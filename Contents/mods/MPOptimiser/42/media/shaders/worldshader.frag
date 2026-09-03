#version 150 core

uniform sampler2D texture_diffuse;

in vec4 pass_Color;
in vec2 pass_TextureCoord;
in vec4 pass_Normal;

out vec4 out_Color;

void main(void) {
	vec3 diffuse = vec3(texture2D(texture_diffuse, pass_TextureCoord).xyz * pass_Color.xyz);
	out_Color = vec4(diffuse, 1);
}