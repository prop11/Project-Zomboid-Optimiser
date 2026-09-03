#version 430

in vec2 uv;

out vec4 colour;

uniform sampler2D Tex;
uniform vec2 UVScale = vec2(1.0, 1.0);

void main()
{
    vec2 scale = UVScale;

    colour = texture2D(Tex, uv * scale, 1.0);
}
