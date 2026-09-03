#version 400

uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
uniform mat4 projectionMatrix;

uniform vec3 sunDirection;

layout (location = 0) in vec3 in_Position;
layout (location = 1) in vec3 in_Normal;
layout (location = 2) in vec2 in_TextureCoord;

out vec4 pass_Color;
out vec3 pass_Normal;
out vec2 pass_TextureCoord;

void main(void)
{
 vec4 pos = modelMatrix * vec4(in_Position.x,in_Position.y,in_Position.z,1.0);

 vec3 sunDir = normalize(vec3(1, 1, 1));

 vec3 normal = normalize(in_Normal);

 float NdotL = max(dot(normal, sunDir), 0.0);

 gl_Position = projectionMatrix * viewMatrix * pos;

 vec3 diffuse = vec3(1.0,1.0,1.0);
 vec4 final = vec4(diffuse * NdotL, 1.0);

 pass_Color = final;
 pass_TextureCoord = in_TextureCoord;
 pass_Normal = normal;

}