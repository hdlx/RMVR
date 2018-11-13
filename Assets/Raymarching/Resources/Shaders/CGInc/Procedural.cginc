//Various noise function...
//hashes and "iq" ones come from https://www.iquilezles.org/
//The "my" ones are not meant to be used every frame, but rather to compute
//the dither-cubemap and the perlin tiling texture.
uniform sampler3D _Hash3DTxt;
uniform sampler3D _Perlin3DTxt;

float hash( float n )
{
	return frac(sin(n)*43758.5453);
}

float3 hash13( float n ) {
    return frac(sin(n+float3(0.,12.345,124))*43758.5453);
}

float hash31( float3 n ) {
    return hash(n.x+10.*n.y+100.*n.z);
}

float hash21( float2 n ) {
    return hash(-222*n.x+10000.*n.y);
}

float3 hash33( float3 input ) {
input = float3(dot(float3(151.5,22.7,45.9),input), dot(float3(551.75,12.7,55.1),input),dot(float3(155,172.7,485.9),input));
return float3(hash(input.x),hash(input.y),hash(input.z));
}

float4 hash44( float4 input ) {
input = float4(dot(float4(151.5,22.7,45.9,17.5),input), dot(float4(551.75,12.7,55.1,21.9),input),dot(float4(155,172.7,485.9,33.7),input),dot(float4(155,172.7,485.9,33.7),input)  );

return float4(hash(input.x),hash(input.y),hash(input.z),hash(input.w) );
}

float perlin2( float2 p){
	 float2 ip = floor(p);
	 float2 u = frac(p);
	u = u*u*(3.0-2.0*u);
	
	float res = lerp(
		lerp(hash(ip),hash(ip+ float2(1.0,0.0)),u.x),
		lerp(hash(ip+ float2(0.0,1.0)),hash(ip+ float2(1.0,1.0)),u.x),u.y);
	return res*res;
}

float perlin3(float3 x)
{
	
	float3 p = floor(x);//
	float3 f = frac(x);

	f = f*f*(3.0-2.0*f);
	float n = p.x + p.y*57.0 + 113.0*p.z;


	return lerp(lerp(lerp( hash(n+0.0), hash(n+1.0),f.x),
					lerp( hash(n+57.0), hash(n+58.0),f.x),f.y),
				lerp(lerp( hash(n+113.0), hash(n+114.0),f.x),
					lerp( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
}

float hash3Txt(float3 p)
{
// use IQ's better filtering technique.
// to use hash as pseudo-perlin noise
	p = p * 32.0;

	p += 0.5;

	float3 i = floor(p);
	float3 f = frac(p);
	f = smoothstep(0., 1., f);
	p = f + i;

	p -= 0.5;

	p = p / 32.;

	float t = tex3Dlod(_Hash3DTxt, float4(p, 0)).r;


	return (t);
}

float perlin3Txt(float3 p)
{
	p/=10; // DIVIDE BY SCALE OF NOISE.
	float t = tex3Dlod(_Perlin3DTxt, float4(p, 0)).r;
	return (t);
}

float calcCornerValue(float3 corner, float3 p)  // for MY NOISE 3
{
	float3 gradV = normalize(hash33(floor(p) + corner)-0.5)*sqrt(3);
	float3 dirV  = (frac(p) - corner);

	return dot(gradV,dirV) ;
}

float calcCornerValue(float4 corner, float4 p)  // for my noise 4 
{
	float4 gradV = normalize(hash44(floor(p) + corner)-0.5)*sqrt(4);
	float4 dirV  = (frac(p) - corner);

	return dot(gradV,dirV) ;
}

float myPerlin3(float3 input) // RANGE -1  +1 
{
	float h1 = calcCornerValue(float3(0,0,0),input);
	float h2 = calcCornerValue(float3(0,0,1),input);
	float h3 = calcCornerValue(float3(1,0,1),input);
	float h4 = calcCornerValue(float3(1,0,0),input);
	float h5 = calcCornerValue(float3(0,1,0),input);
	float h6 = calcCornerValue(float3(0,1,1),input);
	float h7 = calcCornerValue(float3(1,1,1),input);
	float h8 = calcCornerValue(float3(1,1,0),input);

	float3 fra = frac(input);	

	fra = 6 * pow(fra,5) - 15 * pow(fra,4) + 10 * pow(fra,3);
	fra = saturate(fra);

	float v = lerp(h1,h4, fra.x);
	float fb = lerp (v,lerp(h2,h3, fra.x),fra.z);

	v = lerp(h5,h8, fra.x);
	float fh = lerp (v,lerp(h6,h7, fra.x),fra.z);

	v= lerp (fb,fh,fra.y);
	return v;
}

float myPerlin4(float4 input) //RANGE -1 +1
{
	float4 fra = frac(input);
	fra = 6 * pow(fra,5) - 15 * pow(fra,4) + 10 * pow(fra,3);


	//cube1
	float c1 = calcCornerValue(float4(0,0,0,0),input);
	float c2 = calcCornerValue(float4(0,0,1,0),input);
	float c3 = calcCornerValue(float4(1,0,1,0),input);
	float c4 = calcCornerValue(float4(1,0,0,0),input);
	float c5 = calcCornerValue(float4(0,1,0,0),input);
	float c6 = calcCornerValue(float4(0,1,1,0),input);
	float c7 = calcCornerValue(float4(1,1,1,0),input);
	float c8 = calcCornerValue(float4(1,1,0,0),input);

	float v = lerp(c1,c4, fra.x);
	float fb = lerp (v,lerp(c2,c3, fra.x),fra.z);

	v = lerp(c5,c8, fra.x);
	float fh = lerp (v,lerp(c6,c7, fra.x),fra.z);

	float cube1 = lerp (fb,fh,fra.y);


	//cube2
	c1 = calcCornerValue(float4(0,0,0,1),input);
	c2 = calcCornerValue(float4(0,0,1,1),input);
	c3 = calcCornerValue(float4(1,0,1,1),input);
	c4 = calcCornerValue(float4(1,0,0,1),input);
	c5 = calcCornerValue(float4(0,1,0,1),input);
	c6 = calcCornerValue(float4(0,1,1,1),input);
	c7 = calcCornerValue(float4(1,1,1,1),input);
	c8 = calcCornerValue(float4(1,1,0,1),input);



	v = lerp(c1,c4, fra.x);
	fb = lerp (v,lerp(c2,c3, fra.x),fra.z);

	v = lerp(c5,c8, fra.x);
	fh = lerp (v,lerp(c6,c7, fra.x),fra.z);

	float cube2 = lerp (fb,fh,fra.y);


	v = lerp (cube1,cube2, fra.w);
	return v;

}


float myFbm4(float4 input, int octaves)
{
	float res = 0;
	for (int i = 1; i<octaves; i++)
	{
		res = res + myPerlin4 (input*i)/i;
		i = 2*i;
	}
	return res;


}

float myFbm3 (float3 input, int octaves)
{
	float value = 0;
	float frequency = 0;
	int v = 2;

		for (int i = 0; i <octaves; i++)
		{
			v = pow(2,i);
			value += myPerlin3 (input*v)/v;
		}
	return value;
}

float fbm3iq (float3 input)
{
	float f;
	const float3x3 m = float3x3( 0.00,  0.80,  0.60,
           		    -0.80,  0.36, -0.48,
             		-0.60, -0.48,  0.64 );
	float3 p = input;
	f = 0.5000*hash3Txt( p/32 ); 
	p = mul(m,p)*2.02;
	f += 0.2500*hash3Txt( p /32);
	p = mul(m,p)*2.03;
	f += 0.1250*hash3Txt( p /32);
	p = mul(m,p)*2.01;
	f += 0.0625*hash3Txt( p/32 );

	return f;
}


float fbm3 (float3 input, int octaves)
{
	float value = 0;
	float amplitude= 0.5;
	float frequency = 0;

		for (int i = 0; i < octaves; i++)
		{
			value += amplitude * (perlin3Txt(input) )  ;
			input *= 2;
			amplitude *= 0.5;
		}

	return value;
}

float fbm2 (float2 input, int octaves)
{
	float value = 0;
	float amplitude= 0.5;
	float frequency = 0;

		for (int i = 0; i <octaves; i++)
		{
			value += amplitude * perlin2 (input);
			input *= 2;
			amplitude *= 0.5;
		}
	return value;
}


float4 worley( float3 p ) {
	float e = pow(10,10);
    float4 d = float4(e,e,e,e);
    float3 ip = floor(p);
    for (float i=-1.; i<2.; i++)
   	 	for (float j=-1.; j<2.; j++)
            for (float k=-1.; k<2.; k++) {
                float3 p0 = ip+float3(i,j,k),
                      c = hash33(p0)+p0-p;
                float d0 = dot(c,c);
                if      (d0<d.x) { d.yzw=d.xyz; d.x=d0; }
                else if (d0<d.y) { d.zw =d.yz ; d.y=d0; }
                else if (d0<d.z) { d.w  =d.z  ; d.z=d0; }
                else if (d0<d.w) {              d.w=d0; }   
            }
    return sqrt(d);
}