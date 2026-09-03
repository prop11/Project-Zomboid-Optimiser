#version 330

layout (location = 0) in vec2 vPos;
layout (location = 1) in vec2 vUV;
layout (location = 2) in vec4 vCol;
layout (location = 3) in vec2 vUV2;
layout (location = 4) in vec2 vUV3;

out vec4 v_wallShadeColor;
out vec2 texCoord;
out vec2 texCoord2;
out vec2 texCoord3;

uniform mat4 ModelViewProjection;

void main(void)
{
	gl_Position = ModelViewProjection * vec4(vPos.x, vPos.y, 0, 1);

	// Object-texture uv coordinates
	texCoord.x = vUV.x;
	texCoord.y = vUV.y;

	// Circle-stencil-texture uv coordinates
	texCoord2.x = vUV2.x;
	texCoord2.y = vUV2.y;

	// Depth-texture uv coordinates
	texCoord3.x = vUV3.x;
	texCoord3.y = vUV3.y;

	// Wall-shading color (per-vertex)
	v_wallShadeColor = vCol;
}
