#version 110

uniform sampler2D texture;
varying vec4 v_wallShadeColor;

void main()
{
	// Sample the object texture.
	vec4 texColorWall = texture2D(texture, gl_TexCoord[0].st);

	// Multiply by the interpolated wall-lighting color.
	texColorWall.rgb *= v_wallShadeColor.rgb;

	gl_FragColor = texColorWall;
}
