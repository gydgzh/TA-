#ifndef CUSTOM_SHADING_MODELS4_MY_INCLUDED
#define CUSTOM_SHADING_MODELS4_MY_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

// 先 include 自己的 SurfaceData，避免 URP 重复定义
#include "Assets/Resource/Shader/ShaderLibrary/SurfaceData.hlsl"

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Assets/Resource/Shader/ShaderLibrary/CustomBRDF.hlsl"

struct LightingResult
{
    half3 directDiffuse;
    half3 directSpecular;
    half3 ambientDiffuse;
    half3 ambientSpecular;
};

#define EPSILON 1e-6

inline float D_GGX_MY(float NoH, float roughness)
{
    NoH = saturate(NoH);
    roughness = max(roughness, 0.001);

    float a = roughness * roughness;
    float a2 = a * a;
    float d = NoH * NoH * (a2 - 1.0) + 1.0;

    return a2 / max(PI * d * d, 1e-6);
}

inline half D_GGX_MY(half NoH, half roughness)
{
    NoH = saturate(NoH);
    roughness = max(roughness, (half)0.001);

    half a = roughness * roughness;
    half a2 = a * a;
    half d = NoH * NoH * (a2 - (half)1.0) + (half)1.0;

    return a2 / max((half)PI * d * d, (half)1e-4);
}

void DirectLighting(
    BRDFData brdfData,
    Light light,
    half3 normalWS,
    half3 viewDirectionWS,
    SurfaceData surface_data,
    inout LightingResult lightingresult)
{
    half NdotL = saturate(dot(normalWS, light.direction));
    half3 radiance = light.color * (light.shadowAttenuation * NdotL);

    lightingresult.directDiffuse = radiance * brdfData.diffuse / PI;

    half3 V = viewDirectionWS;
    half3 L = light.direction;
    half3 N = normalWS;

    float NdotV = max(dot(N, V), EPSILON);
    float3 H = normalize(V + L);

    half _NoL = dot(N, L);
    half NoH  = saturate(dot(N, H));
    half NoV  = saturate(dot(N, V));
    half VoH  = saturate(dot(V, H));

#ifndef _SPECULARHIGHLIGHTS_OFF
    brdfData.perceptualRoughness = max(0.08, min(0.99, brdfData.perceptualRoughness));

    float NDF = DistributionGGX(N, H, brdfData.perceptualRoughness);
    float G   = GeometrySmith(N, V, L, brdfData.perceptualRoughness);
    float3 F  = FresnelSchlick(max(dot(H, V), 0.0), brdfData.specular);

    float3 numerator   = NDF * G * F;
    float  denominator = 4.0 * NdotV * max(NdotL, EPSILON);
    float3 specular    = numerator / max(denominator, EPSILON);

    lightingresult.directSpecular += specular * radiance;

#ifdef _SILK
    half3 X = normalize(surface_data.tangentWS);
    half3 Y = normalize(cross(N, X));

    half XoH = dot(X, H);
    half YoH = dot(Y, H);
    half XoV = dot(X, V);
    half XoL = dot(X, L);
    half YoV = dot(Y, V);
    half YoL = dot(Y, L);

    specular = SpecularGGX_Aniso(
        NoH, VoH, NoV, _NoL,
        brdfData.specular,
        brdfData.perceptualRoughness,
        surface_data.aniso,
        XoH, YoH, XoV, XoL, YoV, YoL);

    lightingresult.directSpecular += specular * radiance;
#endif
#endif // _SPECULARHIGHLIGHTS_OFF

#if defined(_WATER)
    half sss = (half)CalculateSSSColor(L, N, V);
    lightingresult.directDiffuse += light.color * light.shadowAttenuation * (sss * surface_data.scaterringColor.rgb);
#endif

#if defined(_FOLIAGE) || defined(_ICE)
    half Wrap = 0.5;
    half WrapNoL = saturate((-dot(N, L) + Wrap) / pow(1 + Wrap, 2));

    half VoL = dot(V, L);

    float Scatter = D_GGX_MY(saturate(-VoL), 0.6 * 0.6);

    half3 transmission =
        light.color * light.shadowAttenuation *
        WrapNoL * Scatter *
        surface_data.scaterringColor.rgb;

    lightingresult.directDiffuse += transmission;
#endif
}

void IndirectLight(
    BRDFData brdfData,
    half occlusion,
    half3 normalWS,
    half3 viewDirectionWS,
    SurfaceData surface_data,
    inout LightingResult lightingresult)
{
    half3 reflectVector = reflect(-viewDirectionWS, normalWS);
    half NoV = saturate(dot(normalWS, viewDirectionWS));

    lightingresult.ambientDiffuse = SampleSH(normalWS) * brdfData.diffuse * occlusion;

#if defined(_FOLIAGE) || defined(_ICE)
    lightingresult.ambientDiffuse += SampleSH(-normalWS) * surface_data.scaterringColor.rgb * occlusion;
#endif

    half3 indirectSpecular = GlossyEnvironmentReflection(reflectVector, brdfData.perceptualRoughness, occlusion);

#if defined(_WATER)
    indirectSpecular = surface_data.reflectionColor.rgb;
#endif

    indirectSpecular *= EnvBRDFApprox(brdfData.specular, brdfData.perceptualRoughness, NoV);
    lightingresult.ambientSpecular = indirectSpecular;
}

half4 StandardLighting(InputData inputData, SurfaceData surfaceData)
{
    BRDFData brdfData;
    LightingResult Lightingresult = (LightingResult)0;

    InitializeBRDFData(surfaceData, brdfData);

    half4 shadowMask = CalculateShadowMask(inputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
    Light mainlight = GetMainLight(inputData, shadowMask, aoFactor);

    DirectLighting(brdfData, mainlight, inputData.normalWS, inputData.viewDirectionWS, surfaceData, Lightingresult);
    IndirectLight(brdfData, surfaceData.occlusion, inputData.normalWS, inputData.viewDirectionWS, surfaceData, Lightingresult);

#if defined(_ADDITIONAL_LIGHTS)
    uint pixelLightCount = GetAdditionalLightsCount();

#ifdef _LIGHT_LAYERS
    uint meshRenderingLayers = GetMeshRenderingLayer();
#endif

#if USE_FORWARD_PLUS
    for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
    {
        FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

#ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
        {
            DirectLighting(brdfData, light, inputData.normalWS, inputData.viewDirectionWS, surfaceData, Lightingresult);
        }
    }
#endif

    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

#ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
        {
            DirectLighting(brdfData, light, inputData.normalWS, inputData.viewDirectionWS, surfaceData, Lightingresult);
        }
    LIGHT_LOOP_END
#endif

    half3 color =
        Lightingresult.ambientDiffuse +
        Lightingresult.ambientSpecular +
        Lightingresult.directSpecular +
        Lightingresult.directDiffuse +
        surfaceData.emission;

    return half4(color, surfaceData.alpha);
}

#endif // CUSTOM_SHADING_MODELS4_MY_INCLUDED