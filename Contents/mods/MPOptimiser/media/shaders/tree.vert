#version 330

layout (location = 0) in vec2 aPosition;
layout (location = 1) in vec2 aUV;
layout (location = 2) in vec4 aColor;

uniform mat4 ModelViewProjection;
uniform float chunkDepth = 0;
uniform float zDepth = 0;

out vec2 vUV;
out vec4 vColor;

void main (void)
{
	vec4 o = ModelViewProjection * vec4(aPosition.x, aPosition.y, 0, 1);
	o.z = chunkDepth + zDepth;
	gl_Position = o;
	vUV = aUV;
	vColor = aColor;
}
