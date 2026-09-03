#version 120

#include "util/math"
#include "util/dommat4"

vec3 addDamage(vec3 col, vec4 texDamage, vec3 paintHSV, vec3 lighting, vec3 TintColourNew, float alpha)
{
	vec3 fragHSV = rgb2hsv(texDamage.xyz).xyz;
	fragHSV.x = paintHSV.x;
	fragHSV.y = clamp(fragHSV.y + paintHSV.y - 0.5, 0.0, 0.9999);
	fragHSV.z = clamp(fragHSV.z + paintHSV.z - 0.5, 0.0, 0.9999);
	fragHSV.xyz = mod(fragHSV.xyz, 1.0);
	col = mix(col, hsv2rgb(fragHSV)/** lighting * TintColourNew*/, texDamage.a * 0.75 * alpha);
	return col;
}

#if 0
vec3 addBlood(mat4 matMask1, mat4 matMask2, vec3 lighting, vec3 TintColourNew, vec3 col)
{
	vec4 texColorBlood1 = texture2D(TextureDamage1Overlay, texCoords1);
	vec4 texColorBlood2 = texture2D(TextureDamage2Overlay, texCoords1);

	float alpha1 = step(0.5, dommat4(matMask1, MatBlood1Enables1) + dommat4(matMask2, MatBlood1Enables2));
	float alpha2 = step(0.5, dommat4(matMask1, MatBlood2Enables1) + dommat4(matMask2, MatBlood2Enables2));

	col = mix(col, texColorBlood1.rgb * lighting * TintColourNew, texColorBlood1.a * alpha1);
	col = mix(col, texColorBlood2.rgb * lighting * TintColourNew, texColorBlood2.a * alpha2);

	return col;
}
#endif

vec3 addBlood(vec4 texColorBlood2, vec4 colmask, float intensity, float alpha2, vec3 lighting, vec3 TintColourNew, vec3 colOut)
{
	// See overlayMask.frag. This is how blood is done on clothes.

	vec3 col = texColorBlood2.rgb;

	float a = 1 - pow(1 - texColorBlood2.a, 3);
	float mask_a = 1 - pow(1 - colmask.a, 3);

	float fa = a * mask_a;

//	intensity *= intensity;

	float intens = clamp(intensity, 0.0, 1.0);
	if (intens < 0.0001)
		return colOut;

/*
	float intensity2 = intensity - 1.0;
	intensity2 = clamp(intensity2, 0, 0.6);

	fa += mask_a * intensity2;
	fa = clamp(fa, 0, 1);
*/

	fa = clamp((fa - (1.0 - intens)) / intens, 0.0, 1.0);

	col *= fa;

	colOut = mix(colOut, col/** lighting * TintColourNew*/, fa * texColorBlood2.a * alpha2);

	return colOut;
}

vec3 colorDebug(vec3 col, mat4 texen1, mat4 texen2, float windowAlpha, float frontAlpha, float tailAlpha, float noTintAlpha, vec4 texColorMask)
{
//	col = mix(col, vec3(1.0,0.0,0.0), frontAlpha);
//	col = mix(col, vec3(1.0,0.0,0.0), tailAlpha);
//	col = mix(col, texColorMask.rgb, texen1[3][2]);
//	col = mix(col, texColorMask.rgb, texen2[1][1]); // brake light
//	col = mix(col, texColorMask.rgb, texen2[1][2]); // brake light
//	col = mix(col, texColorMask.rgb, texColorMask.a);
	return col;
}
