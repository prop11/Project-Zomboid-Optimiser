#version 330

layout (location = 0) in vec3 vertex;
layout (location = 1) in vec2 uv;

out vec2 texcoord;

//uniform vec2 UVScale = vec2(1,1);

void main (void)
{
    gl_Position = vec4(vertex, 1.0);
    texcoord = uv;// * UVScale;
}
