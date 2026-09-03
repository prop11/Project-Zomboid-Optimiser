#version 330

uniform sampler2D DIFFUSE;

in vec4 vColor;
in vec2 vUV1;

void main()
{
    vec4 texel = texture2D(DIFFUSE, vUV1);
    texel.a = step(0.5, texel.a);
    gl_FragColor = vec4(vColor.rgb, vColor.a * texel.a);
}
