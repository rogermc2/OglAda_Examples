//
// Crongdor the Barbarian
// javelin stand's 'look at me' flashing lighting
// First version Anton Gerdelan, 17 June 2015
// Latest code review
//

#version 410 core

in vec3 vp; // points
in vec2 vt; // tex coords
in vec3 vn; // normals

uniform mat4 M, V, P;
uniform float ol_pass;
float ol_dist = 0.01;

out vec2 st;
out vec3 n, p;

void main ()
    {
	if (ol_pass > 0.1)
        {
		vec3 p = vp + vn * ol_dist;
		gl_Position = P * V * M * vec4 (p, 1.0);
		return;
        }
	
	st = vt;
	n = vec3 (V * M * vec4 (vn, 0.0));
	p = vec3 (V * M * vec4 (vp, 1.0));
	gl_Position = P * V * M * vec4 (vp, 1.0);
    }