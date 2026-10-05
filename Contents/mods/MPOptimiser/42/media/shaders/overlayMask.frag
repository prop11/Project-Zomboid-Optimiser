#version 120

uniform sampler2D DIFFUSE;
uniform sampler2D MASK;
uniform float intensity = 1.0;
uniform float bloodDark = 0.73;

varying vec4 vColor;
varying vec2 vUV1;

void main()
{
    vec2 UV = vUV1.st;
    vec4 col4 = texture2D(DIFFUSE, UV, 0.0);
    vec4 colmask = texture2D(MASK, UV, 0.0);
    vec3 col = col4.xyz;

    col.r = bloodDark;

    float a = 1.0 - pow(1.0 - col4.a, 3.0);
    colmask.a = 1.0 - pow(1.0 - colmask.a, 3.0);

    float fa = a * colmask.a;

    float intens = clamp(intensity, 0.0, 1.0);
    float intensity2 = intensity - 1.0;
    intensity2 = clamp(intensity2, 0.0, 0.6);

    fa += colmask.a * intensity2;
    fa = clamp(fa, 0.0, 1.0);

    fa = clamp(fa - (1.0 - intens), 0.0, 1.0) / intens;

    col *= fa;

    gl_FragColor = vec4(col, fa);
}
