#version 330

precision mediump int;
precision mediump float;

uniform sampler2D tex;
uniform sampler2D depth;

uniform float frameFade = 1.0;

in vec2 texcoord;

layout (location = 0) out vec4 colour;

void main()
{
    colour = texture2D(tex, texcoord, 0.0);
    float depthSample = texture2D(depth, texcoord, 0.0).r;
    uint uDepth = floatBitsToUint(depthSample);
    uint stencilBit = uDepth & 1u;

    //colour.a *= mix(frameFade, 1.0, float(stencilBit));
    gl_FragDepth = depthSample * 0.0;
}