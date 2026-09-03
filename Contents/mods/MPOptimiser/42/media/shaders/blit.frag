#version 330

uniform sampler2D DIFFUSE;

in vec4 vColor;
in vec2 vUV1;

void main()
{
    gl_FragColor = texture2D(DIFFUSE, vUV1.st, 0.0);
}
