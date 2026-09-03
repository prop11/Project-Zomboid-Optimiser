#version 330

uniform sampler2D DIFFUSE;

in vec2 vUV;
in vec4 v_color;

void main()
{
    vec4 col = texture2D(DIFFUSE, vUV.st, 0.0);
    col *= v_color;
    gl_FragColor = col;
}
