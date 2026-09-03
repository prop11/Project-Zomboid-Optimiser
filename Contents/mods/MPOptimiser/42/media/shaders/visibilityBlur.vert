#version 330

layout (location = 0) in vec3 position;
layout (location = 1) in vec2 texcoord;

out vec2 uv;

void main()
{
    gl_Position = vec4(2.0f * (position.xy - vec2(0.5f,0.5f)), 1.0, 1.0);
    uv = texcoord;
}
