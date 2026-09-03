#version 120

#include "math"

vec3 hueShift(vec3 col, float amount)
{
    vec3 col3 = rgb2hsv(col);
    col3.r += amount;
    while(col3.r > 1.0)
    {
        col3.r -= 2.0;
    }

    while(col3.r < -1.0)
    {
        col3.r += 2.0;
    }

    col = hsv2rgb(col3);
    return col;
}