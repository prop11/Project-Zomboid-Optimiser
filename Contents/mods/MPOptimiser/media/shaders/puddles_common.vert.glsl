#version 330

layout (location = 0) in vec2 vertex;
layout (location = 1) in vec4 color;
layout (location = 2) in float aDirNE;
layout (location = 3) in float aDirNW;
layout (location = 4) in float aDirAll;
layout (location = 5) in float aDirNone;
layout (location = 6) in float aFragDepth;

uniform mat4 ModelViewProjection;

out float puddlesDirNE;
out float puddlesDirNW;
out float puddlesDirAll;
out float puddlesDirNone;
out vec4 vertColour;
out float vDepth;

void puddlesMain(void)
{
	gl_Position = ModelViewProjection * vec4(vertex.xy, 0, 1);
	vertColour = color;

	puddlesDirNE = aDirNE;
	puddlesDirNW = aDirNW;
	puddlesDirAll = aDirAll;
	puddlesDirNone = 1.0 - aDirNone;
	vDepth = aFragDepth;
}
