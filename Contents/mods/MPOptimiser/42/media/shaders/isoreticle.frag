#version 120

uniform sampler2D aimTexture;
uniform float red;
uniform float green;
uniform float blue;
uniform float alpha;

varying vec2 vUV1;

void main()
{
	vec4 colorCursor = texture2D(aimTexture, vUV1, 0.0);
	gl_FragColor = vec4(red, green, blue, alpha * colorCursor.a);
}

