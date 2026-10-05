#version 120

attribute vec4 vertex;
attribute vec4 normal;
attribute vec2 uv;

varying vec3 vertColour;
varying vec3 vertNormal;
varying vec2 texCoords;

uniform mat4 ModelViewProjection;
uniform mat4 transform;
uniform float targetDepth = 0.5;
uniform float DepthBias;

uniform vec2 UVScale;
uniform float HighResDepthMultiplier = 0.0; // 0.5 when drawing models to double-sized chunk textures
uniform float FinalScale = 1.0;

void main()
{
	vec4 position = vec4(vertex.xyz, 1.0);
	vec4 norm = vec4(normal.xyz, 0.0);

	texCoords = uv.st * UVScale.xy;

	vertNormal = (transform * norm).xyz;
	vertColour = vec3(1.0, 1.0, 1.0);

	vec4 positionScaled = transform * position;
	positionScaled.xyz *= FinalScale;
	vec4 o = ModelViewProjection * positionScaled;

	vec4 origin = ModelViewProjection * vec4(0, 0, 0, 1);
	o.z += (origin.z - o.z) * HighResDepthMultiplier;

//	o.z -= DepthBias;
//	o.z /= 16.0f;
	float clip = ((o.z+1.0) / 2.0); // -1,+1 -> 0,2 -> 0,1
	clip += targetDepth - 0.5;
	o.z = (clip*2)-1; // 0-1 -> 0-2 -> -1,+1

	gl_Position = o;
}
