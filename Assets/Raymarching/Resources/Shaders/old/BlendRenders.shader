
Shader "Hidden/BlendRenders"
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
			//#define UNITY_SINGLE_PASS_STEREO

			#include "UnityCG.cginc"


			uniform sampler2D _MainTex;
			half4 _MainTex_ST;
			float4 _MainTex_TexelSize;
			uniform sampler2D _RMTex;
			float4 _RMTex_TexelSize;
			uniform sampler2D _NormalLumTex;
			uniform sampler2D _DepthTex;
			uniform sampler2D _DepthTexHigh;
			uniform float _UseFXAA;

			float _ContrastThreshold;
			float _RelativeThreshold;


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
		


			fixed4 frag (v2f i) : SV_Target
			{	
	
				
				fixed4 col = tex2D(_MainTex, UnityStereoScreenSpaceUVAdjust(i.uv, _MainTex_ST));
				fixed4 rm;
				rm = tex2D(_RMTex, UnityStereoScreenSpaceUVAdjust(i.uv, _MainTex_ST));
				col.rgb =col.rgb * (1-rm.a)+rm.rgb*rm.a;
				

				return col;
			}
			ENDCG//
		}
	}
}
