#version 120

attribute vec3 aPosition;
attribute vec4 aColor;
attribute vec2 aUV1;

uniform mat4 ModelViewProjection;
uniform vec2 UVScale = vec2(1,1);

varying vec4 vColor;
varying vec2 vUV1;

void main (void)
{
    gl_Position = ModelViewProjection * vec4(aPosition.xyz, 1.0);
    vUV1.xy = aUV1.xy * UVScale.xy;
    vColor = aColor;
}
