#version 330

uniform mat4 mvpMatrix; //modelviewprojection matrix
uniform float FireTime;
uniform mat3 FireParam;

layout (location = 0) in vec3 Vertex; 
layout (location = 1) in vec4 Particule;
//layout (location = 2) in mat4 Vortice; 

varying vec2 texCoord;
//varying vec2 texCoord2;
//varying float texCoordMix;
varying vec2 texShadowCoord;
varying float alpha;

float hash( vec2 p, float id ) {
	float h = dot(p,vec2(127.1*id,311.7*id));	
    return fract(sin(h)*43758.5453123);
}

float noise( in vec2 p, float id ) {
    vec2 i = floor( p );
    vec2 f = fract( p );	
	vec2 u = f*f*(3.0-2.0*f);
    return -1.0+2.0*mix( mix( hash( i + vec2(0.0,0.0), id ), 
                     hash( i + vec2(1.0,0.0), id ), u.x),
                mix( hash( i + vec2(0.0,1.0), id ), 
                     hash( i + vec2(1.0,1.0), id ), u.x), u.y);
}

float perlin( in vec2 p ) {
    float result = noise(p, 1.0)*0.50;
    result += noise(p*.3, 1.0)*0.25;
    return result;
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

mat3 getRotation(float angle) {
    float cos_a = cos(angle);
    float sin_a = sin(angle);
    return mat3(cos_a, sin_a, 0.0, -sin_a, cos_a, 0.0, 0.0, 0.0, 1.0);
}

void main (void)
{

    float hashV = noise(Particule.xz, 1.0);
    float lifetime = 0.60;//+ 0.2*hashV;
    float timeShift = Particule.a*lifetime;
    float hashA = noise(vec2(Particule.z, 18.0*floor((FireTime+timeShift)/ lifetime)), 1.0);
    float life = fract((FireTime+timeShift)/ lifetime);
    
    float size = 2.0*life*(1.0-life)+0.5;
    size *= 1.0+hashA*0.5;
    

    float dy = life*150.0+FireParam[0][1]*life*250.0;//pow(life, 2.0)*200.0;
    float dx = FireParam[0][0]*life*500.0;
    float y = Particule.y-dy;
    float x = Particule.x-dx;
    
    float particleRot = 3.1415*(0.13*hashA);
    //particleRot = 3.1415*(0.13-0.26*hashA);

    
    gl_Position = mvpMatrix * vec4((Vertex*120.0*0.15*5.0*size* getRotation(particleRot)  + vec3(x, y, 0.0)), 1.0) ;

    texShadowCoord = Vertex.xy*0.5+0.5;

    
    alpha = smoothstep(0.0, 0.1, life)*smoothstep(1.0, 0.6, life)*0.5;
    
    float tilesX = 8.0;
    float tilesY = 4.0;
    float tShift = life*tilesX*tilesY*1.0;
    float tId = floor(tShift);
    float tx = mod(tId, tilesX);
    float ty = floor(tId/tilesX);
    texCoord = (((Vertex.xy*0.5)+vec2(0.5, 0.5))/vec2(tilesX,tilesY)) + vec2(tx/tilesX, ty/tilesY);
    /*tId = ceil(tShift);
    tx = mod(tId, tilesX);
    ty = floor(tId/tilesX);
    texCoord2 = (((Vertex.xy*0.5)+vec2(0.5, 0.5))/vec2(tilesX,tilesY)) + vec2(tx/tilesX, ty/tilesY);
    texCoordMix = mod(tShift, 1.0);*/
    
    
}
