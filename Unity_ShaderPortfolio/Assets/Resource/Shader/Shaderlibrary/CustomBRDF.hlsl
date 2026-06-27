#define PI 3.14159265359
#define EPS 0.00001

float Pow5(float v)
{
    return pow(1 - v, 5);
}

float CalculateSSSColor(float3 lightDirection, float3 worldNormal, float3 viewDir){
    float lightStrength = sqrt(saturate(lightDirection.y));
    float SSSFactor = pow(saturate(dot(worldNormal ,-lightDirection)) ,5) * lightStrength;
    return  (SSSFactor);
}


// Fresnel functions

float3 fresnel(float3 F0, float NdotV)
{
    return F0 + (1 - F0) * Pow5(NdotV);
}

float3 fresnel(float3 F0, float NdotV, float roughness)
{
    return F0 + (max(1.0 - roughness, F0) - F0) * Pow5(NdotV);
}

half SchlickPhase(float k, float costh)
{
    return (1.0 - k * k) / (12.56637 * pow(1.0 - k * costh, 2.0));
}

float3 Diffuse_Burley( float3 DiffuseColor, float Roughness, float NoV, float NoL, float VoH )
{
    float FD90 = 0.5 + 2 * VoH * VoH * Roughness;
    float FdV = 1 + (FD90 - 1) * Pow5( 1 - NoV );
    float FdL = 1 + (FD90 - 1) * Pow5( 1 - NoL );
    return DiffuseColor * ( (1 / PI) * FdV * FdL );
}

float3 F0(float ior)
{
    return pow((1.0 - ior) / (1.0 + ior), 2);
}
// Geometric attenuation functions

float cookTorranceGAF(float NdotH, float NdotV, float HdotV, float NdotL)
{
    float firstTerm = 2 * NdotH * NdotV / HdotV;
    float secondTerm = 2 * NdotH * NdotL / HdotV;
    return min(1, min(firstTerm, secondTerm));
}

float schlickBeckmannGAF(float dotProduct, float roughness)
{
    float alpha = roughness * roughness;
    float k = alpha * 0.797884560803;  // sqrt(2 / PI)
    return dotProduct / (dotProduct * (1 - k) + k);
}

// 优化后的Trowbridge-Reitz GGX法线分布函数
float DistributionGGX(float3 N, float3 H, float roughness)
{
    float a = roughness * roughness;
    float a2 = a * a;
    float NdotH = max(dot(N, H), 0.0);
    float NdotH2 = NdotH * NdotH;
                
    // 使用更稳定的分母计算
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom + 0.00001;
                
    return a2 / denom;
}
// Schlick-GGX几何遮挡函数（Smith模型）
float GeometrySchlickGGX(float NdotV, float roughness)
{
    // 使用重映射粗糙度来减少高光锯齿
    float r = roughness + 1.0;
    float k = (r * r) / 8.0;
                
    float denom = NdotV * (1.0 - k) + k;
    return NdotV / denom;
}

// 完整Smith几何函数
float GeometrySmith(float3 N, float3 V, float3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.00001);
    float NdotL = max(dot(N, L), 0.00001);
                
    float ggx1 = GeometrySchlickGGX(NdotL, roughness);
    float ggx2 = GeometrySchlickGGX(NdotV, roughness);
                
    return ggx1 * ggx2;
}

// Fresnel-Schlick近似（优化版本）
float3 FresnelSchlick(float cosTheta, float3 F0)
{
    // 使用更快的指数计算
    float pow5 = pow(1.0 - cosTheta, 5.0);
    return F0 + (1.0 - F0) * pow5;
}

float D_GGXaniso( float ax, float ay, float NoH, float XoH, float YoH )
{
    // The two formulations are mathematically equivalent
    float a2 = ax * ay;
    float3 V = float3(ay * XoH, ax * YoH, a2 * NoH);
    float S = dot(V, V);
    return (1.0f / PI) * a2 * pow((a2 / S),2);

}

float Vis_SmithJointAniso(float ax, float ay, float NoV, float NoL, float XoV, float XoL, float YoV, float YoL)
{
    float Vis_SmithV = NoL * length(float3(ax * XoV, ay * YoV, NoV));
    float Vis_SmithL = NoV * length(float3(ax * XoL, ay * YoL, NoL));
    return 0.5 * rcp(Vis_SmithV + Vis_SmithL);
}


half3 SpecularGGX_Aniso( in half NoH, in half VoH, in half NoV, in half NoL, in half3 SpecularColor, in half Roughness,float Anisotropy,
    float XoH,float YoH,float XoV,float XoL,float YoV,float YoL)
{
    float Alpha = Roughness * Roughness;
    float ax = max(Alpha * (1.0f + Anisotropy), 0.001f);
    float ay = max(Alpha * (1.0f - Anisotropy), 0.001f);
    float D = D_GGXaniso( ax,ay,NoH,XoH,YoH);
    float  G = Vis_SmithJointAniso( ax,ay,NoV,NoL,XoV,XoL,YoV,YoL);
    float3 F = F_Schlick( SpecularColor, VoH );
    return (D * G) * F;
}


// Normal distribution functions
float3 FresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
{
    return F0 + (max(float3(1.0 - roughness, 1.0 - roughness, 1.0 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
}


half3 EnvBRDFApprox( half3 SpecularColor, half Roughness, half NoV )
{
    const half4 c0 = { -1, -0.0275, -0.572, 0.022 };
    const half4 c1 = { 1, 0.0425, 1.04, -0.04 };
    half4 r = Roughness * c0 + c1;
    half a004 = min(r.x * r.x, exp2(-9.28 * NoV)) * r.x + r.y;
    half2 AB = half2(-1.04, 1.04) * a004 + r.zw;
    // Anything less than 2% is physically impossible and is instead considered to be shadowing
    // Note: this is needed for the 'specular' show flag to work, since it uses a SpecularColor of 0
    float F90 = saturate( 50.0 * SpecularColor.g );

    return SpecularColor * AB.x + F90 * AB.y;
}

