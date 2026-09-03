#version 330

#define BLUR_RANGE 2
#define MIN_SPREAD 2.0
#define MAX_SPREAD 16.0
#define BASE_OPACITY 0.022

in vec2 uv;

uniform vec2 screenSize = vec2(1920, 1057);
uniform vec2 displayOrigin = vec2(0, 0);
uniform vec2 displaySize = vec2(2048, 2048);
uniform vec2 texSize = vec2(960, 528);
uniform sampler2D tex;
uniform sampler2D depth;
uniform vec2 TextureSize;
uniform float zoom = 1.0;
uniform int opacityScale = 2;

const float BLUR_SAMPLES = (BLUR_RANGE * 2 + 1) * (BLUR_RANGE * 2 + 1);
const float BLUR_SCALE = 1.0 / BLUR_SAMPLES;

out vec4 colour;

void main()
{
    // frag coord is in pixel units, needs to be converted to a 0.0 to 1.0 range
    vec2 screenUV = (gl_FragCoord.xy - displayOrigin.xy) / displaySize;

    vec4 vision = texture2D(tex, screenUV, 0.0);
    float alpha = 0.0;

    float zoomFactor = 1.0 / max(zoom, 0.1);
    float spread = mix(MIN_SPREAD, MAX_SPREAD, zoomFactor * (vision.r * 4.0));

    // texture res is typically bigger than the screen res
    // need to clamp to rendered portion of the texture
    // otherwise you get fading around the edges of the screen
    vec2 maxUV = texSize / TextureSize;

    // only writing depth for shadow polygons, so any blurring off the shadow is clipped
    // need to only blur into the shadow area, edge of shadow = half on/off

    ivec2 pixel = ivec2(gl_FragCoord.xy / screenSize * texSize);
    vec2 pixelStep = vec2(1.0, 1.0) / TextureSize;

    for (int y = -BLUR_RANGE; y <= BLUR_RANGE; y++)
    {
        for (int x = -BLUR_RANGE; x <= BLUR_RANGE; x++)
        {
            vec2 samUV = min((pixel + ivec2(x, y)) * pixelStep, maxUV);
            vec4 sam = texture2D(tex, samUV, 0.0);
            alpha += sam.a;
        }
    }

    // alpha range is 0.0 to BLUR_SAMPLES
    // edge of shadow would produce an alpha of BLUR_SAMPLES * 0.5

    alpha -= BLUR_SAMPLES * 0.5; // (-0.5 to 0.5) * BLUR_SAMPLES, edge of shadow is now 0.0
    alpha *= 2.0; // -BLUR_SAMPLES to BLUR_SAMPLES, edge of shadow is still 0.0
    alpha *= BLUR_SCALE; // -1.0 to 1.0 (negative is clipped)

    gl_FragDepth = texture2D(depth, screenUV, 0.0).r;
    colour = vec4(0.0, 0.0, 0.0, alpha * (BASE_OPACITY * opacityScale));
}
