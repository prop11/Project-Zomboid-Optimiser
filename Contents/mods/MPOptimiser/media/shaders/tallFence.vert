#version 110

attribute vec2 vPos;
attribute vec2 vUV;
attribute vec4 vCol;

uniform mat4 ModelViewProjection;

void main (void)
{
	gl_Position = ModelViewProjection * vec4(vPos.x, vPos.y, 0, 1);
	gl_TexCoord[0].x = vUV.x;
	gl_TexCoord[0].y = vUV.y;
	gl_FrontColor = vCol;
}
