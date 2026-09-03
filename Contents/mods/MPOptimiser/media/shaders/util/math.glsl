#version 110

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 desaturate(vec3 color, float amount)
{
    vec3 gray = vec3(dot(vec3(0.2126,0.7152,0.0722), color));
    return vec3(mix(color, gray, amount));
}

void quantise(inout float amount, float steps)
{
	amount *= steps;
	amount = ceil(amount);
	amount /= steps;
}

float max(float a, float b)
{
    if(a > b) return a;
    return b;
}

float min(float a, float b)
{
    if(a < b) return a;
    return b;
}

float clamp(float a, float min, float max)
{
    if(a > max) return max;
    if(a < min) return min;
    return a;
}

vec3 clamp(vec3 a, float min, float max)
{
    vec3 result;
    result.x = clamp(a.x, min, max);
    result.y = clamp(a.y, min, max);
    result.z = clamp(a.z, min, max);
    return result;
}

vec2 clamp(vec2 a, float min, float max)
{
    vec2 result;
    result.x = clamp(a.x, min, max);
    result.y = clamp(a.y, min, max);
    return result;
}

vec3 lerp(vec3 a, vec3 b, float s)
{
    return vec3(a + (b - a) * s);
}