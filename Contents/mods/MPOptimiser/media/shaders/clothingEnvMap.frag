#version 110

varying vec3 vertColour; 
varying vec3 vertNormal;
varying vec2 texCoords;

uniform sampler2D Texture;

void main()
{
    vec4 texSample = texture2D(Texture, texCoords);
	gl_FragColor = vec4(1,0,0,1);
}