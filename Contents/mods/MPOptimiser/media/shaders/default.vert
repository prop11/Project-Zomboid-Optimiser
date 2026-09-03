#version 330

// Used when rendering any tile without a depth texture.

layout (location = 0) in vec2 vPos;
layout (location = 1) in vec2 vUV;
layout (location = 2) in vec4 vCol;

uniform mat4 ModelViewProjection;
uniform float chunkDepth = 0.0;
uniform float zDepth = 0.0;

out vec4 col;
out vec2 texCoord;

void main (void)
{
    vec4 o = ModelViewProjection * vec4(vPos.x, vPos.y, 0, 1);
    o.z = chunkDepth + zDepth;
    gl_Position = o;
    texCoord.x = vUV.x;
    texCoord.y = vUV.y;
    col = vCol;
}
