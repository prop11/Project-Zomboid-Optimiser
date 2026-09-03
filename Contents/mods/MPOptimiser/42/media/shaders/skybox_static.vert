#version 110

uniform mat4 ModelViewProjection;

varying vec2 texCoords;

void main (void)
{
	gl_Position = ModelViewProjection * gl_Vertex;
	gl_TexCoord[0] = gl_MultiTexCoord0;
	gl_FrontColor = gl_Color;
    texCoords = gl_MultiTexCoord0.st;
}
