#version 430 core

#include "util/instancing"

layout (location = 0) in vec4 vertex;
layout (location = 1) in vec4 normal;
layout (location = 2) in vec2 uv;

out vec3 vertColour;
out vec3 vertNormal;
out vec2 texCoords;

uniform mat4 ModelViewProjection;

DECLARE_INSTANCING_VERT

BEGIN_INSTANCING

vec3 LightDirection[5];

vec3 LightColour[5];

mat4 MatrixPalette[60];

mat4 transform;
mat4 mvp;

vec2 UVScale;   // 2
float targetDepth;    // 1
float DepthBias;      // 1

vec3 TintColour;
float HighResDepthMultiplier; // 0.5 when drawing models to double-sized chunk textures

vec3 AmbientColour;
float Alpha;

float LightingAmount;
float HueChange;
bool FlipNormal;	// is model inside out?

END_INSTANCING

void main()
{
	COPY_INSTANCE_ID

	GET_INSTANCED_STRUCT(inst);

	vec4 position = vec4(vertex.xyz, 1.0);
	vec4 normal = vec4(normal.xyz, 0.0);

	if (inst.FlipNormal)
		normal = -normal;

	normal = inst.transform * normal;

	vertColour = vec3(1.0);
	vertNormal = normal.xyz;
	texCoords = uv * inst.UVScale * inst.textureSize / TextureDimensions;

	position = inst.mvp * inst.transform * position;

	vec4 origin = inst.mvp * inst.transform * vec4(0, 0, 0, 1);
	position.z += (origin.z - position.z) * inst.HighResDepthMultiplier;
    position.z += inst.targetDepth * 2.0 - 1.0;

	gl_Position = position;
}
