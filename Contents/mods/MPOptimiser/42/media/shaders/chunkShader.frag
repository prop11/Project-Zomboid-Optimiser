#version 120

uniform sampler2D DIFFUSE;
uniform sampler2D DEPTH;

uniform int useTexture = 1;
uniform float chunkDepth = 0.0;
varying vec4 col;

varying vec2 texCoord;

void main()
{
    vec4 c = vec4(1,1,1,1);

    if(useTexture==1)
        c = texture2D(DIFFUSE, texCoord.st, 0.0);

    float depthTexel = texture2D(DEPTH, texCoord.st, 0.0).r;
    gl_FragDepth = chunkDepth + depthTexel;
    gl_FragColor = c * col;
}
