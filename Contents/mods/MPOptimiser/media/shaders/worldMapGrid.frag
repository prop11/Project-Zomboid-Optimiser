#version 330

uniform sampler2D DIFFUSE;
uniform vec2 UVOffset = vec2(0.0);

in vec4 col;
in vec2 texCoord;

void main()
{
    // texel.r == 0.0 if BIT_KNOWN is set, otherwise 1.0
    // texel.g == 0.0 if BIT_VISITED is set, otherwise 1.0
    vec4 texel_1 = texture2D(DIFFUSE, texCoord.st - UVOffset, 0.0);
    vec4 texel_2 = texture2D(DIFFUSE, texCoord.st + UVOffset, 0.0);
    gl_FragColor = vec4(col.rgb, col.a * max(texel_1.g * texel_1.r, texel_2.g * texel_2.r));
}
