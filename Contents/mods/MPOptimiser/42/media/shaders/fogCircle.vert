#version 330

layout (location = 0) in vec2 aPosition;
layout (location = 1) in vec2 aUV;
layout (location = 2) in vec4 aColor;

uniform mat4 u_mvp;

out vec2 vUV;
out vec4 v_color;

void main (void)
{
    gl_Position = u_mvp * vec4(aPosition.x, aPosition.y, 0, 1);
    vUV = aUV;
    v_color = aColor;
}
