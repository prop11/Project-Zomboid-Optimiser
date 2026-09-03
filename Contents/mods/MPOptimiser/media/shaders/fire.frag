#version 330

varying vec2 texCoord;
//varying vec2 texCoord2;
//varying float texCoordMix;
varying vec2 texShadowCoord;
varying float alpha;
uniform sampler2D FireTexture;

void main()
{
    vec4 tex1 = texture2D(FireTexture, texCoord);
    //vec4 tex2 = texture2D(FireTexture, texCoord2);
    //vec4 tex = mix(tex1, tex2, texCoordMix);
    float alphaPx = tex1.r*alpha;
    gl_FragColor = vec4(tex1.rgb, alphaPx);
}

