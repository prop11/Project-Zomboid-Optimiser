#version 120

uniform sampler2D DIFFUSE;

varying vec4 vColor;
varying vec2 vUV1;

void main()
{
    vec4 texel = texture2D(DIFFUSE, vUV1);
    if (texel.a < 0.01)
    {
        discard;
    }
    gl_FragColor = vColor * texel;
}
