#version 110

uniform sampler2D u_texture;
uniform float u_alpha;
uniform vec4 u_outlineColor;
uniform vec2 u_stepSize;

float outline(sampler2D texture, vec2 texturePos)
{
	float alpha = 8.0 * texture2D( texture, texturePos ).a;
	alpha -= texture2D( texture, texturePos + vec2( u_stepSize.x, 0.0 ) ).a;
	alpha -= texture2D( texture, texturePos + vec2( -u_stepSize.x, 0.0 ) ).a;
	alpha -= texture2D( texture, texturePos + vec2( 0.0, u_stepSize.y ) ).a;
	alpha -= texture2D( texture, texturePos + vec2( 0.0, -u_stepSize.y ) ).a;

	alpha -= texture2D( texture, texturePos + vec2( -u_stepSize.x, -u_stepSize.y ) ).a;
	alpha -= texture2D( texture, texturePos + vec2( u_stepSize.x, -u_stepSize.y ) ).a;
	alpha -= texture2D( texture, texturePos + vec2( -u_stepSize.x, u_stepSize.y ) ).a;
	alpha -= texture2D( texture, texturePos + vec2( u_stepSize.x, u_stepSize.y ) ).a;

	return alpha;
}

void main()
{
	float outlineAlpha = outline(u_texture, gl_TexCoord[0].xy);
	vec4 texSample = texture2D(u_texture, gl_TexCoord[0].xy);
	texSample.rgb *= u_outlineColor.rgb;
	texSample.a = max(texSample.a * u_alpha, outlineAlpha);
	gl_FragColor = texSample;
}

