#version 120

attribute vec3 aPosition;
attribute vec4 aColor;
attribute vec2 aUV1;

uniform mat4 ModelViewProjection;

varying vec4 vColor;
varying vec2 vUV1;

void main (void)
{
	vColor = aColor;
	vUV1 = aUV1;

	vec4 o = ModelViewProjection * vec4(aPosition.xyz, 1.0);
	gl_Position = o;
}
