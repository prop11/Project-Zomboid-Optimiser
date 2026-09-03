#version 330
layout (location = 0) in vec2 aPos;
layout (location = 1) in vec2 aUV;
layout (location = 2) in vec4 aColor;

uniform mat4 ModelViewProjection;

out vec4 vColor;
out vec2 vUV;

void main (void)
{
	gl_Position = ModelViewProjection * vec4(aPos.x, aPos.y, 0, 1);
	vUV = aUV;
	vColor = aColor;
}
