#version 330

layout (location = 0) in vec3 aPosition;
layout (location = 1) in vec4 aColor;
layout (location = 2) in vec2 aUV1;

uniform mat4 ModelViewProjection;
uniform float userDepth = 0;

out vec4 vColor;
out vec2 vUV1;

void main (void)
{
	vColor = aColor;
	vUV1 = aUV1;

	vec4 o = ModelViewProjection * vec4(aPosition.xyz, 1);

	float clip = ((o.z+1.0) / 2.0); // -1,+1 -> 0,2 -> 0,1
	clip += userDepth;
	o.z = (clip*2)-1; // 0-1 -> 0-2 -> -1,+1

	gl_Position = o;
}
