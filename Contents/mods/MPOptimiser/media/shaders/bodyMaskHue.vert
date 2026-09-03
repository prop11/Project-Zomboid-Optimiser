#version 330

layout (location = 0) in vec3 aPosition;
layout (location = 1) in vec4 aColor;
layout (location = 2) in vec2 aUV1;

uniform mat4 ModelViewProjection;
uniform vec2 UVScale = vec2(1,1);

out vec4 vColor;
out vec2 vUV1;

void main (void)
{
    gl_Position = ModelViewProjection * vec4(aPosition.xyz, 1);
    vUV1.xy = aUV1.xy * UVScale.xy;
    vColor = aColor;
}
