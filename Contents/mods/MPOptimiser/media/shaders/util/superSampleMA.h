
/// <summary>
/// superSampleMA (Max Alpha)
///  Super-sampling utility function. Takes a sample of the supplied texture, and its immediate vicinity, for the highest-alpha, within the given radius.
///  Returns the result.
/// </summary>
vec4 superSampleMA(sampler2D texture, vec2 texCoords, float padRadius, float minAlpha);

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
void sampleMaxAlpha(sampler2D texture, vec2 uv, inout vec4 highestFragCol, inout bool found);

/// <summary>
/// superSampleSquare
///  Super-sampling pattern: []
///  Sample count: 8x8 = 64
///  Samples along the square area specified by the padRadius.
///  Stores the result in the supplied parameters: found and highestFragCol
/// </summary>
void superSampleMaxAlpha_Square(sampler2D texture, vec2 texCoords, float offsets[8], float padRadius, inout bool found, inout vec4 highestFragCol);

/// <summary>
/// superSampleHoriz
///  Super-sampling pattern: -
///  Sample count: 8
///  Samples along the horizontal line for the highest alpha.
///  Stores the result in the supplied parameters: found and highestFragCol
/// </summary>
void superSampleMaxAlpha_Horiz(sampler2D texture, vec2 texCoords, float offsets[8], float padRadius, inout bool found, inout vec4 highestFragCol);

/// <summary>
/// superSampleVert
///  Super-sampling pattern: |
///  Sample count: 8
///  Samples along the vertical line for the highest alpha.
///  Stores the result in the supplied parameters: found and highestFragCol
/// </summary>
void superSampleMaxAlpha_Vert(sampler2D texture, vec2 texCoords, float offsets[8], float padRadius, inout bool found, inout vec4 highestFragCol);

/// <summary>
/// superSampleCross
///  Sample count: 8+8 = 16
///  Super-sampling pattern: +
///  Samples along the horizontal and vertical lines for the highest alpha.
///  Stores the result in the supplied parameters: found and highestFragCol
/// </summary>
void superSampleMaxAlpha_Cross(sampler2D texture, vec2 texCoords, float offsets[8], float padRadius, inout bool found, inout vec4 highestFragCol);

/// <summary>
/// superSampleForMaxAlpha
///  Super-sampling utility function. Takes a sample of the immediate vicinity for the highest-alpha, within the given radius.
///  Stores the result in the supplied fragCol parameter
/// </summary>
void superSampleMaxAlpha(sampler2D texture, vec2 texCoords, vec4 texSample, float padRadius, inout vec4 fragCol);