#version 330

// Used when rendering a whole-chunk texture (without depth).

layout (location = 0) in vec2 vPos;
layout (location = 1) in vec2 vUV;
layout (location = 2) in vec4 vCol;

uniform mat4 ModelViewProjection;

out vec4 col;
out vec2 texCoord;

void main (void)
{
    gl_Position = ModelViewProjection * vec4(vPos.x, vPos.y, 0, 1);
    texCoord.x = vUV.x;
    texCoord.y = vUV.y;
    col = vCol;
}
