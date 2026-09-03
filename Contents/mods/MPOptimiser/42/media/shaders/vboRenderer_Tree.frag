#version 120

uniform sampler2D DIFFUSE;
uniform vec2 stepSize;
uniform vec4 outlineColor;

varying vec4 vColor;
varying vec2 vUV1;

vec4 outline(sampler2D texture, vec2 texturePos)
{
	float alpha = 4.0 * texture2D( texture, texturePos ).a;
	alpha -= texture2D( texture, texturePos + vec2( stepSize.x, 0.0 ) ).a;
	alpha -= texture2D( texture, texturePos + vec2( -stepSize.x, 0.0 ) ).a;
	alpha -= texture2D( texture, texturePos + vec2( 0.0, stepSize.y ) ).a;
	alpha -= texture2D( texture, texturePos + vec2( 0.0, -stepSize.y ) ).a;
	return vec4( outlineColor.rgb, alpha * outlineColor.a );
}

void main()
{
    vec4 texel = outline(DIFFUSE, vUV1);
    if (texel.a < 0.01)
    {
        discard;
    }
    gl_FragColor = texel;
}
