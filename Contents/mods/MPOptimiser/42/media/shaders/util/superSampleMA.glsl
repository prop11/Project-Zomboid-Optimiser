#version 120

/// <summary>
/// sampleMaxAlpha
///  Takes a sample of the supplied texture, at the specified uv coordinates.
///
///  If the sample's alpha is higher than the supplied highestFragCol,
///   the new sample is stored there, and found is set to TRUE
///
///  If the sample's alpha is less than the supplied highestFragCol,
///   the sample is ignored and parameters are unmodified.
/// </summary>
void sampleMaxAlpha(sampler2D texture, vec2 uv, inout vec4 highestFragCol, inout bool found)
{
    if (uv.x > 1.0 || uv.x < 0.0 || uv.y > 1.0 || uv.y < 0.0)
    {
        // Clamp
        return;
    }

    vec4 padSample = texture2D(texture, uv);

    if (padSample.a >= highestFragCol.a)
    {
        found = true;
        highestFragCol = padSample;
    }
}

/// <summary>
/// superSampleSquare
///  Super-sampling pattern: []
///  Sample count: 8x8 = 64
///  Samples along the square area specified by the padRadius.
///  Stores the result in the supplied parameters: found and highestFragCol
/// </summary>
void superSampleMaxAlpha_Square(sampler2D texture, vec2 texCoords, float offsets[8], float padRadius, inout bool found, inout vec4 highestFragCol)
{
    for(int ui=0; ui < 8; ui++)
    {
        for(int vi=0; vi < 8; vi++)
        {
            vec2 offset = vec2(offsets[ui] * padRadius, offsets[vi] * padRadius);
            vec2 padUV = texCoords + offset;
            sampleMaxAlpha(texture, padUV, highestFragCol, found);
        }
    }
}

/// <summary>
/// superSampleHoriz
///  Super-sampling pattern: -
///  Sample count: 8
///  Samples along the horizontal line for the highest alpha.
///  Stores the result in the supplied parameters: found and highestFragCol
/// </summary>
void superSampleMaxAlpha_Horiz(sampler2D texture, vec2 texCoords, float offsets[8], float padRadius, inout bool found, inout vec4 highestFragCol)
{
    for(int ui=0; ui < 8; ui++)
    {
        vec2 offset = vec2(offsets[ui] * padRadius, 0);
        vec2 padUV = texCoords + offset;
        sampleMaxAlpha(texture, padUV, highestFragCol, found);
    }
}

/// <summary>
/// superSampleVert
///  Super-sampling pattern: |
///  Sample count: 8
///  Samples along the vertical line for the highest alpha.
///  Stores the result in the supplied parameters: found and highestFragCol
/// </summary>
void superSampleMaxAlpha_Vert(sampler2D texture, vec2 texCoords, float offsets[8], float padRadius, inout bool found, inout vec4 highestFragCol)
{
    for(int vi=0; vi < 8; vi++)
    {
        vec2 offset = vec2(0, offsets[vi] * padRadius);
        vec2 padUV = texCoords + offset;
        sampleMaxAlpha(texture, padUV, highestFragCol, found);
    }
}

/// <summary>
/// superSampleCross
///  Sample count: 8+8 = 16
///  Super-sampling pattern: +
///  Samples along the horizontal and vertical lines for the highest alpha.
///  Stores the result in the supplied parameters: found and highestFragCol
/// </summary>
void superSampleMaxAlpha_Cross(sampler2D texture, vec2 texCoords, float offsets[8], float padRadius, inout bool found, inout vec4 highestFragCol)
{
    superSampleMaxAlpha_Horiz(texture, texCoords, offsets, padRadius, found, highestFragCol);
    superSampleMaxAlpha_Vert(texture, texCoords, offsets, padRadius, found, highestFragCol);
}

/// <summary>
/// superSampleForMaxAlpha
///  Super-sampling utility function. Takes a sample of the immediate vicinity for the highest-alpha, within the given radius.
///  Stores the result in the supplied fragCol parameter
/// </summary>
void superSampleMaxAlpha(sampler2D texture, vec2 texCoords, vec4 texSample, float padRadius, inout vec4 fragCol)
{
    bool found = false;
    vec4 highestFragCol = texSample;

    // Find highest alpha
    float offsets[8];
    offsets[0] = -4.0;
    offsets[1] = -3.0;
    offsets[2] = -2.0;
    offsets[3] = -1.0;
    offsets[4] = 1.0;
    offsets[5] = 2.0;
    offsets[6] = 3.0;
    offsets[7] = 4.0;

    // Scan Neighborhood
    //superSampleMaxAlpha_Square(texture, texCoords, offsets, padRadius, found, highestFragCol);
    superSampleMaxAlpha_Cross(texture, texCoords, offsets, padRadius, found, highestFragCol);
    //superSampleMaxAlpha_Horiz(texture, texCoords, offsets, padRadius, found, highestFragCol);
    //superSampleMaxAlpha_Vert(texture, texCoords, offsets, padRadius, found, highestFragCol);

    fragCol = highestFragCol;
    //fragCol.a = texSample.a;

    if (!found)
    {
        // DEBUG: No higher alpha found
        //fragCol = vec4(1.0, 0.0, 0.0, 1.0);
    }
    else
    {
        // DEBUG: Higher alpha found
        //fragCol = vec4(0.0, 1.0, 1.0, 1.0);
    }
}

/// <summary>
/// superSampleMA (Max Alpha)
///  Super-sampling utility function. Takes a sample of the supplied texture, and its immediate vicinity, for the highest-alpha, within the given radius.
///  Returns the result.
/// </summary>
vec4 superSampleMA(sampler2D texture, vec2 texCoords, float padRadius, float minAlpha)
{
    vec4 fragCol = vec4(0,1,0,1);

    // Texture sample
	vec4 texSample = texture2D(texture, texCoords);

	//texSample.a = 1.0;

	// Alpha test
	if(texSample.a < minAlpha)
	{
	    // Alpha test failed, abort
        return vec4(1,0,0,0);
	}

    if(texSample.w < 0.99)
    {
        superSampleMaxAlpha(texture, texCoords, texSample, padRadius, fragCol);
    }
    else
    {
        fragCol = texSample;
    }

    return fragCol;
}