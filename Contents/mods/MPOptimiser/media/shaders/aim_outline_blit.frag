#version 120

uniform sampler2D texture;
uniform sampler2D mask;

varying vec4 vColor;
varying vec2 vUV;

void main()
{
	vec2 uv = vUV;
	float alpha = 1.0 - texture2D(mask, uv).a;
	gl_FragColor = texture2D(texture, uv) * vec4(1.0, 1.0, 1.0, alpha);
}
