#version 330

precision mediump int;
precision mediump float;

uniform sampler2D tex;
uniform sampler2D depth;
uniform usampler2D stencil;

in vec2 texcoord;

layout (location = 0) out vec4 colour;

void main()
{
    float depthSample = texture2D(depth, texcoord, 0.0).r;
    uint stencilSample = texture2D(stencil, texcoord, 0.0).r;

    // set last bit to one or zero based on stencil
    uint uDepth = floatBitsToUint(depthSample);

    if (stencilSample == 0u)
        uDepth &= ~1u;
    else
        uDepth |= 1u;

    colour = texture2D(tex, texcoord, 0.0);
    gl_FragDepth = uintBitsToFloat(uDepth);
}