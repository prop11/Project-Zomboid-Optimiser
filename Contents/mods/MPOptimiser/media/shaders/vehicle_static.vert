#version 120

varying vec3 vertColour;
varying vec3 vertNormal;
varying vec2 texCoords;
varying vec4 positionEye;

attribute vec4 vertex;
attribute vec4 normal;
attribute vec2 uv;
attribute vec2 uv2;

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

    positionEye = (ModelViewProjection * transform * position) - vec4(-0.2, 0.2, 0.2, 0.0);
}
