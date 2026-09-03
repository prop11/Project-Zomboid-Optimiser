#version 120

//#define hd_quality
#define low_quality
 
varying float puddlesDirNE;
varying float puddlesDirNW;
varying float puddlesDirAll;
varying float puddlesDirNone;

uniform sampler2D WaterGroundTex;
uniform sampler2D WaterTextureReflectionA;
uniform sampler2D WaterTextureReflectionB;

uniform float WTime;
uniform vec4 WOffset;
uniform vec4 WViewport;
uniform float WReflectionParam;
uniform mat4 PuddlesParams;

vec2 WParamWind = PuddlesParams[0].xy;
float WParamWindSpeed = PuddlesParams[0].z;
float puddlesZCoordinate = PuddlesParams[0].w;
float muddyPuddles = PuddlesParams[1].x;
float wetLand = PuddlesParams[1].y;
float puddlesSize = PuddlesParams[1].z;
float rainIntensity = PuddlesParams[1].w;

#define Pi 3.1415

vec2 add = vec2(1.0, 0.0);
vec3 HashVector31 = vec3(17.1,31.7, 32.6);
vec3 HashVector32 = vec3(29.5,13.3, 42.6);


float FuncHash( vec3 p ) {
	p = vec3(dot(p, HashVector31), dot(p, HashVector32), 0.0);
	return fract(sin(p.x*2.1+1.1)+sin(p.y*2.5+1.5));
}

float FuncNoise(in vec3 p) {

    vec3 j = floor(p);
	vec3 f = fract(p); 
	f = f * f * (4.5-3.5*f);
    float r1 = mix(FuncHash(j),FuncHash(j + add.xyy),f.x);
    float r2 = mix(FuncHash(j + add.yxy), FuncHash(j + add.xxy),f.x);
    float r3 = mix(FuncHash(j + add.yyx), FuncHash(j + add.xyx),f.x);
    float r4 = mix(FuncHash(j + add.yxx), FuncHash(j + add.xxx),f.x);
    float r12 = mix(r1, r2, f.y);
    float r34 = mix(r3, r4, f.y);
    return mix(r12, r34, f.z);
}

float PerlinNoise( vec3 p ) {
#ifdef hd_quality
	p *= .5;
    float f  = 0.5000   * FuncNoise(p); 
    p =  p * 3.0;
    f += 0.2500   * FuncNoise(p); 
    p =  p * 3.0;
    f += 0.1250   * FuncNoise(p); 
    f  *= min(1.0, 2.0*FuncNoise(p*0.02))*min(1.0, 1.0*FuncNoise(p*0.1)); 
    return f;
#else
    return FuncNoise(p)*.4;
#endif
}


// light
const vec3 ld = normalize(vec3(0.0, 2.1, 14.0));

float hash( vec2 p ) {
	float h = dot(p,vec2(127.1,311.7));	
    return fract(sin(h)*43758.5453123);
}

float noise( in vec2 p ) {
    vec2 i = floor( p );
    vec2 f = fract( p );	
	vec2 u = f*f*(3.0-2.0*f);
    return -1.0+2.0*mix( mix( hash( i + vec2(0.0,0.0) ), 
                     hash( i + vec2(1.0,0.0) ), u.x),
                mix( hash( i + vec2(0.0,1.0) ), 
                     hash( i + vec2(1.0,1.0) ), u.x), u.y);
}

vec2 SphereMap(in vec3 inNormal, in vec3 ecPosition3)
{
   float  m;
   vec3   r,u;

   u = normalize(ecPosition3);
   r = reflect(u, -inNormal);
   m = 2.0 * sqrt(r.x * r.x + r.y * r.y + (r.z + 1.0) * (r.z + 1.0));

   return vec2 (r.x / m + 0.5, r.y / m + 0.5);
}

float water(vec2 uv) {
    return noise(uv * .8);
}


float river(vec2 uv)
{

    float s = 0.;
    const float levels = 1.;
    mat2 r;
    r[0] = vec2(0.4, 0.4);
    r[1] = vec2(-0.24, 0.27);
    uv *= r;
    s += water(uv * 2.);
    s /= (levels + 1.);
    return s;
}

float mapHeightLQ(in vec3 rp)
{
    float levelf = 0.5;
    return rp.y + levelf;
}

vec3 seagrad(in vec2 uv, float bump, float t)
{
    uv *= 14.;
    float hc = river(uv);
    vec2 off = vec2((2.0)/t, 0.0);
    float hh = river(uv + off);
    vec3 h = normalize(vec3(bump, hh - hc, 0.)); 
    vec3 v = normalize(vec3(0., hh - hc, bump));
    return -normalize(cross(h, v));
}

float trace(inout vec3 rp, in vec3 rd)
{
    float dify = mapHeightLQ(rp);
    if(dify < 0.) {
        return dify;
    }
    rp += rd*dify;
    return dify;
}

float getMixValue(float cycle)
{
    // mixval 0..1..0 over full cycle
    float mixval = cycle * 2.0;
    if(mixval > 1.0) mixval = 2.0 - mixval;
    return mixval;
}

vec3 getSkyMapVec(vec2 uv)
{
	vec3 dir;
	uv = ( uv-0.5);
	dir.x = uv.x;
	dir.z = uv.y;
	dir.y = 0.18*sqrt(1.0+dir.x * dir.x  - dir.z*dir.z);
	dir = normalize(dir);
	
	return dir;
}


float rainWave(float d) {
    return sin(31.*d) * smoothstep(-1.0, -0.5, d) * smoothstep(0., -0.5, d);
}

vec3 getRain( vec2 uv )
{
#ifdef hd_quality
    uv.x *= 50.0;
    uv.y *= 100.0;
    vec2 fuv = floor(uv);
    
    vec2 circles = vec2(0.0);
    for (float i = 0.0 ; i<0.6 ; i+=0.3) {
        for (int y = 0; y <= 1; ++y) {
            for (int x = 0; x <= 1; ++x) {
                vec2 coord = fuv + vec2(x, y);
                float subcoord = fract(0.6*WTime + FuncHash(vec3(coord.x, i, coord.y)));
                float intensive = smoothstep(1.0-rainIntensity, (1.01-rainIntensity)*1.2, FuncHash(vec3(coord.y, i, coord.x)));
                vec2 v = coord - uv + i;
                float d = length(v) - (rainIntensity )*subcoord*1.8;
                float F1 = rainWave(d-0.001);
                float F2 = rainWave(d+0.001);
                circles += intensive*normalize(v) * (F2 - F1) * (1.0 - subcoord) ;
            }
        }
    }
    circles *= 100.0;
    return vec3(circles, (1. - dot(circles, circles))*(1.0-rainIntensity*0.5));
#else 
    uv.x *= 50.0;
    uv.y *= 100.0;
    vec2 fuv = floor(uv);
    
    vec2 circles = vec2(0.0);
    
    vec2 coord = fuv + vec2(0.5, 0.5);
    float subcoord = fract(0.6*WTime + FuncHash(vec3(coord.x, 0.0, coord.y)));
    float intensive = smoothstep(1.0-rainIntensity, (1.01-rainIntensity)*1.2, FuncHash(vec3(coord.y, 0.0, coord.x)));
    vec2 v = coord - uv;
    float d = length(v) - (rainIntensity )*subcoord*1.8;
    float F1 = rainWave(d-0.001);
    float F2 = rainWave(d+0.001);
    circles += intensive*normalize(v) * (F2 - F1) * (1.0 - subcoord);

    
    circles *= 100.0;
    return vec3(circles, (1. - dot(circles, circles))*(1.0-rainIntensity*0.5));
#endif
}

float getPuddles(vec2 uv) {
    float dirNE = puddlesDirNE;
    float dirNW = puddlesDirNW;
    float dirA = puddlesDirAll;
    uv *= 10.0;
    float s = 1.02*puddlesSize;
    s += dirNE*sin((uv.x*1.0+uv.y*2.0)*Pi*1.0)*cos((uv.x*1.0+uv.y*2.0)*Pi*1.0)*2.0;
    s += dirNW*sin((uv.x*1.0-uv.y*2.0)*Pi*1.0)*cos((uv.x*1.0-uv.y*2.0)*Pi*1.0)*2.0;
    s += dirA*0.3;
    float b = PerlinNoise(vec3(uv.x*1.0, 0.0, uv.y*2.0));
    float a = min(0.7, s*b);
    b = min(0.7, PerlinNoise(vec3(uv.x*0.7, 1.0, uv.y*0.7)));
    return (a+b);

}

#define puddlesNone 0.24
#define puddlesDark 0.25
#define puddlesAmbient 0.34
#define puddlesReflection 0.341
#define puddlesReflectionFull 0.35

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    
    fragColor = vec4(0.0);
    vec2 uv = vec2(fragCoord.x*WOffset.z*0.0008, fragCoord.y*WOffset.a*0.0008) + WOffset.xy*0.0008+vec2(puddlesZCoordinate*7.0);
    
    float puddles = getPuddles(uv);
#ifdef low_quality
    float level = pow(puddles, 2.0)*puddlesDirNone;
    float levelf =min(pow(level, 0.3), 1.0) + level;
    
    float levelp = puddlesSize;
    float alphaPuddlesNone = smoothstep(puddlesNone, puddlesDark, levelf*levelp);
    float alphaPuddlesDark = min(1.0 , wetLand+ smoothstep(puddlesDark, puddlesAmbient, levelf*levelp));
    float alphaPuddlesAmbient = smoothstep(puddlesAmbient, puddlesReflection, levelf*levelp)*(1.0-muddyPuddles);
    float alphaPuddlesReflection = smoothstep(puddlesReflection, puddlesReflectionFull, levelf*levelp);
    
    vec3 bluedark = vec3(0.1, 0.1, 0.2);
    vec3 muddydark = vec3(0.30, 0.21, 0.18);
    vec3 dark = mix(bluedark, muddydark, muddyPuddles);
    vec3 reflection = vec3(0.5, 0.5, 0.55);
    vec3 pebblesCol = vec3(0.2, 0.1, 0.1);
    fragColor.rgb = mix(dark, reflection, 0.3);
    fragColor.a = mix(0.0, 0.3, alphaPuddlesNone);
    fragColor.a = mix(fragColor.a, 0.3, alphaPuddlesDark);
    
    fragColor.rgb = mix(fragColor.rgb, reflection, alphaPuddlesAmbient);
    fragColor.a = mix(fragColor.a, 0.7, alphaPuddlesAmbient);
    
    fragColor.rgb = mix(fragColor.rgb, mix(dark, reflection, 0.8-muddyPuddles*0.4), alphaPuddlesReflection);
    fragColor.a = mix(fragColor.a, 0.5+muddyPuddles*0.3, alphaPuddlesReflection);
#else
    vec3 rainWaves = getRain(uv);

    float level = pow(puddles, 2.0)*puddlesDirNone;
    float levelf =min(pow(level, 0.3), 1.0) + level;
    
    vec3 rp = vec3(.0, 15.0, 5.0-0.001);
    
	// camera    
    vec3 rd = vec3(uv.x , -0.4, uv.y);
    vec3 ro = rp;
    
    trace(rp, rd);
    
    vec3 n = vec3(0.0, 1.0, 0.0);
    float t = (- dot(ro, n))/dot(n, rd);
    vec3 p = ro+rd*t;
    
    float T = 4.;
    
    // texture offsets for advection
    float cycle = mod(WTime, T)/T;
    float mv = getMixValue(cycle);
    
    vec2 scale = vec2(.35, .4);

#ifdef hd_quality
    vec3 g5 = seagrad(scale * p.xz*2.0 + vec2(.2, .2) + WParamWind * 0.2, 0.1, t);
    vec3 g6 = seagrad(scale * p.xz*1.5 + WParamWind * 0.2 , 0.1, t);
    
    vec3 gm = vec3(0.0, 1.0, 0.0);
    gm += mix(vec3(0.0, 1.0, 0.0), (g5+g6)*0.5, WParamWindSpeed*1.0);
#else 
    vec3 g6 = seagrad(scale * p.xz*1.5 + WParamWind * 0.2 , 0.1, t);
    vec3 gm = vec3(0.0, 1.0, 0.0);
    gm += mix(vec3(0.0, 1.0, 0.0), g6, WParamWindSpeed*1.0);
#endif
    gm += rainWaves.xxy*0.3;
    gm *= 0.7;

    // diffuse Цвет воды
    vec4 blue = vec4(96., 48., 48., 0.) / 255.;
    float wd = dot(gm, ld);
    wd = max(0.0, wd);
    wd = (wd+0.5)/(1.5);
    
    fragColor = blue * wd * 0.2;
    fragColor.rgb += rainWaves.z*0.11;
    
    // Рисуем отражения
    vec3 posEye = getSkyMapVec(vec2((gl_FragCoord.x-WViewport.x)/WViewport.z, 1.0 - (gl_FragCoord.y-WViewport.y)/WViewport.w));
    vec2 refTexCoord = SphereMap( gm, posEye );
    vec3 texRefA = texture2D(WaterTextureReflectionA, refTexCoord).rgb;
    vec3 texRefB = texture2D(WaterTextureReflectionB, refTexCoord).rgb;
    vec3 texRef = mix(texRefB, texRefA, min(WReflectionParam, 1.0));
    //gl_FragColor = fragColor.rgbr;
    //return;
    fragColor.rgb = vec3(0.3)+mix(fragColor.rgb, texRef, 0.2*dot(gm, posEye));
    
    float levelp = puddlesSize;
    float alphaPuddlesNone = smoothstep(puddlesNone, puddlesDark, levelf*levelp);
    float alphaPuddlesDark = min(1.0 , wetLand+ smoothstep(puddlesDark, puddlesAmbient, levelf*levelp));
    float alphaPuddlesAmbient = smoothstep(puddlesAmbient, puddlesReflection, levelf*levelp)*(1.0-muddyPuddles);
    float alphaPuddlesReflection = smoothstep(puddlesReflection, puddlesReflectionFull, levelf*levelp);
    
    vec3 bluedark = vec3(0.1, 0.1, 0.2);
    vec3 muddydark = vec3(0.30, 0.21, 0.18);
    vec3 dark = mix(bluedark, muddydark, muddyPuddles);
    vec3 reflection = fragColor.rgb;
    vec3 pebblesCol = vec3(0.2, 0.1, 0.1);
    fragColor.rgb = mix(dark, reflection, 0.3);
    fragColor.a = mix(0.0, 0.3, alphaPuddlesNone);
    fragColor.a = mix(fragColor.a, 0.3, alphaPuddlesDark);
    
    fragColor.rgb = mix(fragColor.rgb, reflection, alphaPuddlesAmbient);
    fragColor.a = mix(fragColor.a, 0.7, alphaPuddlesAmbient);
    
    fragColor.rgb = mix(fragColor.rgb, mix(dark, reflection, 0.8-muddyPuddles*0.4), alphaPuddlesReflection);
    fragColor.a = mix(fragColor.a, 0.5+muddyPuddles*0.3, alphaPuddlesReflection);
    
#endif
}

void main()
{
    mainImage( gl_FragColor, vec2(gl_FragCoord.x/WViewport.z, 1.0 - gl_FragCoord.y/WViewport.w) );
}

