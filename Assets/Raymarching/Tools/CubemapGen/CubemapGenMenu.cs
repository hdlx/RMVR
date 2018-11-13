using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class CubemapGenMenu : MonoBehaviour {

    [MenuItem("GameObject/GenerateCubemap")]
    static void Generate()
    {
        
        AssetDatabase.CreateAsset(CubemapGen.generateCubemap(1024, 1000), "Assets/Cubemap.cubemap");
    }
}
