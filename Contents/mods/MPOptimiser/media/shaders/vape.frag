#version 330

in vec4 color;
in vec2 texCoord;

uniform sampler2D FireTexture;

void main()
{
    //mainImage( gl_FragColor, vec2(gl_FragCoord.x/WViewport.x, 1.0 - gl_FragCoord.y/WViewport.y) );
    
    vec4 colorTex = texture2D(FireTexture, texCoord);
    float colorg = (1.0-colorTex.g*color.a);
    gl_FragColor = vec4(colorg*color.rgb, colorTex.g*color.a);
}

