#version 120

varying vec3 vertColour;
varying vec3 vertNormal;
varying vec2 texCoords;

attribute vec4 vertex;
attribute vec4 normal;
/* location = 2 is tangent */
attribute vec2 uv;

uniform mat4 ModelViewProjection;
uniform mat4 transform;
uniform float targetDepth = 0.5;

void main()
{
	vec4 position = vec4(vertex.xyz, 1.0);
	vec4 norm = vec4(normal.xyz, 0.0);

	texCoords = uv.st;

	vertNormal = (transform * norm).xyz;
	vertColour = vec3(1.0, 1.0, 1.0);

	vec4 o = ModelViewProjection * transform * position;
	float clip = ((o.z+1.0) / 2.0); // -1,+1 -> 0,2 -> 0,1
	clip += targetDepth - 0.5;
	o.z = (clip*2.0)-1.0; // 0-1 -> 0-2 -> -1,+1

	gl_Position = o;
}
