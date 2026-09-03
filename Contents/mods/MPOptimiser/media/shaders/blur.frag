#version 110
uniform sampler2D DIFFUSE;

varying vec2 texCoord;


uniform vec4 ScreenInfo;

//blur options:
const float blur_pi = 6.28318530718; 	// Pi times 2
const float blur_directions = 8.0; 		// def. 16.0 - higher number is more slow
const float blur_quality = 3.0; 			// def. 3.0 - higher number is more slow
const float blur_size = 12.0; 			// def. 8.0

#include "util/math"

vec4 blur(in vec4 col, in float alpha) {
	vec2 rad = blur_size/ScreenInfo.xy;

	vec2 uv = texCoord.st;
	vec4 c = texture2D(DIFFUSE, uv);

	for( float d=0.0; d<blur_pi; d+=blur_pi/blur_directions)
	{
		for(float i=1.0/blur_quality; i<=1.0; i+=1.0/blur_quality)
		{
			c += texture2D( DIFFUSE, uv+vec2(cos(d),sin(d))*rad*i);
		}
	}

	c /= (blur_quality * blur_directions - 15.0);
	c.rgb = clamp(c.rgb,0.0,1.0);
	c.a = clamp(c.a,0.0,1.0);
	return (col*(1.0-alpha))+(c*alpha);
}

void main()
{

	vec4 col = vec4(0,0,0,0);
	col = blur(col, 1.0);

	col.a *= 0.1;
	gl_FragColor = col;
}
