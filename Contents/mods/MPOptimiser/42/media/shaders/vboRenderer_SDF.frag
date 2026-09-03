#version 110
uniform sampler2D DIFFUSE;

varying vec2 texCoord;
varying vec4 col;
varying float threshold;
varying float outlineThick;
varying vec4 outlineColor;
varying float shadow;

const vec2 shadowOffset = vec2(-0.002, 0.002); // Between 0 and spread / textureSize
const float shadowSmoothing = 0.35; // Between 0 and 0.5
const vec4 shadowColor = vec4(0.0, 0.0, 0.0, 1.0);

void main()
{
    vec4 text;
    if (outlineThick == 0.5) {
        float distance = texture2D(DIFFUSE, texCoord.xy).a;
        float alpha = smoothstep(.5 - threshold, .5 + threshold, distance);
        text = vec4(col.rgb, col.a * alpha);
    }
    else {
        float distance = texture2D(DIFFUSE, texCoord.xy).a;
        float outlineFactor = smoothstep(.5 - threshold, .5 + threshold, distance);
        vec4 color = mix(outlineColor, col, outlineFactor);
        float alpha = smoothstep(outlineThick - threshold, outlineThick + threshold, distance);
        text = vec4(color.rgb, color.a * alpha);
    }

    if (shadow == 1.0) {
        float shadowDistance = texture2D(DIFFUSE, texCoord.xy - shadowOffset).a;
        float shadowAlpha = smoothstep(0.5 - shadowSmoothing, 0.5 + shadowSmoothing, shadowDistance);
        vec4 shadow = vec4(shadowColor.rgb, shadowColor.a * shadowAlpha);

        gl_FragColor = mix(shadow, text, text.a);
    }
    else {
       gl_FragColor = text;
    }
}
