#version 430

#define DECLARE_SKINNING(weights, indices, matrices) \
\
layout (location = weights) in vec4 boneWeights; \
layout (location = indices) in vec4 boneIndices; \
layout (std430) buffer boneMatrices \
{ \
    int boneCount; \
    mat4 boneMatrix[]; \
};

#define BONE_INDEX(offset) gl_InstanceID * boneCount + offset
#define BONE_ID(offset) BONE_INDEX(int(boneIndices[offset])])
#define BONE_MATRIX(offset) boneMatrix[BONE_ID(offset)]
#define WEIGHTED_BONE_MATRIX(offset) BONE_MATRIX(offset) * boneWeights[offset]

#define CALC_SKIN_MATRIX(matrix) \
mat4 matrix = mat4(0.0); \
\
matrix += WEIGHTED_BONE_MATRIX(0); \
matrix += WEIGHTED_BONE_MATRIX(1); \
matrix += WEIGHTED_BONE_MATRIX(2); \
matrix += WEIGHTED_BONE_MATRIX(3);
