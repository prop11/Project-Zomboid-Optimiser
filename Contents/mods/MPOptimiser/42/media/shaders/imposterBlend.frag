#version 330

precision mediump int;
precision mediump float;

uniform sampler2D tex;
uniform sampler2D depth;

in vec2 texcoord;

layout (location = 0) out vec4 colour;

void main()
{
    float depthSample = texture2D(depth, texcoord, 0.0).r;
    uint uDepth = floatBitsToUint(depthSample);
    uint stencilBit = uDepth & 1u;

    if (stencilBit == 0u)
        discard;

    colour = texture2D(tex, texcoord, 0.0);
    gl_FragDepth = depthSample;
}