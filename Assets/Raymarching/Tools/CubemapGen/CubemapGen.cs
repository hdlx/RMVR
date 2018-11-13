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

//Generate a noise cubemap.
//Used for a spatialiazed (VR working) dithering
//Uses perlin/FBM noise for eventual other uses, but
//dithering is usually a hash (high frequency perlin)

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class CubemapGen {

	public static Cubemap generateCubemap(int size, float frequency)
	{
		Cubemap cubemap = new Cubemap(size , TextureFormat.RFloat, false);
		RenderTexture rt = RenderTexture.GetTemporary(size,size,0,RenderTextureFormat.ARGBFloat);
		Material mat = new Material( Shader.Find("Custom/GenerateCubemap"));

        RenderTexture.active = rt;

		Texture2D txt;
		mat.SetFloat("_Frequency", frequency);

		mat.SetInt("_Face",0);
		Graphics.Blit(null,rt, mat);
		txt = new Texture2D(size,size,TextureFormat.RGBAFloat,false,true);
		txt.ReadPixels(new Rect(0,0,size,size),0,0,false );
		txt.Apply();
		cubemap.SetPixels(txt.GetPixels(), CubemapFace.PositiveX);


		mat.SetInt("_Face",1);
		Graphics.Blit(null,rt, mat);
		txt = new Texture2D(size,size,TextureFormat.RGBAFloat,false,true);
		txt.ReadPixels(new Rect(0,0,size,size),0,0,false );
		txt.Apply();
		cubemap.SetPixels(txt.GetPixels(), CubemapFace.NegativeX);


		mat.SetInt("_Face",2);
		Graphics.Blit(null,rt, mat);
		txt = new Texture2D(size,size,TextureFormat.RGBAFloat,false,true);
		txt.ReadPixels(new Rect(0,0,size,size),0,0,false );
		txt.Apply();
		cubemap.SetPixels(txt.GetPixels(), CubemapFace.PositiveY);


		mat.SetInt("_Face",3);
		Graphics.Blit(null,rt, mat);
		txt = new Texture2D(size,size,TextureFormat.RGBAFloat,false,true);
		txt.ReadPixels(new Rect(0,0,size,size),0,0,false );
		txt.Apply();
		cubemap.SetPixels(txt.GetPixels(), CubemapFace.NegativeY);


		mat.SetInt("_Face",4);
		Graphics.Blit(null,rt, mat);
		txt = new Texture2D(size,size,TextureFormat.RGBAFloat,false,true);
		txt.ReadPixels(new Rect(0,0,size,size),0,0,false );
		txt.Apply();
		cubemap.SetPixels(txt.GetPixels(), CubemapFace.PositiveZ);

		mat.SetInt("_Face",5);
		Graphics.Blit(null,rt, mat);
		txt = new Texture2D(size,size,TextureFormat.RGBAFloat,false,true);
		txt.ReadPixels(new Rect(0,0,size,size),0,0,false );
		txt.Apply();
		cubemap.SetPixels(txt.GetPixels(), CubemapFace.NegativeZ);

		cubemap.Apply();

		RenderTexture.ReleaseTemporary(rt);

		return cubemap;
	}

}
