#version 330

layout (location = 0) in vec4 vertex;
layout (location = 1) in vec4 normal;
layout (location = 2) in vec2 uv;

out vec2 texCoords;

uniform mat4 ModelViewProjection;
uniform mat4 transform;

void main()
{
	vec4 position = vec4(vertex.xyz, 1);
	vec4 normal = vec4(normal.xyz, 0);

	texCoords = uv;

	vec4 o = ModelViewProjection * transform * position;
//	o.z -= DepthBias;
	gl_Position = o;
}

