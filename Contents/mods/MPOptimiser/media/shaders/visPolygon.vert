#version 330

layout (location = 0) in vec3 aPosition;
layout (location = 1) in float aDist;
layout (location = 2) in float aDepth;

uniform mat4 ModelViewProjection;

out float vDist;
out float vDepth;

void main (void)
{
	vDist = aDist;
	vDepth = aDepth - 0.0001;

	gl_Position = ModelViewProjection * vec4(aPosition, 1.0);
}
