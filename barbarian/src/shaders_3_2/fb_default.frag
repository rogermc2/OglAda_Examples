
#version 410 core

out vec4 frag_colour;

in vec2 st;

uniform sampler2D tex;

void main ()
    {
	frag_colour = texture (tex, st);
    }