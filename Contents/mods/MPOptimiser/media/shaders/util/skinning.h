
#define DECLARE_SKINNING(weights, indices) \
\
layout (location = weights) in vec4 boneWeights; \
layout (location = indices) in vec4 boneIndices; \
layout (std430) buffer boneMatrices \
{ \
    int boneCount; \
    mat4 boneMatrix[]; \
};

// matrix[instance + ids[component]]
#define BONE_INDEX(id) gl_InstanceID * boneCount + id
#define BONE_ID(component) BONE_INDEX(int(boneIndices[component]))
#define BONE_MATRIX(component) boneMatrix[BONE_ID(component)]
#define WEIGHTED_BONE_MATRIX(comp) BONE_MATRIX(comp) * boneWeights[comp]

#define CALC_SKIN_MATRIX(matrix) \
mat4 matrix = mat4(0.0); \
\
matrix += WEIGHTED_BONE_MATRIX(0); \
matrix += WEIGHTED_BONE_MATRIX(1); \
matrix += WEIGHTED_BONE_MATRIX(2); \
matrix += WEIGHTED_BONE_MATRIX(3);
