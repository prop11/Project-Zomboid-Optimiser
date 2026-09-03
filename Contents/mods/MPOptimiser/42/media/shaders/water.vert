#version 330

layout (location = 0) in vec2 vertex;
layout (location = 1) in vec4 color;
layout (location = 2) in float aDepth;
layout (location = 3) in float aFlow;
layout (location = 4) in float aSpeed;
layout (location = 5) in float aExternal;
layout (location = 6) in float aFragDepth;

uniform mat4 ModelViewProjection;

out vec4 vertColour; 
//out vec2 texCoords;
out float waterDepth;
out float waterFlow;
out float waterSpeed;
out float isExternal;
out float vDepth;

void main (void)
{
	gl_Position = ModelViewProjection * vec4(vertex.xy, 0, 1);
	vertColour = color;
	isExternal = aExternal;
	waterSpeed = isExternal * aSpeed;
	waterDepth = aDepth;
	waterFlow = isExternal * aFlow;
	vDepth = aFragDepth;
}
