#version 120

attribute vec4 vertex;
attribute vec4 normal;
attribute vec4 boneWeights;
attribute vec4 boneIndices;
attribute vec2 uv;

varying vec3 vertColour;
varying vec3 vertNormal;
varying vec2 texCoords;

uniform mat4 ModelViewProjection;
uniform float targetDepth = 0.5;
uniform float DepthBias;
uniform mat4 MatrixPalette[60];
uniform vec2 UVScale = vec2(1,1);
uniform float HighResDepthMultiplier = 0.0; // 0.5 when drawing models to double-sized chunk textures
uniform float FinalScale = 1.0;

void main()
{
	vec4 position = vec4(vertex.xyz, 1.0);
	vec4 norm = vec4(normal.xyz, 0.0);

	texCoords = uv * UVScale.xy;

	mat4 boneEffect = mat4(0.0);
	if(boneWeights.x > 0.0)
		boneEffect += MatrixPalette[int(boneIndices.x)] * boneWeights.x;
	if(boneWeights.y > 0.0)
		boneEffect += MatrixPalette[int(boneIndices.y)] * boneWeights.y;
	if(boneWeights.z > 0.0)
		boneEffect += MatrixPalette[int(boneIndices.z)] * boneWeights.z;
	if(boneWeights.w > 0.0)
		boneEffect += MatrixPalette[int(boneIndices.w)] * boneWeights.w;

	norm = boneEffect * norm;
	vertNormal = norm.xyz;
	vertColour = vec3(1.0, 1.0, 1.0);

    vec4 bonedPos = boneEffect * position;
    bonedPos.xyz = bonedPos.xyz * FinalScale;

	vec4 o = ModelViewProjection * bonedPos;

	vec4 origin = ModelViewProjection * vec4(0, 0, 0, 1);
	o.z += (origin.z - o.z) * HighResDepthMultiplier;

	float clip = ((o.z+1.0) / 2.0); // -1,+1 -> 0,2 -> 0,1
	clip += targetDepth - 0.5;
	o.z = (clip*2)-1; // 0-1 -> 0-2 -> -1,+1
	gl_Position = o;
}
