#version 120

uniform sampler2D DIFFUSE;
uniform sampler2D MASK;

uniform float HueChange;
uniform float maskPaddingRadius = 0.0;

varying vec4 vColor;
varying vec2 vUV1;

#include "util/math"
#include "util/hueShift"
#include "util/bodyMask"

void main()
{
    vec4 col;
    performPaddedBodyMask(DIFFUSE, MASK, vUV1, maskPaddingRadius, col);

    col.xyz = hueShift(col.xyz, HueChange);

    gl_FragColor = col;
}
