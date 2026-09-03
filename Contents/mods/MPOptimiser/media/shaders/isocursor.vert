#version 330

layout (location = 0) in vec3 aPosition;
layout (location = 1) in vec2 aUV1;
layout (location = 2) in vec4 aColor;
layout (location = 3) in vec2 aUV2;

uniform mat4 ModelViewProjection;

out vec2 vUV1;
out vec2 vUV2;

void main (void)
{
	gl_Position = ModelViewProjection * vec4(aPosition.xyz, 1.0);
	
	// Cursor-texture uv coordinates
	vUV1 = aUV1;

	// Background-texture uv coordinates
	vUV2 = aUV2;
}
