using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;              // CoreUtils 在这里
using UnityEngine.Rendering.Universal;

public class FogFeature : ScriptableRendererFeature
{
    //添加pass
    [System.Serializable]
    public class FogSettings2
    {
        public Color fogColor = new Color();            // Serializable
        [Range(0, 0.1f)] public float fogDensity;       // Serializable
        [Range(0, 0.1f)] public float fogHeightFalloff = 0.01f;
        [Range(0, 100)] public float fogStartDistance = 10f;
        public float fogHeight = 0f;
        public float fogMaxDistance = 500f;
        
    }

    //调用fogPass
    private FogPass fogpass;
    private Material fogMaterial;
    
    public FogSettings2 settings = new FogSettings2(); 

    public override void Create()
    {
        fogMaterial = CoreUtils.CreateEngineMaterial(shaderPath: "Hidden/HeightFog");
        fogpass = new FogPass(fogMaterial);
        //要传入材质球
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType == CameraType.Game || 
            renderingData.cameraData.cameraType == CameraType.SceneView)
        {
            //希望在游戏窗口和屏幕窗口都显示效果
            fogpass.UpdateParams(
                settings.fogColor,
                settings.fogDensity,
                settings.fogHeightFalloff,
                settings.fogStartDistance,
                settings.fogHeight,
                settings.fogMaxDistance
            );
            renderer.EnqueuePass(fogpass);
        }
    }
}