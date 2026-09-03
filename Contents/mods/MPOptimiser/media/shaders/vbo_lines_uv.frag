#version 120

uniform sampler2D texture;

varying vec4 col;
varying vec2 texCoord;

void main()
{
	gl_FragColor = texture2D(texture, texCoord) * col;
}
