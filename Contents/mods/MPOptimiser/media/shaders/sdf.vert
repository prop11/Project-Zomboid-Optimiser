#version 330

layout (location = 0) in vec2 vPos;
layout (location = 1) in vec2 vUV;
layout (location = 2) in vec4 vCol;

uniform float sdfThreshold;
uniform float sdfShadow;
uniform float sdfOutlineThick;
uniform vec4 sdfOutlineColor;
uniform mat4 ModelViewProjection;

out vec4 col;
out vec2 texCoord;
out float threshold;
out float outlineThick;
out vec4 outlineColor;
out float shadow;

void main (void)
{
    gl_Position = ModelViewProjection * vec4(vPos.x, vPos.y, 0, 1);
    texCoord.x = vUV.x;
    texCoord.y = vUV.y;
	col = vCol;
	threshold = sdfThreshold;
	outlineThick = sdfOutlineThick;
	outlineColor = sdfOutlineColor;
	shadow = sdfShadow;
}
