#version 330

uniform mat4 mvpMatrix; //modelviewprojection matrix
uniform float FireTime;
uniform mat3 FireParam;

layout (location = 0) in vec3 Vertex; 
layout (location = 1) in vec4 Particule;
//layout (location = 2) in mat4 Vortice; 

out float alpha;
out vec2 texCoord;

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
    float lifetime = 1.60+ 0.2*hashV;
    float timeShift = Particule.a*lifetime;
    float hashA = noise(vec2(Particule.x, 18.0*floor((FireTime+timeShift)/ lifetime)), 1.0);
    float life = fract((FireTime+timeShift)/ lifetime);
    
    
    float size = 2.0*life+0.5;
    //size *= 1.0+hashA*0.5;
    
    float dy = life*400.0+FireParam[0][1]*life*1500.0;
    float dx = life*hashA*60.0+FireParam[0][0]*life*500.0*2.66;
    float y = Particule.y-dy;
    float x = Particule.x-dx;

    float particleRot = 3.1415*hashA;
    
    //float hashL = noise(vec2(x+sintime*100.0,y+FireTime*300.0)*0.01, 1.0);
    //life-=hashL*0.5;
    
    float tilesX = 2.0;
    float tilesY = 2.0;
    float tId = floor(2.0*fract(2.0+hashA));
    float tx = mod(tId, tilesX);
    float ty = floor(tId/tilesX);
    texCoord = (((Vertex.xy*0.5)+vec2(0.5, 0.5))/vec2(tilesX,tilesY)) + vec2(tx/tilesX, ty/tilesY);
    
	gl_Position = mvpMatrix * vec4(Vertex*120.0*0.8*size* getRotation(particleRot)  + vec3(x, y, 0.0), 1.0);

    //alpha = 1.05*(life-smoothstep(0.8, 1.0, life));
    //alpha = smoothstep(0.0, 0.6, life)*smoothstep(1.0, 0.6, life)*1.0;
    alpha = smoothstep(0.0, 2.0, life)*smoothstep(1.0, 0.3, life)*2.0;
}
