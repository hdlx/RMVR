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

//USE TO CREATE TILING 3D PERLIN NOISE

using UnityEngine;
using UnityEditor;

public class CreateNoise: MonoBehaviour
{

    [MenuItem("GameObject/Create3DNoise")]
    static void Generate()
    {
        Texture3D txt3D;
        int size = 128;
        Material mat = new Material(Shader.Find("Hidden/createNoise3D"));
        RenderTexture rt = new RenderTexture(size, size, 32, RenderTextureFormat.ARGB32);
        RenderTexture.active = rt;
      
		float scale = 10f;
        
        Color[] colorArray = new Color[size * size * size];
		txt3D = new Texture3D(size, size, size, TextureFormat.RFloat, false);
		mat.SetFloat("_res", (float)size);
        mat.SetFloat("_scale", scale);

        for (int z = 0; z < size; z = z+1)
        {
            Texture2D txt2D = new Texture2D(size, size, TextureFormat.ARGB32, false);
            mat.SetFloat("_z", (float)z);
            mat.SetFloat("_res", (float)size);
			mat.SetFloat("_scale", scale);
            Graphics.Blit(null,rt, mat);

            Graphics.CopyTexture(rt, txt2D);
            txt2D.ReadPixels(new Rect(0, 0, size, size), 0, 0, true);

            txt2D.Apply();
			            
            Color[] depthArray = txt2D.GetPixels(0, 0, size, size, 0);

            int idx = 0;
            foreach (Color col in depthArray)
            {
                colorArray[idx + size * size * z] = col ;
  
            idx = idx+1;
            }


             }
        txt3D.SetPixels(colorArray);
        txt3D.Apply();

        
       AssetDatabase.CreateAsset(txt3D, "Assets/txt3D.asset");
        

    }
}