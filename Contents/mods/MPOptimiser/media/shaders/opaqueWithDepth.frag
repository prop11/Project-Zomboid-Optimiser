#version 120

uniform sampler2D DIFFUSE;
uniform sampler2D DEPTH;

varying vec4 col;

varying vec2 texCoord;
varying vec2 texCoord2;

uniform float zDepthBlendZ = 0;
uniform float zDepthBlendToZ = 0;

// Use glColorMask() instead
uniform int drawPixels = 1;

void main()
{
    vec4 c0 = texture2D(DIFFUSE, texCoord.st, 0.0);
    float d = texture2D(DEPTH, texCoord2.st, 0.0).r;
    vec4 c = c0 * col;
    c.rgb *= col.a;
    if (c0.a > 0.8 && d > 0.0)
    {
        float calcDepthZ = ((zDepthBlendToZ-zDepthBlendZ) * d) + zDepthBlendZ;
        gl_FragDepth = calcDepthZ;

            gl_FragColor = c;
    }
    else
    {
        discard;
    }
}
