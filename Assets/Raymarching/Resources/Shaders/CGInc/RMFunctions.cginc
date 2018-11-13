//Distance field operators and usual maths functions.
//Most of it comes from https://www.iquilezles.org and http://mercury.sexy

static const float PI = 3.14159265f;

// __ Matrix functions __ _____________________________________

// Return 2x2 rotation matrix
// With floattor swizzle/mask can use as a 3x3 xform
// For y, you need to invert 
// angle in radians
float2x2 Rot2(float a) {
	float c = cos(a);
	float s = sin(a);
	return float2x2(c, -s, s, c);
}

// http://www.songho.ca/opengl/gl_anglestoaxes.html

// Return 4x4 rotation X matrix
// angle in radians
float4x4 Rot4X(float a) {
	float c = cos(a);
	float s = sin(a);
	return float4x4(1, 0, 0, 0,
		0, c, -s, 0,
		0, s, c, 0,
		0, 0, 0, 1);
}

// Return 4x4 rotation Y matrix
// angle in radians
float4x4 Rot4Y(float a) {
	float c = cos(a);
	float s = sin(a);
	return float4x4(c, 0, s, 0,
		0, 1, 0, 0,
		-s, 0, c, 0,
		0, 0, 0, 1);
}

// Return 4x4 rotation Z matrix
// angle in radians
float4x4 Rot4Z(float a) {
	float c = cos(a);
	float s = sin(a);
	return float4x4(
		c, -s, 0, 0,
		s, c, 0, 0,
		0, 0, 1, 0,
		0, 0, 0, 1
	);
}

float4x4 RotAA(float3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return float4x4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

// Translate is simply: p - d
// opTx will do transpose(m)
// p' = m*p
//    = [m0 m1 m2 m3 ][ p.x ]
//      [m4 m5 m6 m7 ][ p.y ]
//      [m8 m9 mA mB ][ p.z ]
//      [mC mD mE mF ][ 1.0 ]
float4x4 Loc4(float3 p) {
	p *= -1.;
	return float4x4(
		1, 0, 0, p.x,
		0, 1, 0, p.y,
		0, 0, 1, p.z,
		0, 0, 0, 1
	);
}


//// if no support for GLSL 1.2+
////     #version 120
//float4x4 transposeM4(float4x4 m) {
//	float4 r0 = m[0];
//	float4 r1 = m[1];
//	float4 r2 = m[2];
//	float4 r3 = m[3];
//
//	float4x4 t = float4x4(
//		float4(r0.x, r1.x, r2.x, r3.x),
//		float4(r0.y, r1.y, r2.y, r3.y),
//		float4(r0.z, r1.z, r2.z, r3.z),
//		float4(r0.w, r1.w, r2.w, r3.w)
//	);
//	return t;
//}


// __ Smoothing functions _____________________________________

// Smooth Min
// http://www.iquilezles.org/www/articles/smin/smin.htm

// Min Polynomial
float sMinP(float a, float b, float k) {
	float h = clamp(0.5 + 0.5*(b - a) / k, 0.0, 1.0);
	return lerp(b, a, h) - k*h*(1.0 - h);
}

// Min Exponential
float sMinE(float a, float b, float k) {
	float res = exp(-k*a) + exp(-k*b);
	return -log(res) / k;
}


float sMaxE(float a, float b, float k) {
	float res = exp(k*a) + exp(k*b);

	return log(res) / k ;

}

// Min Power
float sMin(float a, float b, float k) {
	a = pow(a, k);
	b = pow(b, k);
	return pow((a*b) / (a + b), 1.0 / k);
}

// __ Surface Primitives ____________________________

// Return max component x, y, or z
float maxcomp(in float3 p) {
	return max(p.x, max(p.y, p.z));
}

// Signed

// b.x = Width
// b.y = Height
// b.z = Depth
// Leave r=0 if radius not needed
float sdBox(float3 p, float3 b, float r) {
	float3 d = abs(p) - b;
	return min(maxcomp(d), 0.0) - r + length(max(d, 0.0));
	// Inlined maxcomp
	//return min(max(d.x,max(d.y,d.z)),0.0) - r + length(max(d,0.0));
}


float sdCappedCylinder(float3 p, float2 h) {
	float2 d = abs(float2(length(p.xz), p.y)) - h;
	return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}


float sdCapsule(float3 p, float3 a, float3 b, float r) {
	float3 pa = p - a, ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba*h) - r;
}

// c.x Width
// c.y Base Radius
// c.z Depth
// Note: c must be normalized
float sdCone(float3 p, float3 c) // TODO: do we need to use 'in' for all primitives?
{
	float q = length(p.xz);
	return dot(c.xy, float2(q, p.y));
}


float sdCylinder(float3 p, float3 c) {
	return length(p.xz - c.xy) - c.z;
}

// n.xyz = point on plane
// n.w   = distance to plane
// Note: N must be normalized!
float sdPlane(float3 p, float4 n) {
	return dot(p, n.xyz) + n.w;
}

// 4 sided pyramid
// h.x = base X
// h.y = height
// h.z = base Z (usually same as h.x)
float sdPyramid4(float3 p, float3 h) {
	p.xz = abs(p.xz);                   // Symmetrical about XY and ZY
	float3 n = normalize(h);
	return sdPlane(p, float4(n, 0.0)); // cut off bottom
}


float sdSphere(float3 p, float r) {
	return length(p) - r;
}


float sdSphere2(float3 p, float r) {
	return abs(length(p) - r);
}


float sdTorus(float3 p, float2 t) {
	float2 q = float2(length(p.xy) - t.x, p.z);
	return length(q) - t.y;
}

// TODO: document/derive magic number 0.866025
float sdTriPrism(float3 p, float2 h) {
	float3 q = abs(p);
	return max(q.z - h.y, max(q.x*0.866025 + p.y*0.5, -p.y) - h.x*0.5);
}

// Unsigned

// Box
float udBox(float3 p, float3 b) {
	return length(max(abs(p) - b, 0.0));
}

// Round Box
float udRoundBox(float3 p, float3 b, float r)
{
	return length(max(abs(p) - b, 0.0)) - r;
}

// __ Distance Operations _____________________________________

// Basic
// Op Union
float opU(float d1, float d2) {
	return min(d1, d2);
}

// Op Union
float4 opU2(float4 d1, float4 d2) {
	return min(d1, d2);
}

// Op Union
float4 opU(float4 a, float4 b) {
	return lerp(a, b, step(b.x, a.x));
}

float2 opU(float2 a, float2 b) {
	return lerp(a, b, step(b.x, a.x));
}

// Op Subtraction
float opS(float a, float b) {
	return max(-b, a); // BUG in iq's docs: -a, b
}
// Op Subtraction
float4 opS(float4 a, float4 b) {
	return max(-b, a);
}

// Op Intersection
float opI(float a, float b) {
	return max(a, b);
}


// Advanced
float opBlend(float a, float b, float k) {
	return sMin(a, b, k);
}

// a angle
float displacement(float3 p, float a) {
	return sin(a*p.x)*sin(a*p.y)*sin(a*p.z); // NOTE: Replace with your own!
}


float opDisplace(float3 p, float d1, float d2) {
	return d1 + d2;
}

// Op Union Translated
float4 opUt(float4 a, float4 b, float fts) {
	float4 vScaled = float4(b.x * (fts * 2.0 - 1.0), b.yzw);
	return lerp(a, vScaled, step(vScaled.x, a.x) * step(0.0, fts));
}


// __ Domain Operations _______________________________________

// NOTE: iq originally inlined the primitive inside the Domain operations. :-(
// This implied that you would have needed to provide 
// a primitive with one of the sd*() functions above
// since we can't have a generic pointer to a function!
// However we have moved them back out to the caller
// for clarity and flexibility without general loss of precision.

// Basic

float mod(float x, float y)
{
  return x - y * floor(x/y);
}

float3 mod3(float3 a, float3 b)
{
  return float3 ( mod(a.x,b.x), mod(a.y,b.y),mod(a.z,b.z))   ;

}

// Op Repetition
float3 opRep(float3 p, float3 spacing) {

	    float3 q = mod3(p+spacing*0.5,spacing) - spacing*0.5;

		//q = floor(p)*0.5 % -spacing + 0.5 * spacing; 
    return  q;
}

// Deformations

// Op Twist X
float3 opTwistX(float3 p, float angle) {
	float2x2 m = Rot2(angle * p.x);
	return float3(mul(m,p.yz), p.x);
}

// Op Twist Y
float3 opTwistY(float3 p, float angle) {
	float2x2 m = Rot2(angle * p.y);
	return   float3(mul(m,p.xz), p.y);
}

// Op Twist Z
float3 opTwistZ(float3 p, float angle) {
	float2x2 m = Rot2(angle * p.z);
	return   float3(mul(m,p.xy), p.z);
}

// iq's bend X
float3 opCheapBend(float3 p, float angle) {
	float2x2  m = Rot2(angle * p.y);
	float3  q = float3(mul(m,p.yx), p.z);
	return q;
}

// Op Cheap Bend X
float3 opBendX(float3 p, float angle) {
	float2x2 m = Rot2(angle * p.y);
	return   float3(mul(m,p.yx), p.z);
}

// Op Cheap Bend Y
float3 opBendY(float3 p, float angle) {
	float2x2 m = Rot2(angle * p.z);
	return   float3(mul(m,p.zy), p.x);
}

// Op Cheap Bend Z
float3 opBendZ(float3 p, float angle) {
	float2x2 m = Rot2(angle * p.x);
	return   float3(mul(m,p.xz), p.y);
}

// d = distance to move
float3 opTrans(float3 p, float3 d) {
	return p - d;
}

// Note: m must already be inverted!
// TODO: invert(m) transpose(m)
// Op Rotation / Translation
float3 opTx(float3 p, float4x4 m) {   // BUG in iq's docs, should be q
	return (mul(transpose(m),float4(p, 1.0))).xyz;
}

// Op Scale
float opScale(float3 p, float s) {
	return sdBox(p / s, float3(1.2, 0.2, 1.0), 0.01) * s; // TODO: FIXME: NOTE: replace with primative sd*()
}


//
//                           HG_SDF
//
//     GLSL LIBRARY FOR BUILDING SIGNED DISTANCE BOUNDS
//
//     version 2016-01-10
//
//     Check http://mercury.sexy/hg_sdf for updates
//     and usage examples. Send feedback to spheretracing@mercury.sexy.
//
//     Brought to you by MERCURY http://mercury.sexy
//
//
//
// Released as Creative Commons Attribution-NonCommercial (CC BY-NC)

void pR45(inout float2 p) {
	p = (p + float2(p.y, -p.x))*sqrt(0.5);
}


float pMod1(inout float p, float size) {
	float halfsize = size*0.5;
	float c = floor((p + halfsize)/size);
	p = fmod(p + halfsize, size) - halfsize;
	return c;
}
float fOpUnionColumns(float a, float b, float r, float n) {
	if ((a < r) && (b < r)) {
		float2 p = float2(a, b);
		float columnradius = r*sqrt(2)/((n-1)*2+sqrt(2));
		pR45(p);
		p.x -= sqrt(2)/2*r;
		p.x += columnradius*sqrt(2);
		if (fmod(n,2) == 1) {
			p.y += columnradius;
		}
		// At this point, we have turned 45 degrees and moved at a point on the
		// diagonal that we want to place the columns on.
		// Now, repeat the domain along this direction and place a circle.
		pMod1(p.y, columnradius*2);
		float result = length(p) - columnradius;
		result = min(result, p.x);
		result = min(result, a);
		return min(result, b);
	} else {
		return min(a, b);
	}
}


float fOpUnionRound(float a, float b, float r) {
	float2 u = max(float2(r - a,r - b), float2(0,0));
	return max(r, min (a, b)) - length(u);
}

float fOpIntersectionRound(float a, float b, float r) {
	float2 u = max(float2(r + a,r + b), float2(0,0));
	return min(-r, max (a, b)) + length(u);
}

float fOpDifferenceRound (float a, float b, float r) {
	return fOpIntersectionRound(a, -b, r);
}

float fOpPipe(float a, float b, float r) {
	return length(float2(a, b)) - r;
}


float2 pModPolar( float2 p, float repetitions) {
	float angle = 2*PI/repetitions;
	float a = atan2(p.y, p.x) + angle/2.;
	float r = length(p);
	float c = floor(a/angle);
	a = mod(a,angle) - angle/2.;
	p = float2(cos(a), sin(a))*r;
	// For an odd number of repetitions, fix cell index of the cell in -x direction
	// (cell index would be e.g. -5 and 5 in the two halves of the cell):
	if (abs(c) >= (repetitions/2)) c = abs(c);
	return p;
}