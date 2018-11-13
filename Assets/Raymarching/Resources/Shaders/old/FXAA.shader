Shader "Hidden/FXAA" {
	Properties {
		_MainTex ("Texture", 2D) = "white" {}
	}

	CGINCLUDE
		#include "UnityCG.cginc"

		sampler2D _MainTex;
		sampler2D _LumTex;

		float _ContrastThreshold;
		float _RelativeThreshold;

		float4 _MainTex_TexelSize;
		float4 _LumTex_TexelSize;

		float _SubPixelBlending;

		struct VertexData {
			float4 vertex : POSITION;
			float2 uv : TEXCOORD0;
		};

		struct Interpolators {
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD0;
		};

		Interpolators VertexProgram (VertexData v) {
			Interpolators i;
			i.pos = UnityObjectToClipPos(v.vertex);
			i.uv = v.uv;
			return i;
		}
	ENDCG

	SubShader {
		Cull Off
		ZTest Always
		ZWrite Off

		Pass { // 0 luminance
			CGPROGRAM
				#pragma vertex VertexProgram
				#pragma fragment FragmentProgram

				float FragmentProgram (Interpolators i) : SV_Target {
					float4 sample = tex2D(_MainTex, i.uv);
					sample.rgb = saturate(sample.rgb);
					float a = LinearRgbToLuminance(sample.rgb);
					return a;//
				}

			ENDCG
		}


		Pass { // 1 fxaa
	CGPROGRAM
		#pragma vertex VertexProgram
		#pragma fragment FragmentProgram
		
		struct LumData
		{
			float m,n,s,e,w,h,l,c,nw,ne,sw,se;
		};


		float sampleLuminance (float2 uv) {
			return tex2D(_LumTex, uv).a;
		}

		LumData sampleLuminanceNeighborhood (float2 uv) {
			LumData ld;
			ld.m = sampleLuminance(uv);
			ld.n = sampleLuminance(uv + _MainTex_TexelSize * float2( 0,  1));
			ld.e = sampleLuminance(uv + _MainTex_TexelSize * float2( 1,  0));
			ld.s = sampleLuminance(uv + _MainTex_TexelSize * float2( 0, -1));
			ld.w = sampleLuminance(uv + _MainTex_TexelSize * float2( -1,  0));
			
			ld.nw = sampleLuminance(uv + _MainTex_TexelSize * float2( -1, 1));
			ld.ne = sampleLuminance(uv + _MainTex_TexelSize * float2( 1,  1));
			ld.se = sampleLuminance(uv + _MainTex_TexelSize * float2( -1, 1));
			ld.sw = sampleLuminance(uv + _MainTex_TexelSize * float2( -1,  -1));

			ld.h = max(ld.w,max(ld.s,(max( max (ld.m,ld.n),ld.e))));
				ld.l = min(ld.w,min(ld.s,(min( min (ld.m,ld.n),ld.e))));
			ld.c = 	ld.h-	ld.l;
			return ld;
		}

		bool shouldSkipPixel (LumData ld) {
			float threshold =
				max(_ContrastThreshold, _RelativeThreshold * ld.h);
			return ld.c < threshold;
		}

		float determinePixelBlendFactor (LumData ld) {
				float filter = 2 * (ld.n + ld.e + ld.s + ld.w);
				filter += ld.ne + ld.nw + ld.se + ld.sw;
				filter *= 1.0 / 12;

				filter = abs(filter - ld.m);
				filter = saturate(filter / ld.c);
				float blendFactor = smoothstep(0, 1, filter);
			return blendFactor*blendFactor * _SubPixelBlending	;
		}

		struct EdgeData {
			bool isHorizontal;
			float pixelStep;
			float oppositeLuminance, gradient;
		};

		EdgeData determineEdge (LumData ld) {
			EdgeData e;//
			float horizontal =
				abs(ld.n + ld.s - 2 * ld.m) * 2 +
				abs(ld.ne + ld.se - 2 * ld.e) +
				abs(ld.nw + ld.sw - 2 * ld.w);
			float vertical =
				abs(ld.e + ld.w - 2 * ld.m) * 2 +
				abs(ld.ne + ld.nw - 2 * ld.n) +
				abs(ld.se + ld.sw - 2 * ld.s);
			e.isHorizontal = horizontal >= vertical;

			float pLuminance = e.isHorizontal ? ld.n : ld.e;
			float nLuminance = e.isHorizontal ? ld.s : ld.w;

			float pGradient = abs(pLuminance - ld.m);
			float nGradient = abs(nLuminance - ld.m);

			e.pixelStep =
				e.isHorizontal ? _MainTex_TexelSize.y : _MainTex_TexelSize.x;

			if (pGradient < nGradient) 
			{
				e.pixelStep = -e.pixelStep;
				e.oppositeLuminance = nLuminance;
				e.gradient = nGradient;
			}
			else {
				e.oppositeLuminance = pLuminance;
				e.gradient = pGradient;
			}


			return e;
		}

			#define EDGE_STEP_COUNT 12
			#define EDGE_STEPS 1, 1 ,1,1,1,1.5,2,2,2,2,4,8
			#define EDGE_GUESS 8

		

		static const float edgeSteps[EDGE_STEP_COUNT] = { EDGE_STEPS };

		float determineEdgeBlendFactor (LumData ld, EdgeData ed, float2 uv) 
		{
			float2 uvEdge = uv;
			float2 edgeStep;
			if (ed.isHorizontal) {
				uvEdge.y += ed.pixelStep * 0.5;
				edgeStep = float2(_MainTex_TexelSize.x, 0);
			}
			else {
				uvEdge.x += ed.pixelStep * 0.5;
				edgeStep = float2(0, _MainTex_TexelSize.y);
			}

			float edgeLuminance = (ld.m + ed.oppositeLuminance) * 0.5;
			float gradientThreshold = ed.gradient * 0.25;
			
			float2 puv = uvEdge + edgeStep* edgeSteps[0];
			float pLuminanceDelta = sampleLuminance(puv) - edgeLuminance;
			bool pAtEnd = abs(pLuminanceDelta) >= gradientThreshold;
			
			UNITY_UNROLL
			for (int i = 1; i < EDGE_STEP_COUNT && !pAtEnd; i++) {
				puv += edgeStep * edgeSteps[i];
				pLuminanceDelta = sampleLuminance(puv) - edgeLuminance;
				pAtEnd = abs(pLuminanceDelta) >= gradientThreshold;
			}
			if (!pAtEnd) {
				puv += edgeStep * EDGE_GUESS;
			}
			
			float2 nuv = uvEdge - edgeStep * edgeSteps[0];
			float nLuminanceDelta = sampleLuminance(nuv) - edgeLuminance;
			bool nAtEnd = abs(nLuminanceDelta) >= gradientThreshold;
			
			UNITY_UNROLL
			for (int i = 1; i <EDGE_STEP_COUNT && !nAtEnd; i++) {
				nuv -= edgeStep * edgeSteps[i];
				nLuminanceDelta = sampleLuminance(nuv) - edgeLuminance;
				nAtEnd = abs(nLuminanceDelta) >= gradientThreshold;
			}
			if (!pAtEnd) {
				nuv -= edgeStep * EDGE_GUESS;
			}

			float pDistance, nDistance;
			if (ed.isHorizontal) {
				pDistance = puv.x - uv.x;
				nDistance = uv.x - nuv.x;
			}
			else {
				pDistance = puv.y - uv.y;
				nDistance = uv.y - nuv.y;
			}
			
			float shortestDistance;
				bool deltaSign;
			if (pDistance <= nDistance) {
				shortestDistance = pDistance;
				deltaSign = pLuminanceDelta >= 0;
			}
			else {
				shortestDistance = nDistance;
				deltaSign = nLuminanceDelta >= 0;
			}

			if (deltaSign == (ld.m - edgeLuminance >= 0)) {
				return 0;
			}

			return 0.5 - shortestDistance / (pDistance + nDistance);

		}

		float4 ApplyFXAA (float2 uv)
		{	
			LumData ld = sampleLuminanceNeighborhood(uv);
			if(shouldSkipPixel(ld))
			{
				return tex2Dlod(_MainTex, float4(uv, 0, 0));
			}
			float pixelBlend = determinePixelBlendFactor(ld);
			EdgeData ed = determineEdge(ld);
			float edgeBlend = determineEdgeBlendFactor(ld, ed, uv);
			float finalBlend = max(pixelBlend, edgeBlend);
	
			

			if (ed.isHorizontal) {
				uv.y += ed.pixelStep * finalBlend ;
			}
			else {
				uv.x += ed.pixelStep * finalBlend;
			}

			return tex2Dlod(_MainTex, float4(uv, 0, 0));

		}


		float4 FragmentProgram (Interpolators i) : SV_Target0 {
			
			return ApplyFXAA( i.uv);
		}


	ENDCG
	}



	}
}