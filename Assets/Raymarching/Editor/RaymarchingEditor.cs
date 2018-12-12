using UnityEngine;
using UnityEditor;


[CustomEditor(typeof(Raymarching))]
[CanEditMultipleObjects]
public class RaymarchingEditor : Editor
{
    Raymarching rmscript;

    SerializedProperty minDist;
    SerializedProperty maxDist;
    SerializedProperty maxSteps;
    SerializedProperty eyeResolution;
    SerializedProperty dithering;
    SerializedProperty heatMap;

    SerializedProperty stereoSeparationFactor;

    SerializedProperty alpha;
    SerializedProperty fogColor;
    SerializedProperty fogStrength;
    SerializedProperty zTest;
    SerializedProperty zTestSmooth;

    SerializedProperty lightPow;
    SerializedProperty lightType;
    SerializedProperty pointLightTransform;
    SerializedProperty doShadow;
    SerializedProperty shadowMaxDist;
    SerializedProperty shadowtMin;
    SerializedProperty shadowSmooth;
    SerializedProperty shadowStr;
    SerializedProperty shadowColor;

    SerializedProperty cubemap;

    enum selectedMat { mat0, mat1, mat2 };
    selectedMat sm;

    SerializedProperty[] computeNormals = new SerializedProperty[3];

    SerializedProperty[] diffuseMap = new SerializedProperty[3];
    SerializedProperty[] diffuseColor = new SerializedProperty[3];
    SerializedProperty[] kD = new SerializedProperty[3];
    SerializedProperty[] useAlgoColorDiffuse = new SerializedProperty[3];
    SerializedProperty[] emission = new SerializedProperty[3];
    SerializedProperty[] specColor = new SerializedProperty[3];
    SerializedProperty[] kS = new SerializedProperty[3];
    SerializedProperty[] roughness = new SerializedProperty[3];
    SerializedProperty[] kRef = new SerializedProperty[3];
    SerializedProperty[] fresnelColor = new SerializedProperty[3];
    SerializedProperty[] fPow = new SerializedProperty[3];
    SerializedProperty[] kF = new SerializedProperty[3];
    SerializedProperty[] aoSSSColor = new SerializedProperty[3];

    SerializedProperty[] doAoSSS = new SerializedProperty[3];
    SerializedProperty[] aoSSSMode = new SerializedProperty[3];
    SerializedProperty[] aoSSSSteps = new SerializedProperty[3];
    SerializedProperty[] aoSSSDelta = new SerializedProperty[3];
    SerializedProperty[] aoSSSCoef = new SerializedProperty[3];
    SerializedProperty[] aoSSSRemap = new SerializedProperty[3];

    SerializedProperty[] doGlow = new SerializedProperty[3];
    SerializedProperty[] glowColor = new SerializedProperty[3];
    SerializedProperty[] glowCoef = new SerializedProperty[3];
    SerializedProperty[] glowRemap = new SerializedProperty[3];
    SerializedProperty[] useAlgoColorGlow = new SerializedProperty[3];
    SerializedProperty distGlowNear, distGlowFar, distGlowStr;

    SerializedProperty mapIndex;
    SerializedProperty[] algoColor = new SerializedProperty[4];
    SerializedProperty[] algoFloat = new SerializedProperty[4];

    SerializedProperty nearClip;

    bool toggle;
    int tabs = 0;
    //int selectedMat = 0;

    public Material mat;

    void OnEnable()
    {
        rmscript = (Raymarching)target;
        serializedObject.Update();


        // GENERAL
        minDist = serializedObject.FindProperty("minDist");
        maxDist = serializedObject.FindProperty("maxDist");
        maxSteps = serializedObject.FindProperty("maxSteps");
        eyeResolution = serializedObject.FindProperty("eyeResolution");
        dithering = serializedObject.FindProperty("dithering");
        heatMap = serializedObject.FindProperty("heatMap");
        stereoSeparationFactor = serializedObject.FindProperty("stereoSeparationFactor");

        // MATERIAL Common
        alpha = serializedObject.FindProperty("alpha");
        fogStrength = serializedObject.FindProperty("fogStrength");
        fogColor = serializedObject.FindProperty("fogColor");
        zTest = serializedObject.FindProperty("zTest");
        zTestSmooth = serializedObject.FindProperty("zTestSmooth");

        lightType = serializedObject.FindProperty("lt");
        lightPow = serializedObject.FindProperty("lightPow");
        pointLightTransform = serializedObject.FindProperty("pointLightTransform");
        cubemap = serializedObject.FindProperty("cubemap");
        doShadow = serializedObject.FindProperty("doShadow");
        shadowMaxDist = serializedObject.FindProperty("shadowMaxDist");
        shadowtMin = serializedObject.FindProperty("shadowtMin");
        shadowSmooth = serializedObject.FindProperty("shadowSmooth");
        shadowStr = serializedObject.FindProperty("shadowStr");
        shadowColor = serializedObject.FindProperty("shadowColor");

        distGlowNear = serializedObject.FindProperty("distGlowNear");
        distGlowFar = serializedObject.FindProperty("distGlowFar");
        distGlowStr = serializedObject.FindProperty("distGlowStr");

        //MATERIAL ID SPECIFIC
        for (int i = 0; i < 3; i++)
        {
            computeNormals[i] = serializedObject.FindProperty("computeNormals" + i.ToString());

            diffuseMap[i] = serializedObject.FindProperty("diffuseMap" + i.ToString());
            diffuseColor[i] = serializedObject.FindProperty("diffuseColor" + i.ToString());
            kD[i] = serializedObject.FindProperty("kD" + i.ToString());
            useAlgoColorDiffuse[i] = serializedObject.FindProperty("useAlgoColorDiffuse" + i.ToString());
            emission[i] = serializedObject.FindProperty("emission" + i.ToString());
            specColor[i] = serializedObject.FindProperty("specColor" + i.ToString());
            kS[i] = serializedObject.FindProperty("kS" + i.ToString());
            roughness[i] = serializedObject.FindProperty("roughness" + i.ToString());
            kRef[i] = serializedObject.FindProperty("kRef" + i.ToString());
            fresnelColor[i] = serializedObject.FindProperty("fresnelColor" + i.ToString());
            fPow[i] = serializedObject.FindProperty("fPow" + i.ToString());
            kF[i] = serializedObject.FindProperty("kF" + i.ToString());
            aoSSSColor[i] = serializedObject.FindProperty("aoSSSColor" + i.ToString());

            doAoSSS[i] = serializedObject.FindProperty("doAoSSS" + i.ToString());
            aoSSSMode[i] = serializedObject.FindProperty("aoSSSMode" + i.ToString());
            aoSSSSteps[i] = serializedObject.FindProperty("aoSSSSteps" + i.ToString());
            aoSSSDelta[i] = serializedObject.FindProperty("aoSSSDelta" + i.ToString());
            aoSSSCoef[i] = serializedObject.FindProperty("aoSSSCoef" + i.ToString());
            aoSSSRemap[i] = serializedObject.FindProperty("aoSSSRemap" + i.ToString());

            doGlow[i] = serializedObject.FindProperty("doGlow" + i.ToString());
            glowColor[i] = serializedObject.FindProperty("glowColor" + i.ToString());
            glowCoef[i] = serializedObject.FindProperty("glowCoef" + i.ToString());
            glowRemap[i] = serializedObject.FindProperty("glowRemap" + i.ToString());
            useAlgoColorGlow[i] = serializedObject.FindProperty("useAlgoColorGlow" + i.ToString());
        }

        //RAYMARCHING SHAPE RELATED
        mapIndex = serializedObject.FindProperty("mi");

        for (int i = 0; i < 4; i++)
        {
            algoColor[i] = serializedObject.FindProperty("algoColor" + i.ToString());
            algoFloat[i] = serializedObject.FindProperty("algoFloat" + i.ToString());
        }
        nearClip = serializedObject.FindProperty("nearClip");
    }

    public override void OnInspectorGUI()
    {
        serializedObject.Update();

        EditorGUILayout.Space();
        tabs = GUILayout.Toolbar(tabs, new string[] { "General", "Material", "RM Shapes" });
        if (tabs == 0)
        {
            EditorGUILayout.LabelField(new GUIContent("Raymarching algorithm"), EditorStyles.boldLabel);
            EditorGUILayout.PropertyField(minDist);
            EditorGUILayout.PropertyField(maxDist);
            EditorGUILayout.PropertyField(maxSteps);
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.PropertyField(eyeResolution);
            EditorGUILayout.LabelField(new GUIContent("Computed resolution : " + rmscript.computedW.ToString() + " * " + rmscript.computedH.ToString()), EditorStyles.boldLabel);
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.PropertyField(dithering, new GUIContent("Dithering/Speckle fade (uses noise cubemap)"));
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.PropertyField(heatMap);
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.PropertyField(stereoSeparationFactor);

        }
        else if (tabs == 1)
        {
            //COMMON
            EditorGUILayout.PropertyField(alpha);
            EditorGUILayout.PropertyField(fogStrength);
            EditorGUILayout.PropertyField(fogColor);

            EditorGUILayout.PropertyField(zTest);
            EditorGUILayout.PropertyField(zTestSmooth);

            EditorGUILayout.LabelField(new GUIContent("General param."), EditorStyles.boldLabel);
            EditorGUILayout.PropertyField(lightType, new GUIContent("Light type"));
            EditorGUILayout.PropertyField(lightPow, new GUIContent("Light power"));
            EditorGUILayout.PropertyField(pointLightTransform, new GUIContent("Point light tranform"));
            //

            EditorGUILayout.PropertyField(doShadow);
            if (doShadow.boolValue)
            {
                EditorGUI.indentLevel++;
                EditorGUILayout.PropertyField(shadowMaxDist);
                //EditorGUILayout.PropertyField(shadowMaxSteps);
                EditorGUILayout.PropertyField(shadowtMin);
                EditorGUILayout.PropertyField(shadowSmooth);
                EditorGUILayout.PropertyField(shadowStr);
                EditorGUILayout.PropertyField(shadowColor);
                EditorGUI.indentLevel--;
            }

            EditorGUILayout.PropertyField(cubemap, new GUIContent("Reflection Cubemap"));

            EditorGUILayout.Space();

            //SPECIFIC
            EditorGUILayout.LabelField(new GUIContent("Material specific param."), EditorStyles.boldLabel);

            sm = (selectedMat)EditorGUILayout.EnumPopup("Material (hit ID in map() function)", sm);

            EditorGUILayout.PropertyField(computeNormals[(int)sm]);
            

            EditorGUILayout.PropertyField(diffuseMap[(int)sm]);

            EditorGUILayout.BeginHorizontal();
            GUI.enabled = !useAlgoColorDiffuse[(int)sm].boolValue;
            EditorGUILayout.PropertyField(diffuseColor[(int)sm], new GUIContent("Diffuse color"));
            GUI.enabled = true;
            EditorGUILayout.PropertyField(useAlgoColorDiffuse[(int)sm], new GUIContent("Use algo. color"), new GUILayoutOption[] { GUILayout.MaxWidth(EditorGUIUtility.labelWidth) });
            EditorGUILayout.EndHorizontal();


            EditorGUILayout.PropertyField(kD[(int)sm], new GUIContent("Diffuse coef."));
            EditorGUILayout.PropertyField(emission[(int)sm], new GUIContent("emission coef."));
            EditorGUILayout.PropertyField(specColor[(int)sm], new GUIContent("Specular color"));
            EditorGUILayout.PropertyField(kS[(int)sm], new GUIContent("Specular coef."));
            EditorGUILayout.PropertyField(roughness[(int)sm], new GUIContent("Specular roughness"));
            EditorGUILayout.PropertyField(kRef[(int)sm], new GUIContent("Reflection coef."));
            EditorGUILayout.PropertyField(fresnelColor[(int)sm], new GUIContent("Fresnel color"));
            EditorGUILayout.PropertyField(fPow[(int)sm], new GUIContent("Fresnel decay"));
            EditorGUILayout.PropertyField(kF[(int)sm], new GUIContent("Fresnel coef."));


            EditorGUILayout.PropertyField(doAoSSS[(int)sm], new GUIContent("Fake ao/sss"));
            if (doAoSSS[(int)sm].boolValue)
            {
                EditorGUI.indentLevel++;
                EditorGUILayout.PropertyField(aoSSSMode[(int)sm], new GUIContent("Mode"));
                if (aoSSSMode[(int)sm].enumValueIndex == 0 || aoSSSMode[(int)sm].enumValueIndex == 1)
                    EditorGUILayout.PropertyField(aoSSSSteps[(int)sm], new GUIContent("Steps"));
                EditorGUILayout.PropertyField(aoSSSDelta[(int)sm], new GUIContent("Delta"));
                EditorGUILayout.PropertyField(aoSSSCoef[(int)sm], new GUIContent("Coef."));
                EditorGUILayout.PropertyField(aoSSSRemap[(int)sm], new GUIContent("Remap."));
                EditorGUILayout.PropertyField(aoSSSColor[(int)sm], new GUIContent("Color (black for standard effect)"));
                EditorGUI.indentLevel--;
            }


            EditorGUILayout.PropertyField(doGlow[(int)sm], new GUIContent("Glow"));


            if (doGlow[(int)sm].boolValue)
            {
                EditorGUI.indentLevel++;
                EditorGUILayout.BeginHorizontal();
                GUI.enabled = !useAlgoColorGlow[(int)sm].boolValue;
                EditorGUILayout.PropertyField(glowColor[(int)sm], new GUIContent("Glow color"));
                GUI.enabled = true;
                EditorGUILayout.PropertyField(useAlgoColorGlow[(int)sm], new GUIContent("Use algo. color"));
                EditorGUILayout.EndHorizontal();
                EditorGUILayout.PropertyField(glowCoef[(int)sm], new GUIContent("Glow coeff"));
                EditorGUILayout.PropertyField(glowRemap[(int)sm], new GUIContent("Glow remap"));

                EditorGUILayout.LabelField(new GUIContent("Glow over distance : near dist to far dist = strength to base glow value "));
                EditorGUI.indentLevel++;

                EditorGUILayout.PropertyField(distGlowNear, new GUIContent("Near dist."));
                EditorGUILayout.PropertyField(distGlowFar, new GUIContent("Far dist."));
                EditorGUILayout.PropertyField(distGlowStr, new GUIContent("Strength"));
                EditorGUI.indentLevel--;

                EditorGUI.indentLevel--;

            }
            if (rmscript.normalsWarning[(int)sm]) EditorGUILayout.HelpBox("Some normals requiring components are not set to zero. Verify shading or check \"compute normals\" ", MessageType.Warning);

        }
        else if (tabs == 2) // SHAPES
        {
            EditorGUILayout.PropertyField(mapIndex, new GUIContent("Map index from CGInc/RMPatterns"));
            EditorGUILayout.LabelField(new GUIContent("Color passed to the map() function :"));
            EditorGUI.indentLevel++;
            for (int i = 0; i < 4; i++) EditorGUILayout.PropertyField(algoColor[i], new GUIContent(string.Format("Color {0}", i)));


            for (int i = 0; i < 4; i++) EditorGUILayout.PropertyField(algoFloat[i], new GUIContent(string.Format("Float {0}", i)));

            EditorGUI.indentLevel--;
            EditorGUILayout.PropertyField(nearClip);

        }

        serializedObject.ApplyModifiedProperties();

        //	rmScript.BIBI();
    }

}