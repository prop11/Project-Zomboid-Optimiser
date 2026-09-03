#version 110

varying vec3 vertColour;
varying vec3 vertNormal;
varying vec2 texCoords;

attribute vec4 vertex;
attribute vec4 normal;


attribute vec4 boneWeights;
attribute vec4 boneIndices;

attribute vec2 uv;

uniform mat4 ModelViewProjection;
uniform float DepthBias;
uniform mat4 MatrixPalette[60];

void main()
{
	vec4 position = vec4(vertex.xyz, 1.0);
	vec4 normal = vec4(normal.xyz, 0.0);


	texCoords = uv.st;

	mat4 boneEffect = mat4(0.0);
	if(boneWeights.x > 0.0)
		boneEffect += MatrixPalette[int(boneIndices.x)] * boneWeights.x;
	if(boneWeights.y > 0.0)
		boneEffect += MatrixPalette[int(boneIndices.y)] * boneWeights.y;
	if(boneWeights.z > 0.0)
		boneEffect += MatrixPalette[int(boneIndices.z)] * boneWeights.z;
	if(boneWeights.w > 0.0)
		boneEffect += MatrixPalette[int(boneIndices.w)] * boneWeights.w;

	normal = boneEffect * normal;
	vertNormal = normal.xyz;
	vec3 scalevec;
	mat4 m = boneEffect;

    scalevec.x = length(vec3(m[0][0], m[0][1], m[0][2]));
    scalevec.y = length(vec3(m[1][0], m[1][1], m[1][2]));
    scalevec.z = length(vec3(m[2][0], m[2][1], m[2][2]));
    float scale = length(scalevec);
	float blood = scale;
	blood = clamp(blood, 0.0, 0.01)  * 100.0;
	vertColour = vec3(1.0,blood,blood);

	vec4 o = ModelViewProjection * boneEffect * position;
	o.z -= DepthBias;
	gl_Position = o;
}
