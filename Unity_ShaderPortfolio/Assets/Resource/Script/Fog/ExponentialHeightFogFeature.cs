using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class ExponentialHeightFogFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class FogSettings
    {
        public Color fogColor = new Color(0.5f, 0.6f, 0.7f, 1.0f);
        [Range(0, 0.1f)] public float fogDensity = 0.01f;
        [Range(0, 0.1f)] public float fogHeightFalloff = 0.01f;
        [Range(0, 100)] public float fogStartDistance = 10f;
        public float fogHeight = 0f;
        public float fogMaxDistance = 500f;
    }

    public FogSettings settings = new FogSettings();
    
    private ExponentialHeightFogPass fogPass;
    private Material fogMaterial;

    public override void Create()
    {
        fogMaterial = CoreUtils.CreateEngineMaterial("Hidden/ExponentialHeightFog");
        fogPass = new ExponentialHeightFogPass(fogMaterial);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType == CameraType.Game || 
            renderingData.cameraData.cameraType == CameraType.SceneView)
        {
            fogPass.UpdateParams(
                settings.fogColor,
                settings.fogDensity,
                settings.fogHeightFalloff,
                settings.fogStartDistance,
                settings.fogHeight,
                settings.fogMaxDistance
            );
            renderer.EnqueuePass(fogPass);
        }
    }
    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            CoreUtils.Destroy(fogMaterial);
        }
    }
}