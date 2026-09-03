#version 110

attribute vec2 vPos;
attribute vec2 vUV;
attribute vec4 vCol;

uniform mat4 ModelViewProjection;

varying vec2 texCoord;

void main (void)
{
    gl_Position = ModelViewProjection * vec4(vPos.x, vPos.y, 0, 1);
    texCoord.x = vUV.x;
    texCoord.y = vUV.y;
	gl_FrontColor = vCol;
}
