#version 120

uniform sampler2D TextureCursor;
uniform sampler2D TextureBackground;
uniform float u_alpha;

varying vec2 vUV1;
varying vec2 vUV2;

void main()
{
	vec4 colorCursor = texture2D(TextureCursor, vUV1, 0.0);
	vec4 colorBackground = texture2D(TextureBackground, vUV2, 0.0);
	float r = 1.0 - colorBackground.r;
	float g = 1.0 - colorBackground.g;
	float b = 1.0 - colorBackground.b;

	if (length(colorBackground.rgb - vec3(0.5,0.5,0.5)) < 0.2)
	{
		r = 1.0;
		g = 1.0;
		b = 1.0;
	}
/*
	// Uncomment this to check that the correct part of the world texture is being sampled.
	r = colorBackground.r;
	g = colorBackground.g;
	b = colorBackground.b;
	colorCursor.a = step(colorCursor.a, 0.1);
*/
	gl_FragColor = vec4(r, g, b, u_alpha * step(0.1, colorCursor.a));
}

