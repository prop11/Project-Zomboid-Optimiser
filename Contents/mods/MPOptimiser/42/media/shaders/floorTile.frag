#version 120

varying vec4 vertColour;
varying vec3 vertNormal;
varying vec2 texCoords;

uniform sampler2D Texture;
uniform int floorLayer = 0;

#include "util/math"

void main()
{
    // Output color
    vec4 fragCol = vec4(0,1,0,1);

    vec2 uv = texCoords;

    vec4 texSample;
    texSample = texture2D(Texture, uv);
    fragCol = texSample;

    // Blend vertex colour
    fragCol *= vertColour;

    // DEBUG: Show vert colour only
    //fragCol.rgb = vertColour.rgb;

    // Commit
    gl_FragColor = fragCol;
}
