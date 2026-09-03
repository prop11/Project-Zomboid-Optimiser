#version 330

in float vDist;
in float vDepth;

void main()
{
    float d = min(vDist, 1.0);

    gl_FragDepth = vDepth;
    gl_FragColor = vec4(d, d, d, 1.0);
}
