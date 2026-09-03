#version 120

uniform sampler2D DIFFUSE;

varying vec4 col;
varying vec2 texCoord;

void main()
{
    // texel.r == 0.0 if BIT_KNOWN is set, otherwise 1.0
    // texel.g == 0.0 if BIT_VISITED is set, otherwise 1.0
    vec4 texel = texture2D(DIFFUSE, texCoord.st, 0.0);
    vec4 hidden = vec4(col.rgb, texel.g * texel.r);
    vec4 known = vec4(0.5, 0.5, 0.5, 0.5 * texel.g);
    gl_FragColor = mix(hidden, known, 1 - texel.r);
}
