#version 120

varying vec4 vertColour; 
varying vec3 vertNormal;
//varying vec2 texCoords;
varying float waterDepth;
varying vec2 waterFlow;
varying float waterSpeed;
varying float isExternal;
varying float vDepth;

uniform sampler2D WaterGroundTex;
uniform sampler2D WaterTextureReflectionA;
uniform sampler2D WaterTextureReflectionB;

uniform float WTime;
uniform vec4 WOffset;
uniform vec4 WViewport;
uniform float WReflectionParam;
uniform vec2 WParamWind;
uniform float WParamWindSpeed;
uniform float WParamRainIntensity;

#define hd_quality

mat3 rotx(float a) { mat3 rot; rot[0] = vec3(1.0, 0.0, 0.0); rot[1] = vec3(0.0, cos(a), -sin(a)); rot[2] = vec3(0.0, sin(a), cos(a)); return rot; }
mat3 roty(float a) { mat3 rot; rot[0] = vec3(cos(a), 0.0, sin(a)); rot[1] = vec3(0.0, 1.0, 0.0); rot[2] = vec3(-sin(a), 0.0, cos(a)); return rot; }
mat3 rotz(float a) { mat3 rot; rot[0] = vec3(cos(a), -sin(a), 0.0); rot[1] = vec3(sin(a), cos(a), 0.0); rot[2] = vec3(0.0, 0.0, 1.0); return rot; }




const float waterY = 0.0; // Уровень воды
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
#ifdef hd_quality
vec3 hash3( vec2 p )
{
    vec3 q = vec3( dot(p,vec2(145.5,361.5)), 
				   dot(p,vec2(276.5,159.5)), 
				   dot(p,vec2(471.3,375.4)) );
	return fract(sin(q)*44531.4578);
}


float bnoise( in vec2 x )
{
    vec2 fp = floor(x);
    vec2 ff = fract(x);
	
	float k = 0.0;
	float k2 = 0.0;
    for( int y=-2; y<=2; y++ )
    for( int x=-2; x<=2; x++ )
    {
        vec2 g = vec2( float(x),float(y) );
		vec3 o = hash3( fp + g );
		vec2 r = g - ff + o.xy;
		float d = dot(r,r);
		float ww = 1.0-smoothstep(0.0,1.414,d);
		k += o.z*ww;
		k2 += ww;
    }
	
    return k/k2;
}
#endif
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

float shoreLine(vec3 rp)
{
    return abs(rp.x);
}


float river(vec2 uv)
{
#ifdef hd_quality
    float s = 0.;
    const float levels = 4.;
    mat2 r;
    r[0] = vec2(0.4, 0.4);
    r[1] = vec2(-0.24, 0.27);
    for (float i = 1.; i < (levels + 1.); i = i + 1.)
    {
        uv *= r;
        s += water(uv * i * 2.);
    }
    s /= (levels + 1.);
    return s;
#else
    float s = 0.;
    const float levels = 1.;
    mat2 r;
    r[0] = vec2(0.4, 0.4);
    r[1] = vec2(-0.24, 0.27);
    uv *= r;
    s += water(uv * 2.);
    s /= (levels + 1.);
    return s;
#endif
}

float mapHeightLQ(in vec3 rp)
{
#ifdef hd_quality
    float level = pow(waterDepth, 2.0);
    float levelf =bnoise( 5.0*rp.xz ) * min(pow(level, 0.3), 1.0)*0.2 + pow(level,0.2)*1.0;
#else
    float levelf = pow(waterDepth, 2.0);
#endif
    return rp.y + levelf;
}

vec3 seagrad(in vec2 uv, float bump, float t)
{
#ifdef hd_quality
    uv *= 14.;
    float hc = river(uv);
    vec2 off = vec2((1.0)/t, 0.0);
    off = vec2(3./t, 0.0);
    float hh = river(uv + off);
    float hv = river(uv + off.yx);
    
    vec3 h = normalize(vec3(bump, hh - hc, 0.)); 
    vec3 v = normalize(vec3(0., hv - hc, bump));
    return -normalize(cross(h, v));
#else
    uv *= 14.;
    float hc = river(uv);
    vec2 off = vec2((2.0)/t, 0.0);
    float hh = river(uv + off);
    vec3 h = normalize(vec3(bump, hh - hc, 0.)); 
    vec3 v = normalize(vec3(0., hh - hc, bump));
    return -normalize(cross(h, v));
#endif
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

float getMixValue(float cycle, inout float offset1, inout float offset2)
{
    // mixval 0..1..0 over full cycle
    float mixval = cycle * 2.0;
    if(mixval > 1.0) mixval = 2.0 - mixval;
    
    // texture phase 1 
    offset1 = cycle;
    // texture phase 2, phase 1 offset by .5
    offset2 = mod(offset1 + .5, 1.0);
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
    uv.x *= 50.0;
    uv.y *= 100.0;
    //uv *= 0.1;
    //float rainIntersive = 0.7;
    vec2 fuv = floor(uv);
    
    vec2 circles = vec2(0.0);
    for (float i = 0.0 ; i<0.6 ; i+=0.3) {
        for (int y = -1; y <= 1; ++y) {
            for (int x = -1; x <= 1; ++x) {
                vec2 coord = fuv + vec2(x, y);
                float subcoord = fract(0.6*WTime + noise(vec2(coord.x+i, coord.y-i)));
                float intensive = smoothstep(1.0-WParamRainIntensity, (1.01-WParamRainIntensity)*1.2, noise(vec2(coord.y+i, coord.x-i)));
                vec2 v = coord - uv + i;
                float d = length(v) - (WParamRainIntensity )*subcoord*1.8;
                float F1 = rainWave(d-0.001);
                float F2 = rainWave(d+0.001);
                circles += intensive*normalize(v) * (F2 - F1) * (1.0 - subcoord)*isExternal ;
            }
        }
    }
    circles *= 100.0;
    return vec3(circles, (1. - dot(circles, circles))*(1.0-WParamRainIntensity));
    //return vec3(0.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = vec4(0.0);
    
    vec2 uv = vec2(fragCoord.x*WOffset.z*0.0008, fragCoord.y*WOffset.a*0.0008) + WOffset.xy*0.0008;
    
    vec3 rainWaves = getRain(uv);
#ifdef hd_quality
    float level = pow(waterDepth, 2.0);
    float levelf =min(pow(level, 0.3), 1.0) + level;
#else
    float level = pow(waterDepth, 2.0);
    float levelf =min(pow(level, 0.3), 1.0) + level;
#endif
    
    vec3 rp = vec3(.0, 15.0, 5.0-0.001);
    
	// camera    
    vec3 rd = vec3(uv.x , -0.4, uv.y);
    vec3 ro = rp;
    
    trace(rp, rd);
    
    vec3 n = vec3(0.0, 1.0, 0.0);
    float t = (waterY - dot(ro, n))/dot(n, rd);
    vec3 p = ro+rd*t;
    
    float T = 4.;
    
    // texture offsets for advection
    float cycle = mod(WTime, T)/T;
    float o1 = 0.0, o2 = 0.0;
    float mv = getMixValue(cycle, o1, o2);
    float dist = 1.0;
    
    // flow vec
    vec2 flow = waterFlow * 0.02;
    
    // normal
    float speed = 50.*waterSpeed * 2;
    vec2 scale = vec2(.35, .4);
    float bmp = 0.075;
#ifdef hd_quality
    vec3 g1 = seagrad(scale * p.xz + flow * o1 * speed, bmp, t);
    vec3 g2 = seagrad(scale * p.xz + vec2(.2, .2) + flow * o2 * speed, bmp, t);
    
    vec3 g3 = seagrad(scale * p.xz + vec2(.1, .2) + flow * o1 * speed * .4, bmp, t);
    vec3 g4 = seagrad(scale * p.xz + vec2(.3, .2) + flow * o2 * speed * .4, bmp, t);
    
    vec3 g5 = seagrad(scale * p.xz*2.0 + vec2(.2, .2) + WParamWind * 0.2, bmp, t);
    vec3 g6 = seagrad(scale * p.xz*1.5 + WParamWind * 0.2 , bmp, t);
    
    vec3 gm = mix(g2, g1, mv);
    gm += mix(g4, g3, mv);
    gm += mix(vec3(0.0, 1.0, 0.0), (g5+g6)*0.5, WParamWindSpeed);
    gm += rainWaves.xxy*0.3;
    gm *= 0.7;
    gm = normalize(gm);
#else
    vec3 g1 = seagrad(scale * p.xz + flow * o1 * speed, bmp, t);
    vec3 g2 = seagrad(scale * p.xz + vec2(.2, .2) + flow * o2 * speed, bmp, t);
    
    vec3 g5 = seagrad(scale * p.xz*2.0 + WParamWind  * 2.0 , bmp, t);
    vec3 g6 = seagrad(scale * p.xz*2.5 + WParamWind * 2.0, bmp, t);
    
    vec3 gm = mix(g2, g1, mv);
    gm += mix(g5, g6, mv)*WParamWindSpeed;
    gm = normalize(gm);
#endif
    
    // diffuse Цвет воды
    vec4 blue = vec4(0., 95., 110., 0.) / 255.;
    blue *= 0.75;
    float wd = dot(gm, ld);
    wd = max(0.0, wd);
    wd = (wd+0.5)/(1.5);
    wd = clamp(wd, 0, 1);
    fragColor = blue * wd * 0.3;
    fragColor.rgb += rainWaves.z*0.01;

    // Рендеринг пены
    ///float foam = smoothstep(0.1, -0.5, h + noise(rp.xz * .15) * .2);//smoothstep(0.5, -1.4, mixval);
    //fragColor += foam * texture(iChannel2, .5 * p.xz + sideFlow * o1 * speed).rrrr;
    //fragColor += foam * texture(iChannel2, .5 * p.xz + sideFlow * o2 * speed).rrrr;


    // Рисуем отражения
    vec3 posEye = getSkyMapVec(vec2((gl_FragCoord.x-WViewport.x)/WViewport.z, 1.0 - (gl_FragCoord.y-WViewport.y)/WViewport.w));
    vec2 refTexCoord = SphereMap( gm, posEye );
    vec3 texRefA = texture2D(WaterTextureReflectionA, refTexCoord).rgb;
    vec3 texRefB = texture2D(WaterTextureReflectionB, refTexCoord).rgb;
    vec3 texRef = mix(texRefB, texRefA, min(WReflectionParam, 1.0));
    fragColor.rgb = mix(fragColor.rgb, texRef, 0.25*dot(gm, posEye));
    
    // Коррекция яркости
    fragColor.rgb = pow(fragColor.rgb*1.7, vec3(1.0 / 2.2));
    
    // Рисуем берега
    float banklevel =noise( vec2(42.0*uv.x + 18.0*uv.y,42.0*uv.y) )+0.6;
    level = smoothstep(0.0, 1.0, 1.2-max(banklevel, level)*level*1.2);
    levelf = max(banklevel, levelf)*levelf;
    fragColor = mix(fragColor, texture2D(WaterGroundTex, uv*10.0+refTexCoord*0.1)*1.3, max(0.0, level-0.3));
    //fragColor.xyz = vec3(banklevel);

    fragColor *= vertColour;

    fragColor.a = min(levelf, 1.0);

    gl_FragDepth = vDepth;

    // Debug
    //fragColor.rgb = normalize(vec3dbg);
    //fragColor.rgb = vec3dbg;
    //fragColor.xyz = vec3(0.0);
    //fragColor.x = ; // WaterGroundTex
    //fragColor.y = texture2D(WaterTextureReflectionA, vec2(fragCoord.x, fragCoord.y)*1.0).x*1.0;
    //fragColor.z = texture2D(WaterTextureReflectionB, vec2(fragCoord.x, fragCoord.y)*1.0).x*1.0;//*WReflectionParam;
	//fragColor = vec4( f, f, f, 1.0 );
    //fragColor = vec4( h*0.01, h, -h, 1.0 );
    //fragColor = vec4( normalize(gm_.xxz), 1.0 );
    //fragColor = vec4( WParamWind, 1.0 );
    //fragColor.rgb = vec3(waterSpeed, waterFlow, waterSpeed);

    //float interpolatedAngle = atan(waterFlow.x, waterFlow.y);
    //float finalValue = (interpolatedAngle + 3.14159265) / (2.0 * 3.14159265);
    //fragColor = vec4(vec3(finalValue), 1.0);
}



void main()
{
    mainImage( gl_FragColor, vec2(gl_FragCoord.x/WViewport.z, 1.0 - gl_FragCoord.y/WViewport.w) );
}

