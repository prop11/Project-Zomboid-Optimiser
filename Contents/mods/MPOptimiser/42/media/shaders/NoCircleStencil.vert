#version 110

attribute vec2 vPos;
attribute vec2 vUV;
attribute vec4 vCol;
attribute vec4 a_wallShadeColor;

uniform mat4 ModelViewProjection;

varying vec4 v_wallShadeColor;

void main(void)
{
	gl_Position = ModelViewProjection * vec4(vPos.x, vPos.y, 0, 1);

	// Object-texture uv coordinates.
	gl_TexCoord[0].x = vUV.x;
	gl_TexCoord[0].y = vUV.y;

	// Wall-lighting color (per-vertex).
	v_wallShadeColor = a_wallShadeColor;

	gl_FrontColor = vCol;
}
