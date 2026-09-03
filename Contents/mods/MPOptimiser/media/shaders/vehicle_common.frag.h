vec3 addDamage(vec3 col, vec4 texDamage, vec3 paintHSV, vec3 lighting, vec3 TintColourNew, float alpha);

vec3 addBlood(vec4 texColorBlood2, vec4 colmask, float intensity, float alpha2, vec3 lighting, vec3 TintColourNew, vec3 colOut);

vec3 colorDebug(vec3 col, mat4 texen1, mat4 texen2, float windowAlpha, float frontAlpha, float tailAlpha, float noTintAlpha, vec4 texColorMask);


// FF = 1.00
// C0 = 0.75
// 7F = 0.50
// 40 = 0.25

const vec3 colZone1 = vec3(1.00, 0.00, 0.00); // m00 Head
const vec3 colZone2 = vec3(0.00, 1.00, 0.00); // m10 Tail
const vec3 colZone3 = vec3(0.00, 1.00, 1.00); // m20 Door RH
const vec3 colZone4 = vec3(1.00, 1.00, 0.00); // m30 Door RT
const vec3 colZone5 = vec3(1.00, 0.00, 1.00); // m01 Door LH
const vec3 colZone6 = vec3(0.00, 0.00, 1.00); // m11 Door LT
const vec3 colZone7 = vec3(0.00, 0.50, 0.50); // m21 Window RH
const vec3 colZone8 = vec3(0.50, 0.50, 0.00); // m31 Window RT
const vec3 colZone9 = vec3(0.50, 0.00, 0.50); // m02 Window LH
const vec3 colZone10 = vec3(0.00, 0.00, 0.50); // m12  Window LT
const vec3 colZone11 = vec3(0.50, 0.00, 0.00); // m22 Window T
const vec3 colZone12 = vec3(0.00, 0.50, 0.00); // m32 Window H
const vec3 colZone13 = vec3(0.00, 0.75, 0.75); // m03 Guard RH
const vec3 colZone14 = vec3(0.75, 0.75, 0.00); // m13 Guard RT
const vec3 colZone15 = vec3(0.75, 0.00, 0.75); // m23 Guard LH
const vec3 colZone16 = vec3(0.00, 0.00, 0.75); // m33 Guard LT
const vec3 colZone17 = vec3(0.00, 0.00, 0.00); // m00 Roof
const vec3 colZone18 = vec3(0.25, 0.00, 0.00); // m10 Lights R H
const vec3 colZone19 = vec3(0.75, 0.00, 0.00); // m20 Lights L H
const vec3 colZone20 = vec3(0.00, 0.75, 0.00); // m30 Lights R T
const vec3 colZone21 = vec3(0.00, 0.25, 0.00); // m01 Lights L T
const vec3 colZone22 = vec3(0.50, 0.25, 0.00); // m11 StopLights R
const vec3 colZone23 = vec3(0.50, 0.75, 0.00); // m21 StopLights L
const vec3 colZone24 = vec3(0.75, 0.75, 0.75); // m31 LightBar R
const vec3 colZone25 = vec3(0.25, 0.25, 0.25); // m02 LightBar L
const vec3 colZone26 = vec3(1.00, 0.00, 0.50); // m12 Hood FF007F
const vec3 colZone27 = vec3(0.00, 1.00, 0.50); // m22 Boot 00FF7F

