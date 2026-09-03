#version 330

in float alpha;
in vec2 texCoord;

uniform sampler2D FireTexture;

void main()
{
    //mainImage( gl_FragColor, vec2(gl_FragCoord.x/WViewport.x, 1.0 - gl_FragCoord.y/WViewport.y) );
    
    vec4 color = texture2D(FireTexture, texCoord);
    float texAlpha = color.a*alpha;
    gl_FragColor = vec4(color.rgb, texAlpha);
}

