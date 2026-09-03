#version 330

layout (location = 0) in vec3 vPos;
layout (location = 1) in vec4 vCol;
layout (location = 2) in vec2 vUV;

uniform mat4 ModelViewProjection;
uniform vec2 UVScale = vec2(1,1);

out vec4 col;
out vec2 texCoord;

void main (void)
{
    gl_Position = ModelViewProjection * vec4(vPos.xyz, 1);
    col = vCol;
    texCoord.x = vUV.x * UVScale.x;
    texCoord.y = vUV.y * UVScale.y;
}
