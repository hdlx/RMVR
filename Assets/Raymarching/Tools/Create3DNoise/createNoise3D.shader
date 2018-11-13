Shader "Hidden/createNoise3D"
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
			uniform float _z;
			uniform float _res;
			uniform float _scale;

			float hash(float n)
			{
				return frac(sin(n)*43758.5453);
			}

			float3 hash13(float n) {
			 return frac(sin(n + float3(0.,12.345,124))*43758.5453);
			}
			float hash31(float3 n) {
			return hash(n.x + 10.*n.y + 100.*n.z);
			}

			float3 hash33(float3 input) {
			input = float3(dot(float3(151.5,22.7,45.9),input), dot(float3(551.75,12.7,55.1),input),dot(float3(155,172.7,485.9),input));
			return float3(hash(input.x),hash(input.y),hash(input.z));
			}

			float3 mod(float3 v1, float3 v2)
			{
				float3 output;
				output.x = v1.x - v2.x * floor(v1.x / v2.x);
				output.y = v1.y - v2.y * floor(v1.y / v2.y);
				output.z = v1.z - v2.z * floor(v1.z / v2.z);
				return output;
			}

			float calcCornerValue(float3 corner, float3 p)
			{
		
				float3 samp = floor(p) + corner;
				samp = fmod(samp, float3(_scale, _scale,_scale));
				float3 gradV = normalize(hash33(samp) - 0.5)*sqrt(3);
				float3 dirV = (frac(p) - corner);

				return dot(gradV,dirV);
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

				float v = lerp( h1, h4, fra.x);
				float fb = lerp(v,lerp(h2,h3, fra.x),fra.z);

				v = lerp(h5,h8, fra.x);

				float fh = lerp(v,lerp(h6,h7, fra.x),fra.z);

				v = lerp(fb,fh,fra.y);
				return v;
			
			}

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
			
			sampler2D _MainTex;

			fixed4 frag (v2f i) : SV_Target
			{

				fixed4 col;
				float z = _z / _res;

				float v = myNoise(float3(i.uv.x, i.uv.y, z) * _scale);

				v = (v + 1)*0.5;
				col.rgb = float3 (v, v, v);
				col.a = 1;
			

				
				return col;
			}
			ENDCG
		}
	}
}
