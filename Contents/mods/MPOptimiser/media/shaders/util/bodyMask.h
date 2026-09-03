
float sampleMaskAlpha(in sampler2D mask, in vec2 uv);

float samplePaddedMaskAlpha(in sampler2D mask, in vec2 uv, float padRadius);

void performBodyMask(in sampler2D diffuse, in sampler2D mask, in vec2 uv, out vec4 fragColor);

void performPaddedBodyMask(in sampler2D diffuse, in sampler2D mask, in vec2 uv, float padRadius, out vec4 fragColor);

