
vec3 rgb2hsv(vec3 c);

vec3 hsv2rgb(vec3 c);

vec3 desaturate(vec3 color, float amount);

void quantise(inout float amount, float steps);

float max(float a, float b);

float clamp(float a, float b, float c);

vec3 clamp(vec3 a, float min, float max);

vec2 clamp(vec2 a, float min, float max);

vec3 lerp(vec3 a, vec3 b, float s);