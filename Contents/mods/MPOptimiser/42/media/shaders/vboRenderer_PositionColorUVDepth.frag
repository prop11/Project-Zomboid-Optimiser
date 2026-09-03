#version 330

uniform sampler2D DIFFUSE;

in vec4 vColor;
in vec2 vUV1;
in float vDepth;

void main()
{
    vec4 texel = texture2D(DIFFUSE, vUV1);
    gl_FragDepth = vDepth;
    gl_FragColor = vColor * texel;
}
