#version 330

uniform sampler2D texture;
uniform sampler2D CutawayStencil;
uniform sampler2D DEPTH;

in vec4 v_wallShadeColor;
in vec2 texCoord;
in vec2 texCoord2;
in vec2 texCoord3;

uniform float zDepthBlendZ = 0;
uniform float zDepthBlendToZ = 0;
uniform float discardValue = 0.0;

void main()
{
	// Sample the object texture
	vec4 texColorWall = texture2D(texture, texCoord.st);

	// Sample the circle-stencil texture
	vec4 texCutawayStencil = texture2D(CutawayStencil, texCoord2.st);

	if (texCutawayStencil.r > 0.0 != discardValue > 0.0)
	{
	    discard;
	}

	// Multiply by the wall-lighting color
	texColorWall.rgb *= v_wallShadeColor.rgb;

	// Set alpha from the stencil alpha
	// TODO: Make the circle-stencil texture with a "smooth" outer fringe.
	texColorWall.rgba *= texCutawayStencil.rrra;
	texColorWall.rgb += 0.75 * texCutawayStencil.b;
	texColorWall.a = max(texColorWall.a, texCutawayStencil.b * texCutawayStencil.a);
	texColorWall.a = max(texColorWall.a, texCutawayStencil.g * texCutawayStencil.a);
	texColorWall.rgb -= texCutawayStencil.g;
    //texColorWall.a *= texCoord2.s;

	// Outline alpha
	texColorWall.a *= v_wallShadeColor.a;

	float d = texture2D(DEPTH, texCoord3.st, 0.0).r;

	if (texColorWall.a == 0 || d == 0.0)
	{
	    discard;
	}

	float calcDepthZ = ((zDepthBlendToZ-zDepthBlendZ) * d) + zDepthBlendZ;
	gl_FragDepth = calcDepthZ;

    //texColorWall.rgb = texCutawayStencil.rgb;
	gl_FragColor = texColorWall;
}
