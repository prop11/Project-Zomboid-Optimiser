#version 330

layout (location = 0) in vec3 aPosition;
layout (location = 1) in vec4 aColor;
layout (location = 2) in vec2 aUV1;
layout (location = 3) in float aDepth;

uniform mat4 ModelViewProjection;

out vec4 vColor;
out vec2 vUV1;
out float vDepth;

void main (void)
{
	vColor = aColor;
	vUV1 = aUV1;
	vDepth = aDepth;
	gl_Position = ModelViewProjection * vec4(aPosition.xyz, 1);
}
