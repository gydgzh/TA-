#ifndef COMMON_BRDF2_INCLUDED
#define COMMON_BRDF2_INCLUDED

#ifndef PI
    #define PI 3.14159265359
#endif

// ---------- GGX D ----------
inline half D_GGX_TR(half3 N, half3 H, half roughness)
{
    half a  = max(roughness, 0.02h);
    half a2 = a * a;

    half NdotH  = saturate(dot(N, H));
    half NdotH2 = NdotH * NdotH;

    half denom = (NdotH2 * (a2 - 1.0h) + 1.0h);
    denom = PI * denom * denom;

    return a2 / max(denom, 0.0001h);
}

// ---------- G ----------
inline half GeometrySchlickGGX(half NdotX, half roughness)
{
    half r = roughness + 1.0h;
    half k = (r * r) / 8.0h;
    return NdotX / (NdotX * (1.0h - k) + k);
}

inline half GeometrySmith2(half3 N, half3 V, half3 L, half roughness)
{
    half NdotV = saturate(dot(N, V));
    half NdotL = saturate(dot(N, L));
    half gV = GeometrySchlickGGX(NdotV, roughness);
    half gL = GeometrySchlickGGX(NdotL, roughness);
    return gV * gL;
}

// ---------- F ----------
inline half3 FresnelSchlick(half cosTheta, half3 F0)
{
    half oneMinusCos = 1.0h - cosTheta;
    half factor = oneMinusCos * oneMinusCos * oneMinusCos * oneMinusCos * oneMinusCos;
    return F0 + (1.0h - F0) * factor;
}

// ---------- 环境反射采样 ----------
inline half3 GlossyEnvironmentReflection(
    TEXTURECUBE_PARAM(envTex, envSampler),
    half3 reflectVector,
    half perceptualRoughness,
    half occlusion
)
{
    const half mipCount = 6.0h;
    half mip = saturate(perceptualRoughness) * (mipCount - 1.0h);

    half4 envSample = SAMPLE_TEXTURECUBE_LOD(envTex, envSampler, reflectVector, mip);
    half3 envColor  = envSample.rgb;
    return envColor * occlusion;
}

// ---------- 环境 BRDF 近似 ----------
inline half3 EnvBRDFApprox(half3 SpecularColor, half Roughness, half NoV)
{
    const half4 c0 = half4(-1.0h, -0.0275h, -0.572h, 0.022h);
    const half4 c1 = half4( 1.0h,  0.0425h,  1.040h, -0.040h);

    half4 r = Roughness * c0 + c1;

    half a004 = min(r.x * r.x, exp2(-9.28h * NoV)) * r.x + r.y;
    half2 AB  = half2(-1.04h, 1.04h) * a004 + r.zw;

    half F90 = saturate(50.0h * SpecularColor.g);
    return SpecularColor * AB.x + F90 * AB.y;
}

#endif // COMMON_BRDF2_INCLUDED

