#version 120


attribute vec2 vPos;
attribute vec2 vUV;
attribute vec4 vCol;

uniform mat4 ModelViewProjection;

varying vec4 vertColour;
varying vec2 texCoords;

uniform vec2 UVScale = vec2(1,1);

void main()
{
	vec4 position = vec4(vPos.xy, 0.0, 1.0);
	texCoords = vUV.st * UVScale.xy;

	gl_Position = ModelViewProjection * position;
	vertColour = vCol;
}
