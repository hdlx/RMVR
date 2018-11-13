Shader "Custom/GenerateCubemap"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}
			

			uniform sampler2D _MainTex;
			uniform  float _Frequency;
			uniform  int _Face;
			
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
						
			float3 hash33( float3 input ) {
			input = float3(dot(float3(151.5,22.7,45.9),input), dot(float3(551.75,12.7,55.1),input),dot(float3(155,172.7,485.9),input));
    		return float3(hash(input.x),hash(input.y),hash(input.z));
			}

			float calcCornerValue(float3 corner, float3 p) 
			{
				//return hash31(corner);

				float3 gradV = normalize(hash33(floor(p) + corner)-0.5)*sqrt(3);
				float3 dirV  = (frac(p) - corner);
			
				return dot(gradV,dirV) ;
			}

			float myNoise(float3 input)
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




			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = float4(1,1,1,1);
				float2 uv = 1-i.uv-0.5;
				
				float3 pos3d; 

				if(_Face==0) pos3d = float3 (-0.5, uv.y, uv.x) ;     //+x
				else if(_Face==1) pos3d =  float3 (0.5, uv.y, -uv.x);  //-x
				else if(_Face==2) pos3d =  float3 (uv.x, 0.5, -uv.y) ; //+y
				else if(_Face==3) pos3d = float3 (uv.x, -0.5, uv.y) ; //-y
				else if(_Face==4) pos3d =  float3 (uv.x, uv.y,0.5) ; //+z
				else pos3d = float3 (-uv.x, uv.y, -0.5);  //-z				
				pos3d = normalize(pos3d);

				float noi = myNoise(_Frequency*pos3d)*0.5 + 0.5 ;//myNoise(10*pos3d) ;
			
	
				/*if(_Face==0) col.rgb =noise *float3(1,1,0);     //+x
				else if(_Face==1) col.rgb = noise *float3(0,1,0);  //-x
				else if(_Face==2) col.rgb = noise *float3(0,1,1); //+y
				else if(_Face==3) col.rgb = noise* float3 (1,0,1); //-y
				else if(_Face==4) col.rgb = noise * float3(0,0,1); //+z
				else pos3d =noise * float3(1,1,1);  //-z		
				*/

				col.rgb = noi;
				//if (noi.x >0.95) col.rgb = float3(1,0,0);
				//if (noi.x <-0.95 ) col.rgb = float3(0,0,1);


				return col;
			}
			ENDCG
		}
	}
}
