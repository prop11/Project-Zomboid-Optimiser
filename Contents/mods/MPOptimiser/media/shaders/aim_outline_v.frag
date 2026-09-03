#version 120

uniform sampler2D Texture;
uniform vec2 u_resolution;
uniform float u_radius = 0.5;
uniform vec4 u_color;

varying vec4 vColor;
varying vec2 vUV;

void main()
{
	vec2 uv = vUV.xy;

	float blur = u_radius / u_resolution.y;
	
	float sum = texture2D(Texture, uv).a;

	sum += texture2D(Texture, vec2(uv.x, uv.y - 4.0 * blur)).a;
	sum += texture2D(Texture, vec2(uv.x, uv.y - 3.0 * blur)).a;
	sum += texture2D(Texture, vec2(uv.x, uv.y - 2.0 * blur)).a;
	sum += texture2D(Texture, vec2(uv.x, uv.y - 1.0 * blur)).a;
	
	sum += texture2D(Texture, vec2(uv.x, uv.y + 1.0 * blur)).a;
	sum += texture2D(Texture, vec2(uv.x, uv.y + 2.0 * blur)).a;
	sum += texture2D(Texture, vec2(uv.x, uv.y + 3.0 * blur)).a;
	sum += texture2D(Texture, vec2(uv.x, uv.y + 4.0 * blur)).a;

	gl_FragColor = vec4(u_color.rgb, sum * u_color.a);
}

