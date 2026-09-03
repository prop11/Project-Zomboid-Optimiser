#version 330

uniform sampler2D DIFFUSE;
uniform sampler2D MASK;
uniform float cutoffMin = 0.0;
uniform float cutoffMax = 0.00001;
uniform float bloodMinAlpha = 0.25;
uniform float bloodMaxAlpha = 0.975;
uniform float maskPaddingRadius = 1.0 / 64.0;

in vec4 vColor;
in vec2 vUV1;

#include "util/math"
#include "util/bodyMask"

void main()
{
    vec2 UV = vUV1.st;
    vec4 col4 = texture2D(DIFFUSE, UV, 0.0);
    float colmask = samplePaddedMaskAlpha(MASK, UV, maskPaddingRadius);

    float maska = (colmask - cutoffMin) / (cutoffMax - cutoffMin);
    maska = clamp(maska, 0.0, 1.0);

    float fa = col4.a * maska;

    vec4 resultCol = vec4(col4.xyz, fa);

    // Add blood
    //vec3 bloodColor = vec3(0.5, 0.0, 0.05);
    //float bloodAlpha = (colmask - bloodMinAlpha) / (bloodMaxAlpha - bloodMinAlpha);
    //bloodAlpha = clamp(bloodAlpha, 0.0, 1.0);

    //resultCol.xyz = lerp(resultCol.xyz, bloodColor, bloodAlpha);

    gl_FragColor = resultCol;
}
