#version 330

layout (location = 0) in vec2 vPos;
layout (location = 1) in vec2 vUV;
layout (location = 2) in vec4 vCol;

uniform mat4 ModelViewProjection;

out vec4 vertColour;
out vec2 texCoords;

uniform vec2 UVScale = vec2(1,1);

void main()
{
	vec4 position = vec4(vPos.xy, 0, 1.0);
	texCoords = vUV.st * UVScale.xy;

	gl_Position = ModelViewProjection * position;
	vertColour = vCol;
}
