#version 330

uniform sampler2D DIFFUSE;
uniform sampler2D MASK;

uniform float maskPaddingRadius = 0.0;

in vec4 vColor;
in vec2 vUV1;

#include "util/bodyMask"

void main()
{
    vec4 col;
    performPaddedBodyMask(DIFFUSE, MASK, vUV1, maskPaddingRadius, col);

    gl_FragColor = col;
}
