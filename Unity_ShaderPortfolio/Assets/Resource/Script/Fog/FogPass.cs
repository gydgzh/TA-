using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class FogPass : ScriptableRenderPass
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

    private static readonly int FogColorID = Shader.PropertyToID("_FogColor");
    private static readonly int FogDensityID = Shader.PropertyToID("_FogDensity");
    private static readonly int FogHeightFalloffID = Shader.PropertyToID("_FogHeightFalloff");
    private static readonly int FogStartDistanceID = Shader.PropertyToID("_FogStartDistance");
    private static readonly int FogHeightID = Shader.PropertyToID("_FogHeight");
    private static readonly int FogMaxDistanceID = Shader.PropertyToID("_FogMaxDistance");

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

    public FogPass(Material material)
    {
        fogMaterial = material;
        renderPassEvent = RenderPassEvent.AfterRenderingTransparents;

        // 一定要初始化，不然后面 GetTemporaryRT / Identifier 会出问题
        tempTexture.Init("_TempHeightFogTexture");
    }

    public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
    {
        if (fogMaterial == null) return;

        cameraTextureDescriptor.depthBufferBits = 0;
        cmd.GetTemporaryRT(tempTexture.id, cameraTextureDescriptor, FilterMode.Bilinear);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        if (fogMaterial == null) return;

        CommandBuffer cmd = CommandBufferPool.Get("Height Fog");

        source = (RenderTargetIdentifier)renderingData.cameraData.renderer.cameraColorTargetHandle;

        fogMaterial.SetColor(FogColorID, fogColor);
        fogMaterial.SetFloat(FogDensityID, fogDensity);
        fogMaterial.SetFloat(FogHeightFalloffID, fogHeightFalloff);
        fogMaterial.SetFloat(FogStartDistanceID, fogStartDistance);
        fogMaterial.SetFloat(FogHeightID, fogHeight);
        fogMaterial.SetFloat(FogMaxDistanceID, fogMaxDistance);

        Blit(cmd, source, tempTexture.Identifier(), fogMaterial);
        Blit(cmd, tempTexture.Identifier(), source);

        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }

    public override void FrameCleanup(CommandBuffer cmd)
    {
        if (cmd == null) return;
        cmd.ReleaseTemporaryRT(tempTexture.id);
    }
}