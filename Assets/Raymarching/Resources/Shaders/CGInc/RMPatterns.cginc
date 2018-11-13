#include "RMFunctions.cginc"
#include "Procedural.cginc"

// Patterns refer to complex signed distance function. They use basic raymarching functions from RMFunctions 
// and are used in Maps defined in RMMaps.
// Somes take extra input (color and float) and return float 4 (distance + color), for animation and shading purpose.
// IFS ("fold"-named functions) adapted from http://www.fractalforums.com/sierpinski-gasket/kaleidoscopic-(escape-time-ifs)/
// Mandelbulb and appolonian adapted from IQ's shadertoy.

float truchetTower (float3 p, float r){

	float rnd = frac(sin(dot(floor(p) + 41., float3(7.63, 157.31, 113.97)))*43758.5453);

	if (rnd>.75) p = 1. - p;
	else if(rnd>.5) p = p.yzx;
	else if(rnd>.25) p = p.zxy;

	p = frac(p); 

	// Draw three toroidal shapes within the unit block, oriented in such a way to form a 3D tile.
	// It can be a little frustrating trying to get the orientaion right, but once you get the hang
	// of it, it really is pretty simple. If you're not sure what's going on, have a look at the 
	// picture in the link provided above. By the way, the following differs a little from the
	// standard torii distance equations on account of slight mutations, cost cutting, etc, but 
	// that's what it all essentially amounts to.  
	
	// Toroidal shape one.
	float3 q = p; // Not rotated.
	q.xy = length(float2(length(q.xy), q.z) - .5) + .175; // The "abs" and ".125" are additions, in this case.			------REPLACE LENGTH BY ABS FOR SHARP VERSION
	rnd = dot(q.xy, q.xy); // Reusing the "rnd" variable. Squared distance.

	// Toroidal shape two. Same as above, but rotated and shifted to a different part of the cube. 
	q = p.yzx - float3(1, 1, 0); 
	q.xy = length(float2(length(q.xy), q.z) - .5) + .175;
	rnd = min(rnd, dot(q.xy, q.xy)); // Minimum of shape one and two.
	
	// Toroidal shape three. Same as the two above, but rotated and shifted to a different part of the cube.
	q = p.zxy - float3(0, 1, 0);
	q.xy = length(float2(length(q.xy), q.z) - .5) + .175;
	rnd = min(rnd, dot(q.xy, q.xy)); // Minimum of of all three.
			
	return sqrt(rnd) - r; // Taking the square root and setting tube radius... kind of.

	}



float apollonian1 (float3 p, float aF1)
{
	float scale = 1;
	float4 orb = float4(1000,1000,1000,1000); 
	
	for( int i=0; i < 8; i++ )
	{
		p = -1.0 + 2.0*frac(0.5*p+0.5);
		float r2 = dot(p,p);
		orb = min( orb, float4(abs(p),r2) );
		float k = aF1/ r2;
		p *= k;
		scale *= k;
	}
	float res = min(abs(p.z)+abs(p.x), 
			min(abs(p.x)+abs(p.y),
				abs(p.y)+abs(p.z)));
	
	return 0.25*res/scale;
}




float4 apollonianColor(float3 p)
{
	float scale = 1;
	float4 orb = float4(1000,1000,1000,1000); 
	float r2;
	for( int i=0; i < 10;i++ )
	{
		p = -1.0 + 2.0*frac(0.5*p+0.5);
		r2 = dot(p,p);
		orb = min( orb, float4(abs(p),r2) );
		float k = 1.2/ r2;
		p *= k;
		scale *= k;
	}
	float res = min(abs(p.z)+abs(p.x), 
			max(abs(p.x)+abs(p.y),
				abs(p.y)+abs(p.z)));

	float3	color = float3 (r2,scale/100,0);
	return float4(color, 0.25*res/scale);
}


float forks(float3 p )
{
	float s = 0.1; 
	float scale = 1;

	float tt = 0.45+(sin(_Time.x*2.)*.5+.5)*.65;
	
	tt = 0.5;
	
	float4 orb = float4(1000.0,1000.0,1000.0,1000.0); 
	
	for( int i=0; i<8;i++ )
	{
		p = -1.0 + 2.0*frac(0.5*p+0.5);

		float r2 = dot(p,p);
		
		
		r2 = r2 * tt + max(abs(p.x), max(abs(p.y),abs(p.z))) * (1.0 - tt);
		
		orb = min( orb, float4(abs(p),r2) );
		
		float k = s/r2;
		p     *= k;
		scale *= k;
	}
	
	return 0.25*abs(p.y)/scale;
}

float3 fold (float3 p, float3 n ) 
{
	return p-=2.0 * min(0.0, dot(p, n)) * n;
}


float tetraFold(float3 p, float aF0, float aF1, float aF2, float aF3)
{
	float SCALE = 2;
	float3 c;
	int n = 0;
	int IT = 8;
	float ic = 0;
	float4x4 mat;
	float3 Offset = float3(1,1,1);

	aF0 = radians(aF0);
	aF1 = radians(aF1);
	aF2 = radians(aF2);
	aF3 = radians(aF3);


    while (n < IT) {


		if(p.x-p.y<0)p.xy = p.yx ;
		if(p.x-p.z<0)p.xz = p.zx ;
		if(p.y-p.z<0)p.yz = p.zy ;
		if(p.x+p.y<0)p.xy = -p.yx ;
		if(p.x+p.z<0)p.xz = -p.zx ;
		if(p.y+p.z<0)p.yz = -p.zy ;
		mat = Rot4Y  ( aF0 );
		p=mul(mat,p);
		p = p * SCALE - Offset * (SCALE-1);
		
		mat = Rot4Y (aF1 );
		p=mul(mat,p);
		n++;
    }

	float res= (length(p)-2) * pow(SCALE, -n);
	return  res;
}


float cubeFold(float3 p, float aF0, float aF1, float aF2)
{
	float SCALE = aF2;
	float3 c;
	int n = 0;
	int IT = 11;
	float ic = 0;
	float4x4 mat;
	float3 Offset = float3(1,1,1);

	aF0 = radians(aF0);
	aF1 = radians(aF1);


    while (n < IT) {


		p.x = abs(p.x);

		p.y = abs(p.y);

		p.z = abs(p.z);

		mat = Rot4Y  ( aF1 );
		p=mul(mat,p);

		p = p * SCALE - Offset * (SCALE-1);

		mat = Rot4X (aF0 );
		p=mul(mat,p);




		n++;
    }

	float res= (length(p)-2) * pow(SCALE, -n);
	return  res;
}


float cubeFold(float3 p)
{
	float SCALE = 2.1;
	float3 c;
	int n = 0;
	int IT = 10;
	float ic = 0;
	
	float3 Offset = float3(1,1,1);
    while (n < IT) {

		float4x4 mat = RotAA (float3 (0, 1,1), 2 * _Time.x);
		p=mul(mat,p);
		
		if (p.x<0){
		p.x = abs(p.x);
			 ic++;}
		if (p.y<0) 
		{
		p.y = abs(p.y); ic++;
		}
		if (p.z<0) {
		p.z = abs(p.z); ic++;
		}
	   p = p * SCALE - Offset * (SCALE-1);

       n++;
    }

	float res= (length(p)-2) * pow(SCALE, -n);
	return  res;
}


float octaFold(float3 p)
{
	float SCALE = 2.1;
	float3 oldP = p;
	float3 c;
	int n = 0;
	int IT = 10;

	float4x4 mat = RotAA(float3 (-1,1,-1),-2*_Time.x);
			p=mul(mat,p);

	float3 Offset = float3(1,1.5,1);
    while (n < IT) 
	{
		mat = RotAA(float3 (-1,1,-1),2*_Time.x);
		p=mul(mat,p);

		p = abs(p);

		if(p.x-p.y<0) p.xy = p.yx; // fold 1

		if(p.x-p.z<0) p.xz = p.zx; // fold 2

		if(p.y-p.z<0) p.zy = p.yz; // fold 3       
		p = p * SCALE - Offset * (SCALE-1);
		mat = RotAA(float3 (1,-1,1), 1*_Time.x);
		p=mul(mat,p);
		n++;
    }

	float res;
	res= (length(p)-2) * pow(SCALE, -n);
	
	return  res;
}

float2 octaFold2(float3 p )
{
	float SCALE = 3;
	float3 c;
	int n = 0;
	int IT = 8;
	float val = 0;

	float t = 0.1* _Time.y;
	float4x4 rot = RotAA(float3 (0,1,0), -t *PI/4);
	p = mul(rot , p);

	float3 Offset = float3(1,1,0.5);
    while (n < IT) 
	{
		
		float4x4 mat = RotAA(float3 (0,1,0), t* PI/4);

		p=mul(mat,p);

		if (p.x<0) { p.x = -p.x; val++;  }
		if (p.y<0) {p.y = -p.y;  val++;  }
		if (p.z<0) {p.z = -p.z ; val++;  }

		if(p.x-p.y<0){ p.xy = p.yx; val++;}
		if(p.x-p.z<0) {p.xz = p.zx; val++;}
		if(p.y-p.z<0) {p.zy = p.yz; val++;}    

		p.x = p.x * SCALE - Offset.x * (SCALE-1);
		p.y = p.y * SCALE - Offset.y * (SCALE-1);
		p.z = p.z * SCALE ;

		if(p.z>0.5*Offset.z*(SCALE-1)) p.z = p.z - Offset.z*(SCALE-1);

		mat = RotAA(float3 (1,0,0), PI/2);
		p=mul(mat,p);
		n++;
    }
	
	val = val /(6*IT);

	float res = (length(p)-2) * pow(SCALE, -n);
	
	return  float2(res, val);
}

float octaFold(float3 p, float algoFloat0, float algoFloat1, float algoFloat2, float algoFloat3)
{
	float SCALE = 2.1;
	float3 oldP = p;
	float3 c;
	int n = 0;
	int IT = 10;

	float4x4 mat = RotAA(float3 (-1,1,-1),-algoFloat0);
			p=mul(mat,p);

	float3 Offset = float3(1,1.5,1);
    while (n < IT) 
	{
		mat = RotAA(float3 (-1,1,-1), algoFloat0);
		p=mul(mat,p);

		p = abs(p);

		if(p.x-p.y<0) p.xy = p.yx; // fold 1

		if(p.x-p.z<0) p.xz = p.zx; // fold 2

		if(p.y-p.z<0) p.zy = p.yz; // fold 3       
		p = p * SCALE - Offset * (SCALE-1);
		mat = RotAA(float3 (1,-1,1), algoFloat1);
		p=mul(mat,p);
		n++;
    }

	float res;
	res= (length(p)-2) * pow(SCALE, -n);
	
	return  res;
}


float RoundBox(float3 p, float3 csize, float offset)
{
	float3 di = abs(p) - csize;
	float k=max(di.x,max(di.y,di.z));
	return abs(k*float(k<0.)+ length(max(di,0.0))-offset);
}

float Thingy(float3 p, float e){
	float3 Offset = float3 (0,0,0);
	p-=Offset;
	return (abs(length(p.xy)*p.z)-e) / sqrt(dot(p,p)+abs(e));
}

float Thing2(float3 p){
	int MI = 12;
	float3 CSize = float3 ( 0.92436,1.21212,1.0101);
//Just scale=1 Julia box
	float DEfactor=1;
	float3 ap = p+1;
	float4 orbitTrap = float4 (0,0,0,0);
	float Size = 1.14664;
	float3 C = float3 (0.28572,0.3238,-0.05716);
	float3 Offset = float3 ( 0.88888,0.4568,0.03704);
	float DEoffset = 0;
	if(!(ap.x==p.x && ap.y==p.y && ap.z==p.z))
	{
		for(int i=0 ; i<MI;i++)
		{
		ap=p;
		p=2.*clamp(p, -CSize, CSize)-p;
	
		float r2=dot(p,p);
		orbitTrap = min(orbitTrap, abs(float4(p,r2)));
		float k=max(Size/r2,1.);

		p*=k;DEfactor*=k;
	
		p+=C;
		orbitTrap = min(orbitTrap, abs(float4(p,dot(p,p))));
		}
	}
	//Call basic shape and scale its DE
	//return abs(0.5*Thingy(p,TThickness)/DEfactor-DEoffset);
	
	//Alternative shape
	//return abs(0.5*RoundBox(p, float3(1.,1.,1.), 1.0)/DEfactor-DEoffset);
	//Just a plane
	return abs(0.5*abs(p.z-Offset.z)/DEfactor-DEoffset);
}

float kaliBox(float3 pos) {

	float3 Trans =  float3 ( 0.0365,-1.8613,0.0365);
	float3 Julia = float3 (-0.6691,-1.3028,-0.45775);
	float scale =  2.04348;
	float4 orbitTrap = float4 (0,0,0,0);		
	float MinRad2 = 0.3492;
	int Iterations = 15;
	float absScalem1 = abs(scale - 1.0);

	float AbsScaleRaisedTo1mIters = pow(abs(scale), float(1-Iterations));
		
	float4 p = float4(pos,1), p0 = float4(Julia,1);  // p.w is the distance estimate
	
	for (int i=0; i<Iterations; i++) {

		p.xyz=abs(p.xyz)+Trans;
		float r2 = dot(p.xyz, p.xyz);
		if (i<2) orbitTrap = min(orbitTrap, abs(float4(p.xyz,r2)));
		p *= clamp(max(MinRad2/r2, MinRad2), 0.0, 1.0);  // dp3,div,max.sat,mul
		p = p*scale + p0;
	
	}
	return ((length(p.xyz) - absScalem1) / p.w - AbsScaleRaisedTo1mIters);
}

float mandelbulb(float3 p)
{
  float3 c = p;
  float r = length(c);
  float dr = 1;
  float xr =0;
  float theta = 0;
  float phi = 0 ;

  for (int i = 0; i < 4 && r < 3; i++)
  {
    xr = pow(r, 7);
    dr = 6 * xr * dr + 1;
    theta = atan2(c.y, c.x) * 8;
    phi = asin(clamp(c.z / r, -1,1)) * 8 - _Time.y;
    r = xr * r;
    c = r * float3(cos(phi) * cos(theta), cos(phi) * sin(theta), sin(phi));
   
    c += p;
    r = length(c);
  }

  return 0.35 * log(r) * r / dr;
}


float domainWarp(float3 p)
{


	float	res = perlin3(p);
	res = res + fbm3iq(8*p)/8;

	return res * 0.8;

}

