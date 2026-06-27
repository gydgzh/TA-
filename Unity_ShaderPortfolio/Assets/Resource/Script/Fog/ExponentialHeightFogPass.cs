using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class ExponentialHeightFogPass : ScriptableRenderPass
{
    private Material fogMaterial;
    private RenderTargetIdentifier source;
    private RenderTargetHandle tempTexture;
    
    // 雾效参数
    private Color fogColor;
    private float fogDensity;
    private float fogHeightFalloff;
    private float fogStartDistance;
    private float fogHeight;
    private float fogMaxDistance;

    public ExponentialHeightFogPass(Material material)
    {
        fogMaterial = material;
        renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
        tempTexture.Init("_TempFogTexture");
    }

    public void UpdateParams(Color color, float density, float heightFalloff, 
                            float startDistance, float height, float maxDistance)
    {
        fogColor = color;
        fogDensity = density;
        fogHeightFalloff = heightFalloff;
        fogStartDistance = startDistance;
        fogHeight = height;
        fogMaxDistance = maxDistance;
    }

    public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
    {
        cmd.GetTemporaryRT(tempTexture.id, cameraTextureDescriptor);
        // RTHandle rtHandle;
        // rtHandle.rt.a
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        if (fogMaterial == null) return;

        CommandBuffer cmd = CommandBufferPool.Get("Exponential Height Fog");
        source = renderingData.cameraData.renderer.cameraColorTargetHandle;
        // 设置材质参数
        fogMaterial.SetColor("_FogColor", fogColor);
        fogMaterial.SetFloat("_FogDensity", fogDensity);
        fogMaterial.SetFloat("_FogHeightFalloff", fogHeightFalloff);
        fogMaterial.SetFloat("_FogStartDistance", fogStartDistance);
        fogMaterial.SetFloat("_FogHeight", fogHeight);
        fogMaterial.SetFloat("_FogMaxDistance", fogMaxDistance);
        
        // 应用雾效
        Blit(cmd, source, tempTexture.Identifier(), fogMaterial);
        Blit(cmd, tempTexture.Identifier(), source);
        
        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }

    public override void FrameCleanup(CommandBuffer cmd)
    {
        cmd.ReleaseTemporaryRT(tempTexture.id);
    }
}