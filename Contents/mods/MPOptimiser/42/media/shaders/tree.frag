#version 110

uniform sampler2D texture;
uniform vec2 stepSize;
uniform vec4 outlineColor;

varying vec2 vUV;
varying vec4 vColor;

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
	gl_FragColor = outline(texture, vUV.xy);
}
