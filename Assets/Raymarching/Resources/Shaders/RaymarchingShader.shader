//MIT License
//
//Copyright (c) 2018 http://hubpaul.com
//Originally developped at and for http://www.small-studio.io/
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

Shader "Raymarching/RayMarchingShader"
{
	Properties
	{
		_MainTex("Source", 2D) = "white" {}
	}
	
	SubShader
	{
		Cull Off ZWrite Off ZTest Always

		CGINCLUDE

		#pragma multi_compile MAP0 MAP1 MAP2 MAP3 MAP4 MAP5 MAP6 MAP7 MAP8
		#include "UnityCG.cginc"
		#include "CGINC/RMMaps.cginc"
		#include "CGINC/BlendModes.cginc"

		struct appdata
		{
			float4 vertex : POSITION;
			float2 uv : TEXCOORD0;
		};

		struct v2f
		{
			float2 uv : TEXCOORD0;
			float4 vertex : SV_POSITION;
			float3 rd : TEXCOORD1;
			float3 rdCameraSpace : TEXCOORD2;

		};

		#pragma vertex vert
		#pragma fragment frag
		#pragma target 3.0

		uniform float4x4 _FrustumCornersLeft;
		uniform float4x4 _FrustumCornersRight;
		uniform float4x4 _CamToWorldLeft;
		uniform float4x4 _CamToWorldRight;
		uniform float4x4 _InverseProjectionMatrixLeft;
		uniform float4x4 _InverseProjectionMatrixRight;
		uniform float4x4 _InverseProjectionMatrixMiddle;
		uniform float4x4 _ProjectionMatrixMiddle;

		uniform float4x4 _CamToWorldMiddle;
		uniform float _StereoSep;

		uniform float3 _CameraWS;
		uniform float3 _CameraForward;

		uniform samplerCUBE _NoiseCubemap;

		uniform int _MaxSteps;
		uniform float _MinDist;
		uniform float _MaxDist;
		uniform float _Dithering;
		uniform float _OverRelaxation;
		uniform int _HeatMap;

		#define _ReprojectionSteps 5
		uniform float _ReprojectionSpeed;

		uniform float _LightPow;
		uniform int _UsePointLight;
		uniform float3 _PointLightPosition;

		uniform int _DoShadow;
		uniform float _ShadowMaxDist;
		uniform int _ShadowMaxSteps;
		uniform float _ShadowtMin;
		uniform float _ShadowSmooth;
		uniform float _ShadowStr;
		uniform float3 _ShadowColor;

		uniform float _FogStrength;
		uniform float _Alpha;
		uniform float3 _FogColor;
		uniform int _ZTest;
		uniform float _ZTestSmooth;

		#define NMat 3

		uniform sampler2D _DiffuseMap0;
		uniform sampler2D _DiffuseMap1;
		uniform sampler2D _DiffuseMap2;

		#define AA 2
		uniform float _ComputeNormals[NMat];
		uniform int _UseDiffuseTexture[NMat];
		uniform float3 _DiffuseColor[NMat];
		uniform float _UseAlgoColorDiffuse[NMat];
		uniform float _KD[NMat];
		uniform float _Emission[NMat];
		uniform float3 _SpecColor[NMat];
		uniform float _KS[NMat];
		uniform float _Roughness[NMat];
		uniform float3 _FresnelColor[NMat];
		uniform float _KF[NMat];
		uniform float _FPow[NMat];
		uniform samplerCUBE _Cubemap;
		uniform float _KRef[NMat];

		uniform float _DoAoSSS[NMat];
		uniform int _AoSSSMode[NMat];

		uniform float _AoSSSCoef[NMat];
		uniform float _AoSSSRemap[NMat];
		uniform float _AoSSSSteps[NMat];
		uniform float _AoSSSDelta[NMat];
		uniform float3 _AoSSSColor[NMat];

		uniform float _DoGlow[NMat];
		uniform float3 _GlowColor[NMat];
		uniform float _UseAlgoColorGlow[NMat];
		uniform float _GlowCoef[NMat];
		uniform float _GlowRemap[NMat];
		uniform float _DistGlowNear; // 
		uniform float _DistGlowFar;  //	GLOW DISTANCE NOT MATERIAL SPECIFIC  !
		uniform float _DistGlowStr;  //

		uniform float3 _AlgoColor[4];
		uniform float _AlgoFloat[4];

		uniform float _NearClip;
		uniform int _MapIndex;

		struct Hit {
			float3 position;
			float3 normal;
			float iterations;
			int id;
			float3 algoColor;
			float mapDist;
			float travelDist;
		};


		MapResult map(float3 p)
		{
			MapResult res;

			#if defined(MAP1)
			res = map1(p, _CameraWS, _NearClip, _AlgoColor[0],_AlgoColor[1],_AlgoColor[2],_AlgoColor[3], _AlgoFloat[0], _AlgoFloat[1], _AlgoFloat[2], _AlgoFloat[3]);
			#elif defined(MAP2)
			res = map2(p, _CameraWS, _NearClip, _AlgoColor[0],_AlgoColor[1],_AlgoColor[2],_AlgoColor[3], _AlgoFloat[0], _AlgoFloat[1], _AlgoFloat[2], _AlgoFloat[3]);
			#elif defined(MAP3)
			res = map3(p, _CameraWS, _NearClip, _AlgoColor[0],_AlgoColor[1],_AlgoColor[2],_AlgoColor[3], _AlgoFloat[0], _AlgoFloat[1], _AlgoFloat[2], _AlgoFloat[3]);
			#elif defined(MAP4)
			res = map4(p, _CameraWS, _NearClip, _AlgoColor[0],_AlgoColor[1],_AlgoColor[2],_AlgoColor[3], _AlgoFloat[0], _AlgoFloat[1], _AlgoFloat[2], _AlgoFloat[3]);
			#elif defined(MAP4)
			res = map4(p, _CameraWS, _NearClip, _AlgoColor[0],_AlgoColor[1],_AlgoColor[2],_AlgoColor[3], _AlgoFloat[0], _AlgoFloat[1], _AlgoFloat[2], _AlgoFloat[3]);
			#elif defined(MAP5)
			res = map5(p, _CameraWS, _NearClip, _AlgoColor[0],_AlgoColor[1],_AlgoColor[2],_AlgoColor[3], _AlgoFloat[0], _AlgoFloat[1], _AlgoFloat[2], _AlgoFloat[3]);
			#elif defined(MAP6)
			res = map6(p, _CameraWS, _NearClip, _AlgoColor[0],_AlgoColor[1],_AlgoColor[2],_AlgoColor[3], _AlgoFloat[0], _AlgoFloat[1], _AlgoFloat[2], _AlgoFloat[3]);
			#elif defined(MAP7)
			res = map7(p, _CameraWS, _NearClip, _AlgoColor[0],_AlgoColor[1],_AlgoColor[2],_AlgoColor[3], _AlgoFloat[0], _AlgoFloat[1], _AlgoFloat[2], _AlgoFloat[3]);
			#elif defined(MAP8)
			res = map8(p, _CameraWS, _NearClip, _AlgoColor[0],_AlgoColor[1],_AlgoColor[2],_AlgoColor[3], _AlgoFloat[0], _AlgoFloat[1], _AlgoFloat[2], _AlgoFloat[3]);
			#else
			res = map0(p, _CameraWS, _NearClip, _AlgoColor[0],_AlgoColor[1],_AlgoColor[2],_AlgoColor[3], _AlgoFloat[0], _AlgoFloat[1], _AlgoFloat[2], _AlgoFloat[3]);
			#endif

			return res;
		}

		Hit writeNormals(Hit hit)
		{
			float3 pos = hit.position;
			float d = hit.mapDist;

			const float2 eps = float2(0.05, 0.0);

			float d1 = map(pos + eps.xyy).distHit.x, d2 = map(pos - eps.xyy).distHit.x; //replace d2 d4 d6 by d for a little optimisation
			float d3 = map(pos + eps.yxy).distHit.x, d4 = map(pos - eps.yxy).distHit.x;
			float d5 = map(pos + eps.yyx).distHit.x, d6 = map(pos - eps.yyx).distHit.x;

			float3 nor = float3 (d1 - d2, d3 - d4, d5 - d6);

			hit.normal = normalize(nor);

			return hit;
		}


		Hit rayMarch(float3 ro, float3 rd, float noise)
		{
			Hit hit;
			hit.position = ro;
			hit.id = -1; // RETURN -1 IF NO HIT
			hit.travelDist = _MaxDist;
			hit.normal = float3(0,0,0);
			hit.mapDist = 100;

			Hit closestHit = hit;
			closestHit.mapDist = 1000;

			float t = _Dithering * noise; //total ray travel distance. Initialized at some distance from origin for dithering

			MapResult mr;

			for (int i = 0; i < _MaxSteps; i++)
			{
				hit.position = ro + rd * t;
				mr = map(hit.position);
				float radius = mr.distHit.x;

				hit.id = mr.distHit.y;
				hit.travelDist = t;
				hit.algoColor = mr.color;
				hit.mapDist = radius;
				hit.iterations = i;
					
				if (hit.mapDist < closestHit.mapDist) closestHit = hit;

				// hit !!! or out of bounds. Remove clamp(t, 1, 10000) for constant hit treshold.
				if (radius < _MinDist * clamp(t, 1, 100000) || t > _MaxDist) 
				{
					break;
				}

				hit = closestHit;

				t += radius;
			}

			if (t > _MaxDist) hit.id = -1;

			return hit;
		}


		float4 doTexture(float3 position, float3 normal, int id)
		{
			float2 xUV = position.yz;
			float2 yUV = position.xz;
			float2 zUV = position.xy;

			half3 xDiff;
			half3 yDiff;
			half3 zDiff;

			if (id == 2)
			{
				xDiff = tex2Dlod(_DiffuseMap2, float4(xUV, 0,0));
				yDiff = tex2Dlod(_DiffuseMap2, float4(yUV, 0,0));
				zDiff = tex2Dlod(_DiffuseMap2, float4(zUV, 0,0));
			}
			else if (id == 1)
			{
				xDiff = tex2Dlod(_DiffuseMap1, float4(xUV, 0,0));
				yDiff = tex2Dlod(_DiffuseMap1, float4(yUV, 0,0));
				zDiff = tex2Dlod(_DiffuseMap1, float4(zUV, 0,0));
			}
			else
			{
				xDiff = tex2Dlod(_DiffuseMap0, float4(xUV, 0,0));
				yDiff = tex2Dlod(_DiffuseMap0, float4(yUV, 0,0));
				zDiff = tex2Dlod(_DiffuseMap0, float4(zUV, 0,0));
			}

			normal = abs(normal);

			float3 sum = xDiff * normal.x + yDiff * normal.y + zDiff * normal.z;
			float4 diff = float4(sum,1);

			return diff;
		}

		float doAoSSS(float3 p, float3 n, int steps, float delta)
		{
				float a = 0.0;
				float weight = .5;
				for (int i = 1; i <= steps; i++) {
					float d = (float(i) / float(steps)) * delta;
					a = a + weight * (d - map(p + n * d).distHit.x);
					weight = weight * 0.6;
				}
				return clamp(1.0 - a, 0.0, 1.0);
		}

		float doShadow(float3 ro, float3 rd)
		{
			float h = 0;
			float k = _ShadowSmooth;
			float res = 1;
			float t = _ShadowtMin;
			for (int i = 0; t < _ShadowMaxDist; i++)
			{
				h = map(ro - rd * t).distHit.x;

				res = saturate(min(res, k*h / t));

				if (h < 10 * _MinDist)
				{
					return 0;
				}
				t = t + h;
			}
			return res;
		}


		float estimateCosTheTa(float3 pos, float3 lightDir, float eps)
		{
			eps *= 2.25;
			float d = map(pos + lightDir * eps).distHit.x / eps;
			return d;// gain (d, 0.2);
		}


		float4 shade(Hit hit, float3 rayDirection, float3 rayOrigin)
		{
			//HEATMAP FOR DEBUG
			if (_HeatMap == 1)
			{
				float val = hit.iterations / _MaxSteps;
				return float4(val,0,1 - val,1);
			}

			//NO HIT
			if (hit.id == -1)
			{
				return float4(0,0,0,0);
			}

			//SET VARIABLES FROM HIT ID
			float3 diffuseColor;
			if (_UseAlgoColorDiffuse[hit.id] == 1) diffuseColor = hit.algoColor;
			else diffuseColor = _DiffuseColor[hit.id];
			if (_UseDiffuseTexture[hit.id] == 1) diffuseColor = doTexture(hit.position,hit.normal, hit.id) * diffuseColor;
			float kD = _KD[hit.id];

			float emission = _Emission[hit.id];

			float kS = _KS[hit.id];
			float roughness = _Roughness[hit.id];
			if (roughness == 0) roughness = 0.00000001;
			float3 specColor = _SpecColor[hit.id];

			float KRef = _KRef[hit.id];

			float3 fresnelColor = _FresnelColor[hit.id];
			float kF = _KF[hit.id];
			float fPow = _FPow[hit.id];

			float3 aoSSSColor = _AoSSSColor[hit.id];

			//LIGHT
			float3 lightDir;
			float3 lightDist = 1;
			if (_UsePointLight == 1)
			{
				lightDir = hit.position - _PointLightPosition;
				lightDist = length(lightDir);
				lightDir = lightDir / lightDist;
			}
			else
			{
				lightDir = -_WorldSpaceLightPos0.xyz; //Scene Directionnal
				lightDist = 1;
			}

			//DIFFUSE
			float ndl = saturate(dot(hit.normal,-lightDir));
			float3 diffuse = diffuseColor * ((kD * ndl * (_LightPow / (lightDist*lightDist))) + emission);

			//SPECULAR		
			float3 H = -normalize(lightDir + rayDirection);
			float energyConservation = (8.0 + roughness) / (8.0 * 3.14);
			float3 spec = specColor * pow(saturate(dot(hit.normal,H)),roughness) * (_LightPow / (lightDist*lightDist))   * energyConservation;

			//CUBEMAP REFLECTION
			float3 refRd = reflect(rayDirection, hit.normal);
			half4 skyData = texCUBElod(_Cubemap, float4(refRd,0));
			half3 skyColor = skyData.rgb;

			//FRESNEL
			float fresnel = pow(1 - abs(dot(rayDirection, hit.normal)),fPow);

			//SHADOW
			float shadow = 1;
			if (_DoShadow)
			{
				shadow = doShadow(hit.position, lightDir);
				shadow = saturate(shadow + (1 - _ShadowStr));
			}

			//AO - SSS 
			float aoSSS = 1;
			if (_DoAoSSS[hit.id])
			{
				float3 vecInput;
				if (_AoSSSMode[hit.id] == 0 || _AoSSSMode[hit.id] == 1) //iteration based mode
				{
					vecInput = lerp(hit.normal, rayDirection,_AoSSSMode[hit.id]);
					aoSSS = doAoSSS(hit.position,vecInput,_AoSSSSteps[hit.id], _AoSSSDelta[hit.id]);
				}
				else //cosine estimation mode
				{
					vecInput = lerp(hit.normal, rayDirection,_AoSSSMode[hit.id] - 2);
					aoSSS = estimateCosTheTa(hit.position, vecInput, _AoSSSDelta[hit.id]);
				}
				aoSSS = saturate(aoSSS * _AoSSSCoef[hit.id] + _AoSSSRemap[hit.id]);

			}

			//GLOW (USE FAKE RAYMARCHING AO)
			float glow = 0;
			float3 glowColor = 0;
			if (_DoGlow[hit.id])
			{
				float distanceFactor = smoothstep(_DistGlowFar, _DistGlowNear, hit.travelDist) * _DistGlowStr;

				float d = (hit.iterations / _MaxSteps) + distanceFactor;
				glow = d * _GlowCoef[hit.id] + _GlowRemap[hit.id];

				if (_UseAlgoColorGlow[hit.id] == 1) glowColor = hit.algoColor;
				else glowColor = _GlowColor[0];
			}

			//RESULT
			float3 res = diffuse * aoSSS + aoSSSColor * (1 - aoSSS) + (spec * kS * shadow + skyColor * KRef + fresnelColor * fresnel* kF) * _ComputeNormals[hit.id]; //multiply normal-dependant components by 0 if normals were not computed
			res = min(res, res * (shadow)+_ShadowColor * (1 - shadow)); //apply shadow
			res = max(BlendLinearLight(res, glow * glowColor) ,res); //apply glow

			//ALPHA
			float alpha = _Alpha;

			return float4 (res,alpha);
		}

		ENDCG

		Pass // pass 0 : middle eye
		{
			CGPROGRAM

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				float2 uv = o.uv;
				uv = uv * 2 - 1;
				float4 viewSpace = mul(_InverseProjectionMatrixMiddle, float4(uv, 1,  1));
				float3 rdCam = viewSpace.xyz / viewSpace.w;

				o.rdCameraSpace = rdCam;
				o.rd = mul(_CamToWorldMiddle, rdCam);

				return o;
			}

			void frag(v2f i, out float4 color:SV_Target0, out float2 depth : SV_Target1)
			{

				float3 rd = normalize(i.rd);
				float2 uv = i.uv;
				float ditherNoise;


				ditherNoise = texCUBElod(_NoiseCubemap, float4(rd, 0)).r;

				Hit hit = rayMarch(_CameraWS, rd, ditherNoise);
				if (_ComputeNormals[hit.id]) hit = writeNormals(hit);
				else hit.normal = float3(1, 0, 0);
				color = shade(hit, rd, _CameraWS);
				depth.r = length(dot((hit.position - _CameraWS), normalize(_CameraForward)));
				if (hit.id == -1) depth.r = _MaxDist;
				depth.g = color.a;
			}
			ENDCG
		}

		Pass // pass 1 : reprojection and compositing with camera pass
		{
			CGPROGRAM

			sampler2D _FirstPass;
			sampler2D _DepthTex;
			sampler2D _MainTex;
			half4 _MainTex_ST;
			sampler2D _CameraDepthTexture;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;

				float2 uv = o.uv;
				uv = uv * 2 - 1;

				float4x4 ipm;
				float4x4 ctw;
				if (unity_StereoEyeIndex > 0) //right
				{
					ipm = _InverseProjectionMatrixRight;
					ctw = _CamToWorldRight;
				}
				else //left
				{
					ipm = _InverseProjectionMatrixLeft;
					ctw = _CamToWorldLeft;
				}

				float4 viewSpace = mul(ipm, float4(uv, 1,  1));
				float3 rdCam = viewSpace.xyz / viewSpace.w;

				o.rdCameraSpace = rdCam;
				o.rd = mul(ctw, rdCam);

				return o;
			}

			void frag(v2f i, out float4 color:SV_Target0)
			{
				float2 uv = i.uv;
				float s = sign(unity_StereoEyeIndex - 0.5);
				float3 rdCameraSpace = normalize(i.rdCameraSpace);

				// CAMERA SPACE STEREO REPROJECTION
				float3 eyePosCameraSpace = float3(0.5*_StereoSep*s, 0, 0); //Ray origin in middle camera space 

				float t = 0; //t0;

				float2 projectedUv;

				float reprojectionSpeed = _ReprojectionSpeed;
				float sampleZ;
				float prevSampleZ;
				float4 sampleColor;

				for (int j = 0; j < _ReprojectionSteps; j++)
				{
					float3 samplePos = eyePosCameraSpace + t * rdCameraSpace;

					float4 clipSpace;

					clipSpace = mul(_ProjectionMatrixMiddle, samplePos);
					clipSpace.xyz /= clipSpace.w;
					projectedUv.x = clipSpace.x*0.5 + 0.5;
					projectedUv.y = clipSpace.y*0.5 + 0.5;

					sampleZ = tex2Dlod(_DepthTex, float4(projectedUv, 0, 0)).r;

					if (-samplePos.z > sampleZ)
					{
						//sampleZ = prevSampleZ;
						break;
					}
					prevSampleZ = sampleZ;
					t = 0 + pow(reprojectionSpeed, j);
				}

				//Resample middle texture after position correction
				float3 pos = eyePosCameraSpace + rdCameraSpace * (sampleZ / -rdCameraSpace.z);
				float4 clipSpace;

				clipSpace = mul(_ProjectionMatrixMiddle, pos);
				clipSpace.xyz /= clipSpace.w;
				projectedUv.x = clipSpace.x*0.5 + 0.5;
				projectedUv.y = clipSpace.y*0.5 + 0.5;

				float4 RMColor = tex2D(_FirstPass, projectedUv);
				float2 depthAlpha = tex2D(_DepthTex, projectedUv);
				float RMZ = depthAlpha.r;
				float4 camColor = tex2D(_MainTex, UnityStereoScreenSpaceUVAdjust(uv, _MainTex_ST)); //unity camera pass to composite with																			//colorblending

				color.rgb = lerp(RMColor.rgb, camColor, 1 - depthAlpha.g);//composite with camera as background

				float Z = RMZ;
				if (_ZTest)
				{
					float camZ = tex2D(_CameraDepthTexture, UnityStereoScreenSpaceUVAdjust(uv, _MainTex_ST));
					camZ = DECODE_EYEDEPTH(camZ);
					float v = smoothstep(0, _ZTestSmooth, (camZ - RMZ));
					color.rgb = lerp(color.rgb, camColor.rgb, 1 - v);
					Z = lerp(RMZ, camZ, 1 - v);
				}
				float distToCam = clamp(0,_MaxDist,length((rdCameraSpace / rdCameraSpace.z) * Z));
				float fog = distToCam / _MaxDist;

				color.rgb = lerp(color.rgb, _FogColor, fog*_FogStrength);//apply fog
				//color.rgb = RMColor.a;
				color.a = 1;
			}
		ENDCG
		}

		Pass // pass 2 : replace reprojection if no stereo (composite raymarching pass with camera pass) 
		{
			CGPROGRAM

			sampler2D _FirstPass;
			sampler2D _DepthTex;
			sampler2D _MainTex;
			half4 _MainTex_ST;
			sampler2D _CameraDepthTexture;


			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				float2 uv = o.uv;
				uv = uv * 2 - 1;
				float4 viewSpace = mul(_InverseProjectionMatrixMiddle, float4(uv, 1, 1));
				float3 rdCam = viewSpace.xyz / viewSpace.w;

				o.rdCameraSpace = rdCam;
				o.rd = float3(0.,0.,0.);//not used here
				o.uv = v.uv;
				return o;
			}

			void frag(v2f i, out float4 color:SV_Target0)
			{
				float4 camColor = tex2D(_MainTex, i.uv); //unity camera pass to composite with
				float4 RMColor = tex2D(_FirstPass, i.uv); //raymarching middle eye pass
				float RMZ = tex2D(_DepthTex, i.uv).r; //raymarching middle eye Z
				float Z = RMZ;
				color.rgb = lerp(RMColor.rgb, camColor, 1 - RMColor.a); //composite with camera as background	
				if (_ZTest) //depth blending
				{
					float camZ;
					float v;
					camZ = tex2D(_CameraDepthTexture, i.uv);
					camZ = DECODE_EYEDEPTH(camZ);
					v = smoothstep(0, _ZTestSmooth, (camZ - RMZ));
					color.rgb = lerp(color.rgb, camColor.rgb, 1 - v);
					Z = lerp(RMZ, camZ, 1 - v);
				}
				float distToCam = clamp(0, _MaxDist, length((i.rdCameraSpace / i.rdCameraSpace.z) * Z));
				float fog = distToCam / _MaxDist;
				color.rgb = lerp(color.rgb, _FogColor, fog*_FogStrength);
				color.a = 1;
			}

			ENDCG
		}

	}
}