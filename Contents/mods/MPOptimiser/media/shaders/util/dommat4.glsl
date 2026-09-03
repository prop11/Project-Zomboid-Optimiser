#version 110

float dommat4(mat4 a, mat4 b)
{
    return dot(a[0], b[0]) + dot(a[1], b[1]) + dot(a[2], b[2]) + dot(a[3], b[3]);
}