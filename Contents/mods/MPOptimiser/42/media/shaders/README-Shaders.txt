Intel HD 2000/3000 are limited to OpenGL version 3.1.

MacOS is limited to OpenGL 2.1 unless deprecated API calls are removed,
in which case version 3.2 and greater are supported on MacOS.

These shader files include OpenGL 3.3 syntax which is not actually
supported on these older systems.

When pre-processing these shader files on older systems, some text
is changed:

1) "#version 330" is replaced by "#version 120", the highest GLSL version
   supported by OpenGL 2.1.

2) "layout (location = N)" text is removed, and glBindAttribLocation() is
   called instead.

3) "in" qualifier for vertex-shader inputs is replaced by "attribute"

4) "out" for vertex outputs is replaced by "varying"

5) "in" qualifier for fragment-shader inputs is replaced by "varying"
