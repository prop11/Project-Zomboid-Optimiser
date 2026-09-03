#version 330

uniform sampler2D texture;
uniform vec2 stepSize;
uniform vec4 outlineColor;

in vec4 vColor;
in vec2 vUV;

vec4 outline(sampler2D texture, vec2 texturePos)
{
	float alpha = 8.0 * step(0.5, texture2D( texture, texturePos ).a);
	alpha -= step(0.5, texture2D( texture, texturePos + vec2( stepSize.x, 0.0 ) ).a);
	alpha -= step(0.5, texture2D( texture, texturePos + vec2( -stepSize.x, 0.0 ) ).a);
	alpha -= step(0.5, texture2D( texture, texturePos + vec2( 0.0, stepSize.y ) ).a);
	alpha -= step(0.5, texture2D( texture, texturePos + vec2( 0.0, -stepSize.y ) ).a);

	alpha -= step(0.5, texture2D( texture, texturePos + vec2( -stepSize.x, -stepSize.y ) ).a);
	alpha -= step(0.5, texture2D( texture, texturePos + vec2( stepSize.x, -stepSize.y ) ).a);
	alpha -= step(0.5, texture2D( texture, texturePos + vec2( -stepSize.x, stepSize.y ) ).a);
	alpha -= step(0.5, texture2D( texture, texturePos + vec2( stepSize.x, stepSize.y ) ).a);

	return vec4( outlineColor.r, outlineColor.g, outlineColor.b, alpha * outlineColor.a );
}

void main()
{
	gl_FragColor = outline(texture, vUV);
}
