
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
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


void DirectLighting(BRDFData brdfData,Light light,half3 normalWS, half3 viewDirectionWS,SurfaceData surface_data,inout LightingResult lightingresult)
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
    half NoL = saturate(dot(N, L));
    // half VoL = dot(L, V);
    half NoH = saturate(dot(N, H));
    half NoV = saturate(dot(N, V));
    half VoH = saturate(dot(V, H));
    half3 NxH = cross(N, H);

    #ifndef _SPECULARHIGHLIGHTS_OFF
        brdfData.perceptualRoughness =max(0.08,min(0.99,brdfData.perceptualRoughness));
                    
        // 计算BRDF分量
        float NDF = DistributionGGX(N, H, brdfData.perceptualRoughness);
        float G = GeometrySmith(N, V, L, brdfData.perceptualRoughness);
        float3 F = FresnelSchlick(max(dot(H, V), 0.0), brdfData.specular);
        // 计算镜面反射BRDF
        float3 numerator = NDF * G * F;
        float denominator = 4.0 * NdotV * NdotL;
        float3 specular = numerator / max(denominator,EPSILON);
        // lightingresult.directSpecular = brdfData.specular * DirectBRDFSpecular(brdfData, normalWS, light.direction, viewDirectionWS);
    
    
        lightingresult.directSpecular += specular * radiance;

        #ifdef _SILK
            half3 X = normalize(surface_data.tangentWS);
            half3 Y = normalize(cross(N, X));
            float XoV = dot(X,V);
            half XoL = dot(X, L);
            half XoH = (dot(X,H));
            half YoV = dot(Y, V);
            half YoL = dot(Y, L);
            half YoH = (dot(Y, H));

           specular = SpecularGGX_Aniso(NoH, VoH, NoV,_NoL,brdfData.specular ,
                    brdfData.perceptualRoughness,surface_data.aniso, XoH, YoH, XoV, XoL,
                    YoV, YoL);
            lightingresult.directSpecular += specular * radiance;
        #endif

    #endif // _SPECULARHIGHLIGHTS_OFF


    #if defined(_WATER)

    
        half3 scatter = CalculateSSSColor(L,N,V) * surface_data.scaterringColor; ;
    // float3 R = reflect(V,N);
    // half3 scatter = SchlickPhase(0.2,dot(-light.direction,R)) * surface_data.scaterringColor;
    
        lightingresult.directDiffuse += light.color * light.shadowAttenuation * scatter;
    #endif
    


    #if defined(_FOLIAGE) || defined(_ICE)//加一个冰的部分
        half Wrap = 0.5;
        half WrapNoL = saturate((-dot(N,L) + Wrap) / pow(1+Wrap ,2));
    
        half VoL = dot(V,L);
        float Scatter = D_GGX(saturate(-VoL),0.6 * 0.6);
        half3 transmition = light.color * light.shadowAttenuation * WrapNoL * Scatter * surface_data.scaterringColor;
        lightingresult.directDiffuse += transmition;
    #endif
}

void IndirectLight(BRDFData brdfData,half occlusion,half3 normalWS,half3 viewDirectionWS,SurfaceData surface_data,inout LightingResult lightingresult)
{
    half3 reflectVector = reflect(-viewDirectionWS, normalWS);
    
    half NoV = saturate(dot(normalWS, viewDirectionWS));
    
    lightingresult.ambientDiffuse = SampleSH(normalWS) * brdfData.diffuse * occlusion;

    #if defined(_FOLIAGE) || defined(_ICE)
        lightingresult.ambientDiffuse +=  SampleSH(-normalWS) * surface_data.scaterringColor * occlusion;
    #endif

    // #ifdef _SILK
    //
    //     half3 tangentWS = normalize(surface_data.tangentWS);
    //     half3 bitangent = normalize(cross(normalWS,tangentWS));
    //     half3 AnisotropicDir = bitangent;
    //     if(surface_data.aniso < 0)
    //     {
    //         AnisotropicDir = tangentWS;
    //     }
    //
    //     half3 anisotropicTangent = cross(AnisotropicDir,viewDirectionWS);
    //     half3 anisotropicNormal = cross(anisotropicTangent, AnisotropicDir);
    //     half anisotropicStretch = abs(surface_data.aniso) * saturate(5.0f * brdfData.perceptualRoughness);
    //     half3 bentNormal = normalize(lerp(normalWS, anisotropicNormal,anisotropicStretch));
    //     half3 r = reflect(-viewDirectionWS, bentNormal);
    //     reflectVector = r;
    //     brdfData.perceptualRoughness *= saturate(1.2f - abs(surface_data.aniso));
    // #endif
    
    half3 indirectSpecular = GlossyEnvironmentReflection(reflectVector, brdfData.perceptualRoughness, occlusion);
    #if defined(_WATER)
        indirectSpecular = surface_data.reflectionColor;
    #endif

    indirectSpecular *= EnvBRDFApprox(brdfData.specular,brdfData.perceptualRoughness,NoV);
    lightingresult.ambientSpecular = indirectSpecular;
}

half4 StandardLighting(InputData inputData,SurfaceData surfaceData)
{
    BRDFData brdfData;
    LightingResult Lightingresult = (LightingResult) 0;
    
    InitializeBRDFData(surfaceData, brdfData);
    
    half4 shadowMask = CalculateShadowMask(inputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
    Light mainlight = GetMainLight(inputData, shadowMask, aoFactor);
    
    DirectLighting(brdfData,mainlight,inputData.normalWS,inputData.viewDirectionWS,surfaceData,Lightingresult);
    IndirectLight(brdfData,surfaceData.occlusion,inputData.normalWS,inputData.viewDirectionWS,surfaceData,Lightingresult);

    #if defined(_ADDITIONAL_LIGHTS)
    uint pixelLightCount = GetAdditionalLightsCount();

    #if USE_FORWARD_PLUS
        for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
        {
            FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

            Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

            #ifdef _LIGHT_LAYERS
            if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
                #endif
            {
                // lightingData.additionalLightsColor += LightingPhysicallyBased(brdfData, brdfDataClearCoat, light,
                //                                                               inputData.normalWS, inputData.viewDirectionWS,
                //                                                               surfaceData.clearCoatMask, specularHighlightsOff);
                DirectLighting(brdfData,light,inputData.normalWS,inputData.viewDirectionWS,surfaceData,Lightingresult);
            }
        }
    #endif

        LIGHT_LOOP_BEGIN(pixelLightCount)
            Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

        #ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
            #endif
        {
            DirectLighting(brdfData,light,inputData.normalWS,inputData.viewDirectionWS,surfaceData,Lightingresult);
        }
        LIGHT_LOOP_END
    #endif

    #if defined(_ADDITIONAL_LIGHTS_VERTEX)
        lightingData.vertexLightingColor += inputData.vertexLighting * brdfData.diffuse;
    #endif

    half3 color = Lightingresult.ambientDiffuse + Lightingresult.ambientSpecular + Lightingresult.directSpecular + Lightingresult.directDiffuse + surfaceData.emission;
    return half4(color,surfaceData.alpha);
}