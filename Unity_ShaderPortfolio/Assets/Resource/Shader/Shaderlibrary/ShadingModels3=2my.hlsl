
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
//URP官方基础工具函数，light结构体，InputDate
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Assets/Resource/Shader/ShaderLibrary/CustomBRDF.hlsl"
//自己去文件里看
struct LightingResult//收集光照结果的结构体，定义
{
    half3 directDiffuse;//直射漫反射
    half3 directSpecular;//直射高光
    half3 ambientDiffuse;
    half3 ambientSpecular;
};

#define EPSILON 1e-6
//防止除以一个极小值

void DirectLighting(BRDFData brdfData, Light light, half3 normalWS, 
                    half3 viewDirectionWS, SurfaceData surface_data, 
                    inout LightingResult lightingResult)
{
    half Ndotl = saturate(dot(normalWS, light.direction));
    //计算光线和法线夹角的余弦（N·L），saturate，并且把背面（负数）变成 0，限制在 0~1
    half3 radiance = light.color*(light.shadowAttenuation*Ndotl);
    //light.color-灯光强度RGB
    //light.shadowAttenuation阴影衰减
    lightingResult.directDiffuse = radiance*brdfData.diffuse/PI;
    //Lambert 漫反射 BRDF
}
 