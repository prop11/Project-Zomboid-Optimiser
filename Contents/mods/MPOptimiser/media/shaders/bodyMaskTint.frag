#version 330

uniform sampler2D DIFFUSE;
uniform sampler2D MASK;

uniform float R = 1.0;
uniform float G = 1.0;
uniform float B = 1.0;

uniform float maskPaddingRadius = 0.0;

in vec4 vColor;
in vec2 vUV1;

#include "util/math"
#include "util/bodyMask"

void main()
{
    vec4 col;
    performPaddedBodyMask(DIFFUSE, MASK, vUV1, maskPaddingRadius, col);

    col.r *= R;
    col.g *= G;
    col.b *= B;

    gl_FragColor = col;
}
