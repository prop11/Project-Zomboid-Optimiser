#version 430

// keep the same as Shader.INSTANCE_MAX
#define INSTANCE_MAX 128
//

// don't use outside this file
#define TEXTURE_UNIFORMS uniform sampler2DArray InstTexArr; uniform vec2 TextureDimensions;
#define INSTANCE_TEXTURE_VARS vec2 textureSize; int textureIndex;
#define INSTANCE_BUFFER_DATA InstancedStruct instancedStructs[INSTANCE_MAX];
//

// use in shaders
#define DECLARE_INSTANCING_VERT flat out int instanceID; TEXTURE_UNIFORMS
#define DECLARE_INSTANCING_FRAG flat in int instanceID; TEXTURE_UNIFORMS

#define BEGIN_INSTANCING struct InstancedStruct { INSTANCE_TEXTURE_VARS
#define END_INSTANCING }; layout (std430) buffer instancedData { INSTANCE_BUFFER_DATA };

#define COPY_INSTANCE_ID instanceID = gl_InstanceID;
#define GET_INSTANCED_STRUCT(name) InstancedStruct name = instancedStructs[instanceID];
#define TRANSFORM_UV(uv, inst) uv * inst.textureSize / TextureDimensions;
#define SAMPLE_TEXTURE_ARRAY(uv, inst) texture(InstTexArr, vec3(uv, inst.textureIndex));

#define INSTANCED_ARG(name) InstancedStruct name
//
