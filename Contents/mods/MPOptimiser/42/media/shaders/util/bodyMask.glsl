#version 120

#include "math"

float sampleMaskAlpha(in sampler2D mask, in vec2 uv)
{
    vec4 colMask = texture2D(mask, uv, 0.0);
    return colMask.a;
}

float samplePaddedMaskAlpha(in sampler2D mask, in vec2 uv, float padRadius)
{
    float maskAlpha = sampleMaskAlpha(mask, uv);
    if (maskAlpha >= 0.99 || padRadius <= 0.00001)
    {
        return maskAlpha;
    }

    // Offsets = (-1,  1), (0,  1), (1,  1)
    //           (-1,  0), (0,  0), (1,  0)
    //           (-1, -1), (0, -1), (1, -1)
    vec2 offsets[8];
    offsets[0] = vec2(-1, 1);
    offsets[1] = vec2( 0, 1);
    offsets[2] = vec2( 1, 1);

    offsets[3] = vec2(-1, 0);
    offsets[4] = vec2( 1, 0);

    offsets[5] = vec2(-1,-1);
    offsets[6] = vec2( 0,-1);
    offsets[7] = vec2( 1,-1);

    // Get the highest alpha value from surrounding pixels
    for(int i=0; i < 8; i++)
    {
        vec2 offset = offsets[i];
        vec2 scaledOffset = offset * padRadius;
        vec2 offsetUV = uv + scaledOffset;

        offsetUV = clamp(offsetUV, 0.0, 1.0);

        float offsetSampleAlpha = sampleMaskAlpha(mask, offsetUV);
        maskAlpha = max(maskAlpha, offsetSampleAlpha);
    }

    return maskAlpha;
}

void performBodyMask(in sampler2D diffuse, in sampler2D mask, in vec2 uv, out vec4 fragColor)
{
    vec4 col = texture2D(diffuse, uv, 0.0);
    float maskAlpha = sampleMaskAlpha(mask, uv);

    fragColor = vec4(col.xyz, col.a * maskAlpha);
}

void performPaddedBodyMask(in sampler2D diffuse, in sampler2D mask, in vec2 uv, float padRadius, out vec4 fragColor)
{
    vec4 col = texture2D(diffuse, uv, 0.0);
    float maskAlpha = samplePaddedMaskAlpha(mask, uv, padRadius);

    fragColor = vec4(col.xyz, col.a * maskAlpha);
}
