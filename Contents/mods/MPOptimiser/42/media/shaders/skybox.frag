#version 110

varying vec2 vUV1;

float gTime;

uniform float SBTime;
#if 1 // DEBUG
uniform float SBParamCloudCount;
uniform float SBParamCloudSize;
uniform float SBParamFog;
uniform vec3 SBParamSunLight;
uniform vec3 SBParamSunColour;
uniform vec3 SBParamSkyHColour;
uniform vec3 SBParamSkyLColour;
uniform float SBParamCloudLight;
uniform float SBParamStars;
uniform vec3 SBParamWind;

#else


//#define RASSVET
#define DAY
//#define NIGHT
//
float SBParamCloudCount = 0.3;
float SBParamCloudSize = 0.2;
float SBParamFog = 0.0;
vec3 SBParamWind  = vec3(0.0, .0, .0);
#ifdef RASSVET
vec3 SBParamSunLight  = normalize( vec3(  0.9, 0.1,  0.2 ) );
vec3 SBParamSunColour = vec3(1.0, .3, .1);
vec3 SBParamSkyHColour = vec3(.2, .2, .3);//vec3(.1, .1, .4);
vec3 SBParamSkyLColour = vec3(.1, .4, .6);//vec3(.1, .45, .7);
float SBParamCloudLight = 0.8;
float SBParamStars = 0.2;
#endif
#ifdef DAY
vec3 SBParamSunLight  = normalize( vec3(  0.35, 0.22,  0.3 ) );
vec3 SBParamSunColour = vec3(1.0, .86, .7);
vec3 SBParamSkyHColour = vec3(.1, .1, .4);
vec3 SBParamSkyLColour = vec3(.1, .45, .7);
float SBParamCloudLight = 0.99;
float SBParamStars = 0.0;
#endif
#ifdef NIGHT
vec3 SBParamSunLight  = normalize( vec3(  0.35, 0.22,  0.3 ) );
vec3 SBParamSunColour = vec3(.1, .086, .07);
vec3 SBParamSkyHColour = vec3(.01, .01, .04);
vec3 SBParamSkyLColour = vec3(.01, .045, .07);
float SBParamCloudLight = 0.1;
float SBParamStars = 0.99;
#endif

#endif


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
	p *= .5;
    float f  = 0.5000   * FuncNoise(p); 
    p =  p * 3.0;
    f += 0.2500   * FuncNoise(p); 
    return f;
}


float MapNoise(vec3 p)
{
	return PerlinNoise(p)-SBParamCloudCount;
}

vec3 doBackgroundStars( const in vec3 rd ) {
	vec3 rds = rd;
	vec3 col = vec3(0);
    float v = 1.0/( 2. * ( 1. + rds.z ) );
    
    vec2 xy = vec2(rds.y * v, rds.x * v);
    float s = FuncNoise(rds*134.);
    
    s += FuncNoise(rds*470.);
    s = pow(s,19.0) * 0.00001;
    if (s > 0.5) {
        vec3 backStars = vec3(s)*.5 * vec3(0.95,0.8,0.9); 
        col += backStars;
    }
	return   col; 
} 

vec3 render(in vec3 pos,in vec3 rd)
{
	float sunAmount = max( dot( rd, SBParamSunLight), 0.0 )*length(SBParamSunLight);
    float sunZenit = 1.0-min(pow(max( dot( vec3(1.0, 0.0, 0.0), SBParamSunLight), 0.0 ), 10.0),1.0)*length(SBParamSunLight);
    float cloudLower = 1000.0+SBParamCloudSize*5000.0;
	float cloudUpper = 2000.0+SBParamCloudSize*5000.0;

	vec3  sky = mix(SBParamSkyHColour, SBParamSkyLColour, 1.0-pow(abs(rd.y), .5));
    
	sky += SBParamSunColour * min(pow(sunAmount, 10.0) * .75, 1.0);
    sky += normalize(SBParamSunColour) * min(pow(sunAmount, 1500.0) * 2.0, 1.0);
    sky += doBackgroundStars(rd)*SBParamStars*(1.0-min(sky.x+sky.y+sky.z, 1.0));
	
	float beg = ((cloudLower-pos.y)/rd.y);
	float end = ((cloudUpper-pos.y)/rd.y);

	vec3 p = vec3(pos.x + rd.x * beg, cloudLower, pos.z + rd.z * beg);


	float d = 0.0;
    float add = (end-beg) / 20.0;
	vec4 clouds_col = vec4(0.1, .1, .1, 0.0);

	vec4 col = vec4(0.0, 0.0, 0.0, pow(1.0-rd.y,30.) * .2);
	for (int i = 0; i < 20; i++)
	{
		if (clouds_col.a >= 1.0) continue;
		vec3 pos = p + rd * d;
		float h = MapNoise(pos * .001);
        col.a += max(-h, 0.0) * .3; 
		col.rgb = mix(vec3((pos.y-cloudLower)/((cloudUpper-cloudLower))) * col.a*SBParamCloudLight, SBParamSunColour, mix(min(pow(sunAmount, 2.0) * .75, 1.0)*0.02, max(.3-col.a, 0.0) * .04, sunZenit));
		clouds_col = clouds_col + col*(1.0 - clouds_col.a);
		d += add;
	}
	clouds_col.xyz += min((1.-clouds_col.a) * pow(sunAmount, 3.0), 1.0);
	sky = mix(sky, clouds_col.xyz, clouds_col.a);
    
    sky = mix(sky, vec3(0.5)+normalize(SBParamSunColour) * min(pow(sunAmount, 3.0) * 0.75, 1.0), SBParamFog);

	return clamp(sky, 0.0, 1.0);
}


vec3 getCameraVector( float t )
{
    return vec3(3200.0  * sin(0.02*t), 0.0, 3200.0 * cos(0.015*t) )+SBParamWind*1000.0;
} 


void main()
{
	gTime = SBTime*.5 - 0.8;

    vec2 uv = vUV1.xy;
    
    // Sphere map
    vec4 dir4;
    vec3 dir;
    uv = (2.0 * uv - 1.0);
	dir.xz = uv.xy;
	dir.y = sqrt(1.0-dir.x * dir.x  - dir.z*dir.z) * 0.2;
	if (length(dir) >= 1.0) {
        dir4 = vec4(0.0, .001, .999, 0.0);
    } else {
        dir4 = vec4(normalize(dir), 1.0);
    }
	
    vec3 col = render(getCameraVector(gTime), dir4.xyz);

	// Don't gamma too much to keep the moody look...
	col = pow(col, vec3(.6));
    
    gl_FragColor=vec4(col, dir4.a);
}

