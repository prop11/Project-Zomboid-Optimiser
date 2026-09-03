#version 330

uniform sampler2D texture;
uniform sampler2D CutawayStencil;

in vec4 v_wallShadeColor;
in vec2 texCoord;
in vec2 texCoord2;

void main()
{
	// Sample the object texture
	vec4 texColorWall = texture2D(texture, texCoord.st);

	// Sample the circle-stencil texture
	vec4 texCutawayStencil = texture2D(CutawayStencil, texCoord2.st);

    // Don't render the door-frame or window-frame outline
	if (texCutawayStencil.g + texCutawayStencil.b > 0.0)
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

    //texColorWall.rgb = texCutawayStencil.rgb;
	gl_FragColor = texColorWall;
}
