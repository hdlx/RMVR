# RMVR
VR Compatible Raymarching for Unity

RMVR sets up a raymarching environnement in Unity, allowing you to play with distance functions and to display procedural shapes and fractals.
Have a look on the project sample scene. On the camera is the Raymarching component. Everything happens here.

The 3 tabs correspond to 1 - Optimisation, 2 - Shading, and 3 - Distance function to use and variable passed to it. Try some of the included 
presets.

This tool is also meant to work in VR. Stereo is optimised using a screen space reprojection technique.
You can shade the shapes like you would with a standard material, with additionnal features adapted from raymarching demos, like pseudo-SSS, 
AO, or glow. You can mix meshes and raymarching with depth awareness.
Write your own distance function into one of the 8 "maps" slots in the "Assets/Raymarching/Resources/Shaders/CGInc/RMMaps.cginc" file.
It has to return some custom struct. This allows you to return a procedural color and to use it in the shading. Also note that some variables
are systematically passed to the distance function.
The others CGINCLUDE files contain a lot of usefull functions for distance fields, shader maths, noises.
Theses are not well documented yet, but should look familiar to shader programmers.
I just made this project public. A cleaner documentation and nice pictures and video are coming.
