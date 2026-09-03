#version 330

uniform sampler2D DIFFUSE;
uniform int useTexture = 1;

in vec4 col;
in vec2 texCoord;

void main()
{
    vec4 c = vec4(1.0, 1.0, 1.0, 1.0);

    if(useTexture==1)
    c = texture2D(DIFFUSE, texCoord.st, 0.0);

    c *= col;
    //c.rgb *= c.a;

    // Without these 2 lines, transparent pixels write to the depth buffer around zombies rendered as textures (via DeadBodyAltas)
    if (c.a == 0.0)
        discard;

    gl_FragColor = c;
}
