#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Assets/Resource/Shader/ShaderLibrary/CustomBRDF.hlsl"


struct  LightingResult
{
    half3 directDiffuse;
    half3 directSpecular;
    half3 indirectDiffuse;
    half3 indirectSpecular;
};

#define EPSILON 1e-6

void DirectLighting(BRDFData brdfData,Light light,half3 normalWS, half3 viewDir,SurfaceData surface_data,inout LightingResult lightingresult)
{
    half3 L = light.direction;
    half3 N = normalWS;
    half3 V = viewDir;
    half NdotL = saturate(dot(N,L));
    half3 radiance = light.color * light.shadowAttenuation * NdotL;

    lightingresult.directDiffuse = radiance * brdfData.diffuse / PI;
    float NdotV = max(dot(N,V),0.00001);

    brdfData.perceptualRoughness = max(0.04,brdfData.perceptualRoughness);
    float3 H = normalize(V + L);

    float NDF = DistributionGGX(N, H, brdfData.perceptualRoughness);
    float G = GeometrySmith(N, V, L, brdfData.perceptualRoughness);
    float3 F = FresnelSchlick(max(dot(H, V), 0.0), brdfData.specular);
    // 计算镜面反射BRDF
    float3 numerator = NDF * G * F;
    float denominator = 4.0 * NdotV * NdotL;
    float3 specular = numerator / max(denominator,EPSILON);

    lightingresult.directSpecular = specular * radiance;

    #if defined(_FOLIAGE) || defined(_ICE)
        half Wrap = 0.5;
        half WrapNoL = saturate((-dot(N,L) + Wrap) / pow(1+Wrap ,2));
    
        half VoL = dot(V,L);
        float Scatter = D_GGX(saturate(-VoL),0.6 * 0.6);
        half3 transmition = light.color * light.shadowAttenuation * WrapNoL * Scatter * surface_data.scaterringColor;
        lightingresult.directDiffuse += transmition;
    #endif

    // #if defined(_ICE)
    //     half Opacity = surface_data.thickness;
    //     half InScatter = pow(saturate(dot(L, -V)), 12) * lerp(3, 0.1f, Opacity);
    //     const half WrappedDiffuse = pow(saturate(dot(N, L) * (1.f / 1.5f) + (0.5f / 1.5f)), 1.5f) * (2.5f / 1.5f);
    //     const half NormalContribution = lerp(1.f, WrappedDiffuse, Opacity);
    //     const half BackScatter = surface_data.occlusion * NormalContribution / (PI * 2);
    //     lightingresult.directDiffuse += lerp(BackScatter, 1, InScatter) * light.color * light.shadowAttenuation * surface_data.scaterringColor;
    //
    //     lightingresult.directSpecular *= surface_data.specularScale;
    // #endif

    #if defined(_WATER)
    
        float3 R = reflect(V,N);
        half3 scatter = SchlickPhase(0.5,dot(-light.direction,R)) * surface_data.scaterringColor;
        lightingresult.directDiffuse += light.color * light.shadowAttenuation * scatter;
    
    #endif

    
    
}

void IndirectLighting(BRDFData brdfData,half occlusion,half3 normalWS, half3 viewDir,SurfaceData surface_data,inout LightingResult lightingresult)
{
    half3 reflectVector = reflect(-viewDir,normalWS);
    half NoV = saturate(dot(normalWS,viewDir));
    lightingresult.indirectDiffuse = SampleSH(normalWS) * brdfData.diffuse * occlusion;
    
    #if defined(_FOLIAGE) || defined(_ICE)
        lightingresult.indirectDiffuse +=   SampleSH(-normalWS) * surface_data.scaterringColor * occlusion;
    #endif

    half3 indirectSpecular = GlossyEnvironmentReflection(reflectVector,brdfData.perceptualRoughness,occlusion);
    #if defined(_WATER)
        indirectSpecular = surface_data.reflectionColor;
    #endif


    indirectSpecular *= EnvBRDFApprox(brdfData.specular,brdfData.perceptualRoughness,NoV);
    lightingresult.indirectSpecular = indirectSpecular;
}

half4 StandardLighting(InputData inputData,SurfaceData surfacedata)
{
    Light light = GetMainLight();
    BRDFData brdfData;
    LightingResult lighting_result = (LightingResult)0;

    InitializeBRDFData(surfacedata,brdfData);
    half4 shadowMask = CalculateShadowMask(inputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData,surfacedata);

    DirectLighting(brdfData,light,inputData.normalWS,inputData.viewDirectionWS,surfacedata,lighting_result);
    IndirectLighting(brdfData,surfacedata.occlusion,inputData.normalWS,inputData.viewDirectionWS,surfacedata,lighting_result);

    half3 color = lighting_result.directDiffuse + lighting_result.directSpecular + lighting_result.indirectDiffuse + lighting_result.indirectSpecular + surfacedata.emission;
    return half4(color,surfacedata.alpha);
}