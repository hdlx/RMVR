//MIT License
//
//Copyright (c) 2018 http://hubpaul.com
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

//This script should be put on a camera. It then takes care of everything to compute raymarching as a post processing effect.
//It stores variables related to the raymarching algorithm and to the shading used in it.
//Variables implied in the shading exist in 3 version in order to use different materials.
//The name "map" describe a distance field function (i.e. one or several raymarched objects).
//The maps can be tweaked in the RMMaps.cginc file. 

//For VR, set mode to SINGLE PASS STEREO
//VR uses eye reprojection with screenspace raymarching, adapted from article :
//Fast Gather-based Construction of Stereoscopic Images Using Reprojection by Marries van de Hoef, Bas Zalmstra


using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;

[ExecuteInEditMode]
public class Raymarching: MonoBehaviour {

	[Range(0.0000001f,0.1f)]
	public float minDist = 0.001f;
	[Range(1,1000)]
	public int maxSteps = 64;
	[Range(0,1000)]
	public float maxDist = 30;
	[Range(0.1f,2f)]
	public float eyeResolution = 1;
	public int computedW = 0;
	public int computedH = 0;
	[Range(0f,20f)]
	public float dithering = 0;
	public bool heatMap = false;

	[Range(0f,30f)]
	public float stereoSeparationFactor = 1;

	public Cubemap cubemap;
	public Texture2DArray diffuseMapArray ;
	[Range(0f,1f)]
	public float alpha = 1;
	public bool alphaDecay = true;
	public bool zTest = false;

	[Range(0f,10f)]
	public float zTestSmooth = 1;

	public enum LightType {Directional, Point};
	public LightType lt = 0;
	[Range(0f,10000f)]
	public float lightPow = 1;
	public Transform pointLightTransform;
	public bool doShadow = true;
	[Range(1,50)]
	public int shadowMaxSteps = 5;
	public float shadowMaxDist = 5;
	[Range(0f,10f)]
	public float shadowtMin = 0.1f;
	[Range(0f,10f)]
	public float shadowSmooth = 1;
	[Range(0f,10f)]
	public float shadowStr = 1;
	public Color shadowColor;

	public enum AoSSSMode {Ao, SSS, CheapAo, CheapSSS};
	public float distGlowNear, distGlowFar,distGlowStr; //not mat id specific ... 

	public bool[] normalsWarning = new bool[3]; // not animated so it can be an array


// MATERIAL SPECIFIC VARIABLES (arrays are not used to make it easily keyable for animation)

//-------------------------------------// MAT0
	public bool computeNormals0 = true;
	private float computeNormalsFloat0;
	public Texture2D diffuseMap0;
	private float useDiffuseTexture0;
	public bool	useAlgoColorDiffuse0;
	private float useAlgoColorDiffuseFloat0; // PRIVATE; convert bool to float and send the float array to the shader
	public Color diffuseColor0 = Color.red;
	public float kD0;
	public float emission0;
	public Color specColor0 = Color.white;
	public float kS0;
	public float roughness0;
	public float kRef0;
	public Color fresnelColor0;
	public float fPow0;
	public float kF0;

	public bool	doGlow0;
	private float doGlowFloat0;
	public Color glowColor0;
	public float glowCoef0 = 1;
	public float glowRemap0 = 0;
	public bool	useAlgoColorGlow0;
	private float useAlgoColorGlowFloat0;

	public bool	doAoSSS0 = false;
	public AoSSSMode aoSSSMode0;
	private float aoSSSModeFloat0;
	private float doAoSSSFloat0;
	public int aoSSSSteps0 = 5;
	private float aoSSSStepsFloat0;
	public float aoSSSDelta0 = 0.1f;
	public float aoSSSCoef0 = 1;
	public float aoSSSRemap0 = 0;
	public Color aoSSSColor0 = Color.black;

//------------------------------------- // MAT1

	public bool computeNormals1;
	private float computeNormalsFloat1;
	public Texture2D diffuseMap1;
	private float useDiffuseTexture1;
	public bool	useAlgoColorDiffuse1;
	private float useAlgoColorDiffuseFloat1;
	public Color diffuseColor1 = Color.red;
	public float kD1;
	public float emission1;
	public Color specColor1= Color.white ;
	public float kS1 ;
	public float roughness1;
	public float kRef1;
	public Color fresnelColor1;
	public float fPow1;
	public float kF1;

	public bool	doGlow1;
	private float doGlowFloat1;
	public Color glowColor1;
	public float glowCoef1 = 1;
	public float glowRemap1 = 0;
	public bool	useAlgoColorGlow1;
	private float useAlgoColorGlowFloat1;

	public bool	doAoSSS1;
	public AoSSSMode aoSSSMode1;
	private float aoSSSModeFloat1;
	private float doAoSSSFloat1;
	public int aoSSSSteps1 = 5;
	private float aoSSSStepsFloat1;
	public float aoSSSDelta1 = 0.1f;
	public float aoSSSCoef1 = 1;
	public float aoSSSRemap1 = 0;
	public Color aoSSSColor1 = Color.black;

//------------------------------------- // MAT2

	public bool computeNormals2;
	private float computeNormalsFloat2;
	public Texture2D diffuseMap2;
	private float useDiffuseTexture2 ;
	public bool	useAlgoColorDiffuse2;
	private float useAlgoColorDiffuseFloat2;
	public Color diffuseColor2 = Color.red;
	public float kD2;
	public float emission2 ;
	public Color specColor2 = Color.white;
	public float kS2 ;
	public float roughness2;
	public float kRef2;
	public Color fresnelColor2;
	public float fPow2;
	public float kF2;

	public bool	doGlow2;
	private float doGlowFloat2;
	public Color glowColor2;
	public float glowCoef2 = 1;
	public float glowRemap2 = 0;
	public bool	useAlgoColorGlow2;
	private float useAlgoColorGlowFloat2;

	public bool	doAoSSS2;
	public AoSSSMode aoSSSMode2;
	private float aoSSSModeFloat2;
	private float doAoSSSFloat2;
	public int aoSSSSteps2;
	private float aoSSSStepsFloat2;
	public float aoSSSDelta2 = 0.1f;
	public float aoSSSCoef2 = 1;
	public float aoSSSRemap2 = 0;
	public Color aoSSSColor2 = Color.black;

//------------------------------------------ 

//SHAPES VARIABLES. Arbitrary variables passed to the map function
	public Color algoColor0;
	public Color algoColor1;
	public Color algoColor2;
	public Color algoColor3;

	public float algoFloat0;
	public float algoFloat1;
	public float algoFloat2;
	public float algoFloat3;

	public enum MapIndex {map0, map1, map2, map3, map4, map5,map6,map7,map8}; //Determines the map used
	public MapIndex mi = 0;

	public float nearClip;

	private Shader raymarchingShader;
	private Material raymarchingMat;

	private Camera camera;
	private Vector3 fakePosition;

	private Matrix4x4 frustumCornersWS;
	private Matrix4x4 frustumCorners;

	private RenderBuffer[] renderBuffer;

    private bool VROn = false;

	[ImageEffectOpaque]
	void OnRenderImage(RenderTexture src, RenderTexture dest) 
	{
		camera.ResetProjectionMatrix();

		// CAMERA MATRICES AND VECTORS SETUP
		// VR enabled or not. If not, shader won't use right/left projection matrixes

		raymarchingMat.SetVector("_CameraForward", camera.transform.forward);
		raymarchingMat.SetVector("_CameraWS", camera.transform.position);

		Matrix4x4 m;

		m =  GL.GetGPUProjectionMatrix(camera.projectionMatrix,true).inverse;
		m[1,1] *= -1;
		raymarchingMat.SetMatrix("_InverseProjectionMatrixMiddle", m );
		raymarchingMat.SetMatrix("_ProjectionMatrixMiddle", m.inverse );

		m =  GL.GetGPUProjectionMatrix( camera.GetStereoProjectionMatrix(Camera.StereoscopicEye.Left),true ).inverse;
		m[1,1] *= -1;
		raymarchingMat.SetMatrix("_InverseProjectionMatrixLeft",  m);

		m =  GL.GetGPUProjectionMatrix( camera.GetStereoProjectionMatrix(Camera.StereoscopicEye.Right),true ).inverse;
		m[1,1] *= -1;
		raymarchingMat.SetMatrix("_InverseProjectionMatrixRight", m);

		raymarchingMat.SetMatrix("_CamToWorldMiddle", camera.cameraToWorldMatrix );

		// RENDER TARGET RESOLUTION SETUP
		int hh;
		int ww;

		if (!Application.isPlaying) // if application is not playing, VR enabled or not
		{
			hh = Screen.height;
			ww = Screen.width;
		}
		else
		{
			if (!VROn ) 
			{
				// get window/screen active resolution
				hh = Screen.height;
				ww = Screen.width;
			} 
			else 
			{
				// get headset eye resolution
				hh = UnityEngine.XR.XRSettings.eyeTextureHeight;
				ww = UnityEngine.XR.XRSettings.eyeTextureWidth;
			}
		}

		// h and w are real computed resolutions. That way,the user know what the HMD API expect for a standard resolution and 
		// he can apply a 0.1 - 2.0 factor to it
		int h = computedH = (int) Mathf.Floor(hh * eyeResolution);
		int w = computedW = (int) Mathf.Floor(ww * eyeResolution);

		//RENDERING
		RenderTexture active = RenderTexture.active;

		RenderTexture RTMiddleEye = RenderTexture.GetTemporary(w,h,0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear, 1, RenderTextureMemoryless.None, VRTextureUsage.None);
		RTMiddleEye.filterMode = FilterMode.Trilinear;

		RenderTexture RTDepth = RenderTexture.GetTemporary(w,h,0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear, 1, RenderTextureMemoryless.None, VRTextureUsage.None);
		RTDepth.filterMode = FilterMode.Point;

		renderBuffer[0] = RTMiddleEye.colorBuffer;
		renderBuffer[1] = RTDepth.colorBuffer;

		Graphics.SetRenderTarget(renderBuffer, RTMiddleEye.depthBuffer);

		Graphics.Blit(null, raymarchingMat,0);

		raymarchingMat.SetTexture("_FirstPass", RTMiddleEye); 
		raymarchingMat.SetTexture("_DepthTex", RTDepth);

		if (!VROn || !Application.isPlaying) Graphics.Blit(src, dest, raymarchingMat, 2); 
        else Graphics.Blit(src, dest, raymarchingMat, 1); 

		RenderTexture.ReleaseTemporary(RTDepth);
		RenderTexture.ReleaseTemporary(RTMiddleEye);
    }


	void Initialize()
	{
        if (raymarchingMat == null) DestroyImmediate(raymarchingMat);
		raymarchingMat = new Material(Shader.Find("Raymarching/RayMarchingShader"));
		renderBuffer = new RenderBuffer [2];
		camera = GetComponent<Camera>();
        Shader.SetGlobalTexture("_NoiseCubemap", Resources.Load<Cubemap>("Textures/HashCubemap"));
		Shader.SetGlobalTexture("_Hash3DTxt", Resources.Load<Texture3D> ("Textures/Hash3DTxt"));
		Shader.SetGlobalTexture ("_Perlin3DTxt", Resources.Load<Texture3D> ("Textures/Perlin3DTxt"));
		VROn = (PlayerSettings.virtualRealitySupported && UnityEngine.XR.XRDevice.isPresent);
        if (VROn) PlayerSettings.stereoRenderingPath = StereoRenderingPath.SinglePass;
	}

	void Start()
	{
		Initialize();
	}
	void OnEnable()
	{
		Initialize();
	}

	void Update() //essentially passes var. to the shader.
	{
		
		raymarchingMat.SetFloat("_StereoSep", camera.stereoSeparation * stereoSeparationFactor );
		raymarchingMat.SetInt("_MaxSteps", maxSteps);
		raymarchingMat.SetFloat("_MinDist", minDist);
		raymarchingMat.SetFloat("_MaxDist", maxDist);
		raymarchingMat.SetFloat("_Dithering", dithering);
		raymarchingMat.SetTexture("_Cubemap", cubemap);

		// Optimal (exponential) raymarching speed (FOR THE SCREEN SPACE STEREO REPROJECTION), for 5 maxSteps (#defined in the shader)
		// for example : distance = 100; steps = 5 ; ReprojectionSpeed = 3.16. At the last step, the ray traveled distance 
		// is 3.16^4 unit, so approximately 100.
		// Need to be rechecked with HMD. It my be better to use some static value
		raymarchingMat.SetFloat ("_ReprojectionSpeed", Mathf.Exp( (Mathf.Log (maxDist)   ) / (5 - 1))   ) ;  

		raymarchingMat.SetInt("_HeatMap", (int)System.Convert.ToSingle(heatMap) );

		raymarchingMat.SetFloat("_Alpha", alpha);
		raymarchingMat.SetInt("_AlphaDecay", System.Convert.ToInt16(alphaDecay));
		raymarchingMat.SetInt("_ZTest", System.Convert.ToInt16(zTest));
		raymarchingMat.SetFloat("_ZTestSmooth", zTestSmooth);

		raymarchingMat.SetInt("_UsePointLight", (int)lt);
		raymarchingMat.SetFloat("_LightPow", lightPow);

		Vector3 plp;
		if (pointLightTransform == null) plp = transform.position;
		else plp = pointLightTransform.position;

		raymarchingMat.SetVector("_PointLightPosition",plp);

		raymarchingMat.SetInt("_DoShadow", System.Convert.ToInt16(doShadow));
		raymarchingMat.SetInt("_ShadowMaxSteps", shadowMaxSteps);
		raymarchingMat.SetFloat("_ShadowMaxDist", shadowMaxDist);
		raymarchingMat.SetFloat("_ShadowtMin", shadowtMin);
		raymarchingMat.SetFloat("_ShadowSmooth", shadowSmooth);
		raymarchingMat.SetFloat("_ShadowStr", shadowStr);
		raymarchingMat.SetColor("_ShadowColor", shadowColor);

        //------------------------------ MAT SPECIFIC VALUES

        computeNormalsFloat0 = System.Convert.ToSingle(computeNormals0);
		computeNormalsFloat1 = System.Convert.ToSingle(computeNormals1);
		computeNormalsFloat2 = System.Convert.ToSingle(computeNormals2);
		raymarchingMat.SetFloatArray("_ComputeNormals", new float[] {computeNormalsFloat0, computeNormalsFloat1, computeNormalsFloat2} );

		raymarchingMat.SetTexture( "_DiffuseMap0",diffuseMap0 );
		raymarchingMat.SetTexture( "_DiffuseMap1",diffuseMap1 );
		raymarchingMat.SetTexture( "_DiffuseMap2",diffuseMap2 );
		float[] useDiffuseTexArray = new float[] { System.Convert.ToSingle(!(diffuseMap0 == null)), System.Convert.ToSingle(!(diffuseMap1 == null)), System.Convert.ToSingle(!(diffuseMap2 == null))};
		raymarchingMat.SetFloatArray("_UseDiffuseTexture", useDiffuseTexArray);

		raymarchingMat.SetColorArray("_DiffuseColor", new Color[] {diffuseColor0,diffuseColor1,diffuseColor2});
		raymarchingMat.SetFloatArray("_KD",new float[] {kD0,kD1,kD2});
		useAlgoColorDiffuseFloat0 = System.Convert.ToSingle(useAlgoColorDiffuse0);
		useAlgoColorDiffuseFloat1 = System.Convert.ToSingle(useAlgoColorDiffuse1);
		useAlgoColorDiffuseFloat2 = System.Convert.ToSingle(useAlgoColorDiffuse2);
		raymarchingMat.SetFloatArray("_UseAlgoColorDiffuse", new float[] {useAlgoColorDiffuseFloat0,useAlgoColorDiffuseFloat1,useAlgoColorDiffuseFloat2});
		raymarchingMat.SetFloatArray("_Emission", new float[] {emission0,emission1,emission2});
		raymarchingMat.SetColorArray("_SpecColor", new Color[] {specColor0,specColor1,specColor2} );
		raymarchingMat.SetFloatArray("_Roughness", new float[] {roughness0, roughness1, roughness2});
		raymarchingMat.SetFloatArray("_KS", new float[] {kS0,kS1,kS2});
		raymarchingMat.SetColorArray("_FresnelColor", new Color[] {fresnelColor0,fresnelColor1,fresnelColor2});
		raymarchingMat.SetFloatArray("_FPow", new float[] {fPow0,fPow1,fPow2});
		raymarchingMat.SetFloatArray("_KF", new float[] {kF0,kF1,kF2}); 
		raymarchingMat.SetColorArray("_AoSSSColor",new Color[] {aoSSSColor0,aoSSSColor1,aoSSSColor2});
		raymarchingMat.SetFloatArray("_KRef",new float[]{kRef0,kRef1,kRef2});

		doAoSSSFloat0 = System.Convert.ToSingle(doAoSSS0);
		doAoSSSFloat1 = System.Convert.ToSingle(doAoSSS1);
		doAoSSSFloat2 = System.Convert.ToSingle(doAoSSS2);
		raymarchingMat.SetFloatArray("_DoAoSSS", new float[]{doAoSSSFloat0, doAoSSSFloat1,doAoSSSFloat2});

		aoSSSModeFloat0 = (int)aoSSSMode0;
		aoSSSModeFloat1 = (int)aoSSSMode1;
		aoSSSModeFloat2 = (int)aoSSSMode2;

		raymarchingMat.SetFloatArray("_AoSSSMode", new float[]{aoSSSModeFloat0,aoSSSModeFloat1,aoSSSModeFloat2});
		raymarchingMat.SetFloatArray("_AoSSSSteps",  new float[]{aoSSSSteps0,aoSSSSteps1,aoSSSSteps2});
		raymarchingMat.SetFloatArray("_AoSSSDelta",  new float[]{aoSSSDelta0,aoSSSDelta1,aoSSSDelta2});
		raymarchingMat.SetFloatArray("_AoSSSCoef", new float[]{aoSSSCoef0,aoSSSCoef1,aoSSSCoef2});
		raymarchingMat.SetFloatArray("_AoSSSRemap", new float[]{aoSSSRemap0,aoSSSRemap1,aoSSSRemap2});

		doGlowFloat0 = System.Convert.ToSingle(doGlow0);
		doGlowFloat1 = System.Convert.ToSingle(doGlow1);
		doGlowFloat2 = System.Convert.ToSingle(doGlow2);
		raymarchingMat.SetFloatArray("_DoGlow", new float[] {doGlowFloat0,doGlowFloat1,doGlowFloat2});

		raymarchingMat.SetFloatArray("_GlowCoef", new float[] {glowCoef0,glowCoef1,glowCoef2});
		raymarchingMat.SetFloatArray("_GlowRemap", new float[] {glowRemap0, glowRemap1, glowRemap2});
		raymarchingMat.SetColorArray("_GlowColor", new Color[] {glowColor0,glowColor1, glowColor2});

		useAlgoColorGlowFloat0 = System.Convert.ToSingle(useAlgoColorGlow0);
		useAlgoColorGlowFloat1 = System.Convert.ToSingle(useAlgoColorGlow1);
		useAlgoColorGlowFloat2 = System.Convert.ToSingle(useAlgoColorGlow2);
		raymarchingMat.SetFloatArray("_UseAlgoColorGlow", new float[]{useAlgoColorGlowFloat0,useAlgoColorGlowFloat1,useAlgoColorGlowFloat2});

		raymarchingMat.SetFloat("_DistGlowNear", distGlowNear);
		raymarchingMat.SetFloat("_DistGlowFar", distGlowFar);
		raymarchingMat.SetFloat("_DistGlowStr", distGlowStr);

		int miInt;

		foreach (MapIndex item in System.Enum.GetValues(typeof(MapIndex)) ) 
		{
			miInt = (int)item;
			raymarchingMat.DisableKeyword(string.Format("MAP{0}",miInt.ToString()));
		}

		miInt = (int)mi;
		raymarchingMat.EnableKeyword(string.Format("MAP{0}", miInt.ToString()));
		raymarchingMat.SetFloat("_NearClip", nearClip);
		raymarchingMat.SetColorArray("_AlgoColor", new Color[] {algoColor0, algoColor1, algoColor2, algoColor3});
		raymarchingMat.SetFloatArray("_AlgoFloat", new float[] {algoFloat0, algoFloat1, algoFloat2, algoFloat3});

		if (!computeNormals0) normalsWarning[0] = kD0 != 0 || kS0 != 0 || kRef0 != 0 || kF0 !=0 || doAoSSS0 && aoSSSMode0 == AoSSSMode.Ao || doAoSSS0 && aoSSSMode0 == AoSSSMode.CheapAo || useDiffuseTexArray[0] != 0 ;	
		else normalsWarning[0] = false;

		if (!computeNormals1) normalsWarning[1] = kD1 != 0 || kS1 != 0 || kRef1!= 0 || kF1 !=0 || doAoSSS1 && aoSSSMode1 == AoSSSMode.Ao || doAoSSS1 && aoSSSMode1 == AoSSSMode.CheapAo || useDiffuseTexArray[1] != 0 ;	
		else normalsWarning[1] = false;

		if (!computeNormals2) normalsWarning[2] = kD2 != 0 || kS2 != 0 || kRef2 != 0 || kF2 !=0 || doAoSSS2 && aoSSSMode2 == AoSSSMode.Ao || doAoSSS2 && aoSSSMode2 == AoSSSMode.CheapAo || useDiffuseTexArray[2] != 0 ;	
		else normalsWarning[2] = false;
	}
		
}


