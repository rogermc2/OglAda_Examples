#version 410 core

layout (location = 0) in vec3 position;

void main(void)
{
    gl_PointSize = 4.0;
    gl_Position = vec4(position * 0.03, 1.0);
}
