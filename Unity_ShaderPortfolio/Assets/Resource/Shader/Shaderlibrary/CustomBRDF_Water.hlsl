#ifndef CUSTOM_BRDF_WATER_INCLUDED
#define CUSTOM_BRDF_WATER_INCLUDED

struct WaterBRDFData
{
    half3 diffuse;
    half3 specular;
    half  perceptualRoughness;
};

struct WaterLightingResult
{
    half3 directDiffuse;
    half3 directSpecular;
    half3 indirectDiffuse;
    half3 indirectSpecular;
};

inline half DistributionGGX_Water(half3 N, half3 H, half roughness)
{
    half a  = max(roughness * roughness, 0.02h);
    half a2 = a * a;

    half NdotH  = saturate(dot(N, H));
    half NdotH2 = NdotH * NdotH;

    half denom = (NdotH2 * (a2 - 1.0h) + 1.0h);
    denom = PI * denom * denom;

    return a2 / max(denom, 0.0001h);
}

inline half GeometrySchlickGGX_Water(half NdotX, half roughness)
{
    half r = roughness + 1.0h;
    half k = (r * r) / 8.0h;
    return NdotX / (NdotX * (1.0h - k) + k);
}

inline half GeometrySmith_Water(half3 N, half3 V, half3 L, half roughness)
{
    half NdotV = saturate(dot(N, V));
    half NdotL = saturate(dot(N, L));
    half gV = GeometrySchlickGGX_Water(NdotV, roughness);
    half gL = GeometrySchlickGGX_Water(NdotL, roughness);
    return gV * gL;
}

inline half3 FresnelSchlick_Water(half cosTheta, half3 F0)
{
    half oneMinusCos = 1.0h - cosTheta;
    half factor = oneMinusCos * oneMinusCos * oneMinusCos * oneMinusCos * oneMinusCos;
    return F0 + (1.0h - F0) * factor;
}

inline half3 EnvBRDFApprox_Water(half3 specularColor, half roughness, half NoV)
{
    const half4 c0 = half4(-1.0h, -0.0275h, -0.572h, 0.022h);
    const half4 c1 = half4( 1.0h,  0.0425h,  1.04h, -0.04h);

    half4 r = roughness * c0 + c1;

    half a004 = min(r.x * r.x, exp2(-9.28h * NoV)) * r.x + r.y;
    half2 AB = half2(-1.04h, 1.04h) * a004 + r.zw;

    return specularColor * AB.x + AB.y;
}

inline void InitializeWaterBRDFData(half3 albedo, half metallic, half roughness, out WaterBRDFData brdfData)
{
    brdfData.perceptualRoughness = saturate(roughness);

    half oneMinusMetallic = 1.0h - metallic;
    brdfData.diffuse = albedo * oneMinusMetallic;

    half3 dielectricF0 = half3(0.02h, 0.02h, 0.02h);
    brdfData.specular = lerp(dielectricF0, albedo, metallic);
}

inline void WaterDirectLighting(
    WaterBRDFData brdfData,
    Light light,
    half3 N,
    half3 V,
    half3 scatteringColor,
    inout WaterLightingResult lighting)
{
    half3 L = normalize(light.direction);
    half3 H = normalize(L + V);

    half NdotL = saturate(dot(N, L));
    if (NdotL <= 0.0h)
        return;

    half3 radiance = light.color * light.shadowAttenuation * NdotL;

    lighting.directDiffuse += radiance * brdfData.diffuse / PI;

    half NdotV = saturate(dot(N, V));
    half D = DistributionGGX_Water(N, H, brdfData.perceptualRoughness);
    half G = GeometrySmith_Water(N, V, L, brdfData.perceptualRoughness);
    half3 F = FresnelSchlick_Water(saturate(dot(H, V)), brdfData.specular);

    half denom = max(4.0h * NdotL * NdotV, 0.0001h);
    half3 specular = (D * G * F) / denom;
    lighting.directSpecular += specular * radiance;

    half VoL = dot(V, L);
    half forwardScatter = saturate(1.0h - abs(VoL));
    lighting.directDiffuse += radiance * scatteringColor * forwardScatter * 0.2h;
}

inline void WaterIndirectLighting(
    WaterBRDFData brdfData,
    half3 N,
    half3 V,
    half occlusion,
    half3 scatteringColor,
    half3 reflectionColor,
    inout WaterLightingResult lighting)
{
    lighting.indirectDiffuse += SampleSH(N) * brdfData.diffuse * occlusion;

    half3 R = reflect(-V, N);
    half3 envSpec = GlossyEnvironmentReflection(R, brdfData.perceptualRoughness, occlusion);

    envSpec *= reflectionColor;

    half NoV = saturate(dot(N, V));
    envSpec *= EnvBRDFApprox_Water(brdfData.specular, brdfData.perceptualRoughness, NoV);

    lighting.indirectSpecular += envSpec;

    lighting.indirectDiffuse += scatteringColor * 0.05h;
}

inline half3 EvaluateWaterLighting(
    float3 positionWS,
    half3 normalWS,
    half3 viewDirWS,
    half3 albedo,
    half metallic,
    half roughness,
    half occlusion,
    half3 scatteringColor,
    half3 reflectionColor)
{
    normalWS = normalize(normalWS);
    half3 V = normalize(viewDirWS);

    WaterBRDFData brdfData;
    InitializeWaterBRDFData(albedo, metallic, roughness, brdfData);

    WaterLightingResult lighting = (WaterLightingResult)0;

    Light mainLight = GetMainLight();
    WaterDirectLighting(brdfData, mainLight, normalWS, V, scatteringColor, lighting);

    #if defined(_ADDITIONAL_LIGHTS)
    uint additionalCount = GetAdditionalLightsCount();
    for (uint i = 0u; i < additionalCount; i++)
    {
        Light light = GetAdditionalLight(i, positionWS);
        WaterDirectLighting(brdfData, light, normalWS, V, scatteringColor, lighting);
    }
    #endif

    WaterIndirectLighting(brdfData, normalWS, V, occlusion, scatteringColor, reflectionColor, lighting);

    return lighting.directDiffuse + lighting.directSpecular +
           lighting.indirectDiffuse + lighting.indirectSpecular;
}

#endif // CUSTOM_BRDF_WATER_INCLUDED
