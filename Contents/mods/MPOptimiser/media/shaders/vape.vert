#version 330

uniform mat4 mvpMatrix; //modelviewprojection matrix
uniform float FireTime;
uniform mat4 FireVortice;

layout (location = 0) in vec3 Vertex; 
layout (location = 1) in vec4 Particule;
//layout (location = 2) in mat4 Vortice; 

out vec4 color;
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



void main (void)
{
    float sintime = sin(FireTime);
    float sintime10 = sin(FireTime*10.0);
    float costime10 = cos(FireTime*10.0);
    float hashV = noise(Particule.xz, 1.0);
    float lifetime = 10.0*hashV;
    float timeShift = hashV*lifetime;
    float life = fract(FireTime+timeShift/ lifetime);
    float vx = 3.0 - noise(Particule.xz, 2.0)*6.0;
    float vy = 3.0 - noise(Particule.xz, 2.5)*6.0;
    
    float size = (1.0-life);
    
    
    float y = Particule.y-((life)*300.0 + vy*life*20.0);
    float x = Particule.x-(vx*life*20.0);
    
    float dx = (sintime10)*perlin(vec2(x,y)*0.05)*50.0*life;
    dx += (costime10)*perlin(vec2(x+100.0,y)*0.03)*50.0*life;
    
    //x += dx;
    
    size += abs(dx)*0.02;
    
    
    //float hashL = noise(vec2(x+sintime*100.0,y+FireTime*300.0)*0.01, 1.0);
    //life-=hashL*0.5;
    

    
	gl_Position = mvpMatrix * vec4(Vertex*120.0*0.2  + vec3(x, y, 0.0), 1.0);
	//gl_TexCoord[0] = gl_MultiTexCoord0;
    texCoord = Vertex.xy*0.5+0.5;
    color = vec4(hsv2rgb(vec3(0.1 , 0.5-life*life*0.5 , 1.0)), 0.05*(life-smoothstep(0.8, 1.0, life)));
}
