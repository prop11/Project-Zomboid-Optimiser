#version 330

in vec2 texcoord;

layout (location = 0) out vec4 colour;

void main()
{
    colour = vec4(texcoord, 0.0, 1.0);
    gl_FragDepth = 0.0;
}