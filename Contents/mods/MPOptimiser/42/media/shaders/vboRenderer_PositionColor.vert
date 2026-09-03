#version 330

layout (location = 0) in vec3 aPosition;
layout (location = 1) in vec4 aColor;

uniform mat4 ModelViewProjection;
uniform float userDepth = 0;

out vec4 vColor;

void main (void)
{
	vColor = aColor;

	vec4 o = ModelViewProjection * vec4(aPosition.xyz, 1);

	float clip = ((o.z+1.0) / 2.0); // -1,+1 -> 0,2 -> 0,1
	clip += userDepth;
	o.z = (clip*2)-1; // 0-1 -> 0-2 -> -1,+1

	gl_Position = o;
}	
