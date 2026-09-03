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

	float blur = u_radius / u_resolution.x;
	
	float sum = texture2D(Texture, uv).a;
	
	sum += texture2D(Texture, vec2(uv.x - 4.0 * blur, uv.y)).a;
	sum += texture2D(Texture, vec2(uv.x - 3.0 * blur, uv.y)).a;
	sum += texture2D(Texture, vec2(uv.x - 2.0 * blur, uv.y)).a;
	sum += texture2D(Texture, vec2(uv.x - 1.0 * blur, uv.y)).a;
	
	sum += texture2D(Texture, vec2(uv.x + 1.0 * blur, uv.y)).a;
	sum += texture2D(Texture, vec2(uv.x + 2.0 * blur, uv.y)).a;
	sum += texture2D(Texture, vec2(uv.x + 3.0 * blur, uv.y)).a;
	sum += texture2D(Texture, vec2(uv.x + 4.0 * blur, uv.y)).a;

	gl_FragColor = vec4(u_color.rgb, sum * u_color.a);
}

