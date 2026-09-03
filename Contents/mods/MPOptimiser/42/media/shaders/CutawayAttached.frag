#version 330

uniform sampler2D DIFFUSE;
uniform sampler2D DEPTH;
uniform sampler2D MASK;

in vec4 col;

in vec2 texCoord;
in vec2 texCoord2;
in vec2 texCoord3;

uniform float zDepthBlendZ = 0;
uniform float zDepthBlendToZ = 0;

void main()
{
    vec4 c = texture2D(DIFFUSE, texCoord.st, 0.0);
    float d = texture2D(DEPTH, texCoord2.st, 0.0).r;
    vec4 m = texture2D(MASK, texCoord3.st, 0.0);

    // Don't render the door-frame or window-frame outline
    if (m.g + m.b > 0.0)
    {
        discard;
    }

    c.rgba *= m.rrra; // only the red pixels
    c *= col;
    c.rgb *= col.a;
    if (c.a * d * m.a > 0)
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
