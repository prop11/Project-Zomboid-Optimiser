#version 330

in vec2 texCoords;

uniform sampler2D Texture;
uniform vec4 u_color;

void main()
{
	float alpha = step(0.5, texture2D(Texture, texCoords).a);
	gl_FragColor = vec4(u_color.rgb, u_color.a * alpha);
}

