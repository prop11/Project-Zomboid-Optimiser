#version 120

varying vec3 vertColour;
varying vec3 vertNormal;
varying vec2 texCoords;
varying vec2 texCoords1;

uniform mat4 ModelViewProjection;
uniform mat4 transform;
uniform float targetDepth = 0.5;

attribute vec4 vertex;
attribute vec4 normal;
attribute vec2 uv;
attribute vec2 uv2;

void main()
{
	vec4 position = vec4(vertex.xyz, 1.0);
	vec4 norm = vec4(normal.xyz, 0.0);

	texCoords = uv.st;
#ifdef MULTI_UV
	texCoords1 = uv2.st;
#else
	texCoords1 = uv.st;
#endif

	vertNormal = (transform * norm).xyz;
	vertColour = vec3(1.0, 1.0, 1.0);

	vec4 o = ModelViewProjection * transform * position;
	float clip = ((o.z+1.0) / 2.0); // -1,+1 -> 0,2 -> 0,1
	clip += targetDepth - 0.5;
	o.z = (clip*2.0)-1.0; // 0-1 -> 0-2 -> -1,+1
	gl_Position = o;
}
