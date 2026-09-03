#version 330

layout (location = 0) in vec2 aPosition;
layout (location = 1) in vec4 aColor;
layout (location = 2) in vec2 aUV;

uniform mat4 ModelViewProjection;

out vec4 vColor;
out vec2 vUV;

void main (void)
{
	gl_Position = ModelViewProjection * vec4(aPosition.x, aPosition.y, 0, 1);
	vColor = aColor;
	vUV = aUV;
}
