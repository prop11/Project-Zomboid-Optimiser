#version 330

uniform sampler2D DIFFUSE;
uniform sampler2D MASK;
uniform float cutoffMin = 0.20;
uniform float cutoffMax = 0.55;

in vec4 vColor;
in vec2 vUV1;

#include "util/math"

void main()
{
    vec2 UV = vUV1;
    vec4 col4 = texture2D(DIFFUSE, UV, 0.0);
    vec4 colmask = texture2D(MASK, UV, 0.0);

    //float maska = max(cutoff - colmask.a, 0.0) / cutoff;
    float maska = (colmask.a - cutoffMin) / (cutoffMax - cutoffMin);
    maska = clamp(maska, 0.0, 1.0);
    maska = 1.0 - maska;

    float fa = col4.a * maska;
    gl_FragColor = vec4(col4.xyz, fa);
}
