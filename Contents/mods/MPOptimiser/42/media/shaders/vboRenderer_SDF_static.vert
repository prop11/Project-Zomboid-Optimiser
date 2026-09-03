#version 330

layout (location = 0) in vec3 aPosition;
layout (location = 1) in vec4 aColor;
layout (location = 2) in vec2 aUV1;

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
    gl_Position = ModelViewProjection * vec4(aPosition.x, aPosition.y, 0, 1);
    texCoord.x = aUV1.x;
    texCoord.y = aUV1.y;
	col = aColor;
	threshold = sdfThreshold;
	outlineThick = sdfOutlineThick;
	outlineColor = sdfOutlineColor;
	shadow = sdfShadow;
}
