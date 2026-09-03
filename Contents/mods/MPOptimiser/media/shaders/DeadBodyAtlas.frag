#version 120

uniform sampler2D DIFFUSE;
uniform sampler2D DEPTH;
uniform float zDepthBlendZ = 0;
uniform float zDepthBlendToZ = 0;

varying vec4 vColor;
varying vec2 vUV1;

void main()
{
    vec4 texel = texture2D(DIFFUSE, vUV1);
    float d = texture2D(DEPTH, vUV1, 0.0).r;
    if (texel.a * d > 0.0)
    {
        float calcDepthZ = ((zDepthBlendToZ-zDepthBlendZ) * d) + zDepthBlendZ;
        gl_FragDepth = calcDepthZ;
        gl_FragColor = vColor * texel;
    }
    else
    {
        discard;
    }
}
