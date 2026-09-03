#version 120

uniform sampler2D DIFFUSE;
uniform sampler2D DEPTH;
uniform sampler2D MASK;

varying vec4 col;

varying vec2 texCoord;
varying vec2 texCoord2;
varying vec2 texCoord3;

uniform float zDepthBlendZ = 0;
uniform float zDepthBlendToZ = 0;

// Use glColorMask() instead
uniform int drawPixels = 1;

void main()
{
    vec4 c = texture2D(DIFFUSE, texCoord.st, 0.0);
    float d = texture2D(DEPTH, texCoord2.st, 0.0).r;
    vec4 m = texture2D(MASK, texCoord3.st, 0.0);
    c *= col;
    c.rgb *= col.a;
    if (d * m.a > 0) {
        float calcDepthZ = ((zDepthBlendToZ-zDepthBlendZ) * d) + zDepthBlendZ;
        gl_FragDepth = calcDepthZ;
        gl_FragColor = c;
    } else {
        discard;
    }
}
