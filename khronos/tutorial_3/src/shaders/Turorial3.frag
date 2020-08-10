#version 410 core
// Some drivers require this next line to function properly
precision highp float;

in  vec3 ex_Colour;
out vec4 gl_FragColour;

void main(void)
    {
    // Pass the original colour with full opacity.
    gl_FragColour = vec4(ex_Colour, 1.0);
    }
