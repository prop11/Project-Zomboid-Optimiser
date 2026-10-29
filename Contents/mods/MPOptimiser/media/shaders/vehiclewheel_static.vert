#version 330

varying vec3 vertColour;
varying vec3 vertNormal;
varying vec2 texCoords;

layout (location = 0) in vec4 vertex;
layout (location = 1) in vec4 normal;
/* location = 2 is tangent */
layout (location = 3) in vec2 uv;

uniform mat4 ModelViewProjection;
uniform mat4 transform;
uniform float targetDepth = 0.5;

void main()
{
	vec4 position = vec4(vertex.xyz, 1);
	vec4 normal = vec4(normal.xyz, 0);

	texCoords = uv.st;

	vertNormal = (transform * normal).xyz;
	vertColour = vec3(1,1,1);

	vec4 o = ModelViewProjection * transform * position;
	float clip = ((o.z+1.0) / 2.0); // -1,+1 -> 0,2 -> 0,1
	clip += targetDepth - 0.5;
	o.z = (clip*2)-1; // 0-1 -> 0-2 -> -1,+1

	gl_Position = o;
}
