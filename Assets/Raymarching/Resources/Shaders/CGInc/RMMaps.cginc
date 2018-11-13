#include "RMPatterns.cginc"

// Maps used depending on the compile keyword in the Raymarching Shader.
// One map function correspond to a "scene", a combination of sdf from RMPatterns.
// Map takes as inputs : p (SDF evaluation position), cameraPos (or ray origin), and various floats and colors, free to use for animation and available 
// as public in the editor ( under "shapes" )
// Maps output a custom struct with : float2 distHit (sdf sample at position p, hit ID), float3 color (color calculated inside the map function for procedural shading)
// IDs correspond to materials ID available in the inspector (0,1,2). -1 is no hit. 
// Use opU(float2 distHit1, float2 distHit2) on a combination of float2 of type distHit to mix several materials in one scene.

struct MapResult{
		float2 distHit;
		float3 color;
};

MapResult map0 (float3 p, float3 cameraPos, float nearClip, float3 algoColor0, float3 algoColor1, float3 algoColor2, float3 algoColor3, float algoFloat0, float algoFloat1, float algoFloat2, float algoFloat3) 
{				
	MapResult mr;
	
	float objS = sdSphere(p-(cameraPos), nearClip);

	float3 p3 = opRep(p, float3(2,2,2));

	float res = udBox(p3, float3(2,2,2));

	float d = length (p-cameraPos);

	float l = 1-saturate((d-nearClip)/(4));

	l = smoothstep(0,1,l) ; 

	res = octaFold(p*0.08)/0.08	;
	res = opS(res, objS);
	mr.distHit = float2(res,0);

	mr.color = float3(0,0,1);
	return mr;

}

MapResult map1 (float3 p, float3 cameraPos, float nearClip, float3 algoColor0, float3 algoColor1, float3 algoColor2, float3 algoColor3, float algoFloat0, float algoFloat1, float algoFloat2, float algoFloat3) 
{				
	MapResult mr;
	float res;
	//-----------------
	p += float3(-253,464,-1025);
	float3 oldP;
	float3 index;

	oldP = p; 

	float objS = sdSphere(p-(cameraPos), nearClip);

	float l = 1- smoothstep(0,nearClip,length (oldP - cameraPos) ) ;
	l = 1+l;

	float v1 = perlin3Txt (0.005*p);
		
	float obj =apollonian1(0.01*p, algoFloat0)/0.01; 

	float3 color = lerp (algoColor0,algoColor1, v1);


	res = opS(obj, objS );
	//res = obj;
	//-----------------
	mr.distHit = float2(res,0);
	mr.color = color;
	return mr;

}

MapResult map2 (float3 p, float3 cameraPos, float nearClip, float3 algoColor0, float3 algoColor1, float3 algoColor2, float3 algoColor3, float algoFloat0, float algoFloat1, float algoFloat2, float algoFloat3) 
{				
	MapResult mr;
	float res;
	//-----------------

	float objS = sdSphere(p-(cameraPos), nearClip);

	float3 p3 = opRep(p, float3(2,2,2));

	res =udBox(p3, float3(2,2,2));

	float d = length (p-cameraPos);

	float l = 1-saturate((d-nearClip)/(2));
	l = smoothstep(0,1,l);


	float4 obj4 = cubeFold(p*0.08)/0.08;

	res = obj4.r;
	//	res = 	opS(res, objS);

	mr.distHit = res;

	mr.color = obj4.gba;
	return mr;
}


MapResult map3 (float3 p, float3 cameraPos, float nearClip, float3 algoColor0, float3 algoColor1, float3 algoColor2, float3 algoColor3, float algoFloat0, float algoFloat1, float algoFloat2, float algoFloat3) 
{				
	MapResult mr;
	float res;
	float3 color = float3 (0,0,0.);
	//-----------------
	float3 oldP = p;
	p.y -= _Time.y;
	float4x4 mat = Rot4Y  (oldP.y * algoFloat2 );

	p=mul(mat,p);

	float noise = fbm3(algoFloat0*p,6)-0.5;

	res = length ( p.xz) -5. + algoFloat1 * noise;
	res *=0.25;
	//-----------------
	mr.distHit = float2(res,0);
	mr.color = color;
	return mr;

}

MapResult map4 (float3 p, float3 cameraPos, float nearClip, float3 algoColor0, float3 algoColor1, float3 algoColor2, float3 algoColor3, float algoFloat0, float algoFloat1, float algoFloat2, float algoFloat3) 
{				
	MapResult mr;
	float res;
	//-----------------


	float3 oldP = p;
	float s = 20;


	float objS =  sdSphere(oldP-(cameraPos), nearClip);




	float d = length (p-cameraPos);

	float l = 1 - saturate((d-nearClip)/(2));

	l = smoothstep(0,1,l);
	

	float2 res2 = octaFold2(p*0.08);
	res = res2.x/0.08;
	float val = res2.y;

	res = 	opS(res, objS); 


	mr.distHit = float2(res,0);

	mr.color = lerp(algoColor0, algoColor1, val);
	
	return mr;
}



MapResult map5 (float3 p, float3 cameraPos, float nearClip, float3 algoColor0, float3 algoColor1, float3 algoColor2, float3 algoColor3, float algoFloat0, float algoFloat1, float algoFloat2, float algoFloat3) 
{				
	MapResult mr;
	float res;
	//-----------------

	float3 oldP = p;

	res = tetraFold(p*0.08,algoFloat0,algoFloat1, algoFloat2, algoFloat3)/0.08;


	//-----------------
	mr.distHit = float2(res,0);

	mr.color = float3(0,0,0);
	return mr;
}

MapResult map6 (float3 p, float3 cameraPos, float nearClip, float3 algoColor0, float3 algoColor1, float3 algoColor2, float3 algoColor3, float algoFloat0, float algoFloat1, float algoFloat2, float algoFloat3) 
{				
	MapResult mr;
	float l = length(p-cameraPos);
	l =1-saturate(l/ nearClip);
	float res ;
	res = (fbm3(0.05*p,7) -0.4)/(0.05);
	res*=0.6;

	float c = hash3Txt(0.005*p);

	mr.distHit = float2(res,0);

	mr.color = lerp(algoColor0,algoColor1,c);
	
	return mr;
}
MapResult map7 (float3 p, float3 cameraPos, float nearClip, float3 algoColor0, float3 algoColor1, float3 algoColor2, float3 algoColor3, float algoFloat0, float algoFloat1, float algoFloat2, float algoFloat3) 
{				
	MapResult mr;
	float res;
	//-----------------

	float objS = sdSphere(p - (cameraPos), nearClip);

	res = cubeFold(p*0.08, algoFloat0, algoFloat1, algoFloat2)/0.08;

	res = opS(res, objS);

		
	float2 resHit = float2(res, 0);
	//-----------------
	mr.distHit = resHit;
	mr.color = float3(0,0,0);
	return mr;
}

MapResult map8 (float3 p, float3 cameraPos, float nearClip, float3 algoColor0, float3 algoColor1, float3 algoColor2, float3 algoColor3, float algoFloat0, float algoFloat1, float algoFloat2, float algoFloat3) 
{				
	MapResult mr;
	float res;
	float3 color = float3(0,0,0);
	//-----------------

	res = mandelbulb(p*0.05)/0.05;

	//-----------------
	mr.distHit = float2(res,0);
	mr.color = color;
	return mr;
}
