#version 330

// Used when rendering a tile with a pre-defined depth texture (floor, wall, etc).

layout (location = 0) in vec2 vPos;
layout (location = 1) in vec2 vUV;
layout (location = 2) in vec4 vCol;
layout (location = 3) in vec2 vUV2;

uniform mat4 ModelViewProjection;
uniform float zDepth = 0;
uniform float zDepthBlendZ = 0;
uniform float zDepthBlendToZ = 0;

out vec4 col;
out vec2 texCoord;
out vec2 texCoord2;

void main (void)
{
    gl_Position = ModelViewProjection * vec4(vPos.x, vPos.y, zDepth, 1);
    texCoord.x = vUV.x;
    texCoord.y = vUV.y;
    texCoord2.x = vUV2.x;
    texCoord2.y = vUV2.y;
    col = vCol;
}
