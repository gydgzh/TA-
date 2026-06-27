Shader "Custom/LocalVolumeFog3DNoise"
{
    Properties
    {
        _FogColor ("Fog Color", Color) = (0.5, 0.6, 0.7, 1.0)
        _FogDensity ("Fog Density", Range(0, 10)) = 1.0
        _Noise3D ("3D Noise Texture", 3D) = "white" {}
        _NoiseScale ("Noise Scale", Range(0.01, 10)) = 1.0
        _NoiseStrength ("Noise Strength", Range(0, 1)) = 0.5
        _NoiseSpeed ("Noise Speed", Vector) = (0.1, 0.2, 0.3, 0)
        _MaxSteps ("Max Steps", Range(1, 256)) = 64
        _StepSize ("Step Size", Range(0.01, 1)) = 0.1
        _FadeDistance ("Fade Distance", Range(0, 10)) = 1.0
        _HeightGradient ("Height Gradient", Range(0, 10)) = 1.0
        [Toggle] _UseHeightGradient ("Use Height Gradient", Float) = 1
        [Toggle] _UseWorldSpace ("Use World Space", Float) = 1
    }
    
    SubShader
    {
        Tags { 
            "RenderType"="Transparent" 
            "Queue"="Transparent"
            "RenderPipeline" = "UniversalPipeline"
            "IgnoreProjector" = "True"
        }
        LOD 100
        
        Pass
        {
            Name "LocalVolumeFog"
            Tags { "LightMode" = "UniversalForward" }
            
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Back
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            
            // 属性
            float4 _FogColor;
            float _FogDensity;
            float _NoiseScale;
            float _NoiseStrength;
            float4 _NoiseSpeed;
            int _MaxSteps;
            float _StepSize;
            float _FadeDistance;
            float _HeightGradient;
            float _UseHeightGradient;
            float _UseWorldSpace;
            
            // 3D 噪声纹理
            TEXTURE3D(_Noise3D);
            SAMPLER(sampler_Noise3D);
            
            // 采样 3D 噪声
            float sampleNoise3D(float3 position)
            {
                // 应用缩放和时间偏移
                float3 samplePos = position * _NoiseScale + _NoiseSpeed.xyz * _Time.y;
                return SAMPLE_TEXTURE3D(_Noise3D, sampler_Noise3D, samplePos).r;
            }
            
            // 雾密度函数
            float fogDensity(float3 pos, float3 boundsMin, float3 boundsMax)
            {
                // 计算到边界框边缘的距离
                float3 distToEdge = min(pos - boundsMin, boundsMax - pos);
                float edgeFactor = min(min(distToEdge.x, distToEdge.y), distToEdge.z);
                
                // 边缘淡化
                float fade = smoothstep(0, _FadeDistance, edgeFactor);
                
                // 高度梯度
                float heightFactor = 1.0;
                if (_UseHeightGradient > 0.5)
                {
                    float normalizedHeight = (pos.y - boundsMin.y) / (boundsMax.y - boundsMin.y);
                    heightFactor = 1.0 - exp(-_HeightGradient * normalizedHeight);
                }
                
                // 采样 3D 噪声
                float3 noisePos = _UseWorldSpace > 0.5 ? pos : (pos - boundsMin) / (boundsMax - boundsMin);
                float noiseValue = sampleNoise3D(noisePos) * _NoiseStrength;
                
                return _FogDensity * fade * heightFactor * (1.0 + noiseValue);
            }
            
            // 计算射线与AABB的交点
            bool rayAABBIntersection(float3 rayOrigin, float3 rayDir, float3 boundsMin, float3 boundsMax, 
                                    out float tMin, out float tMax)
            {
                float3 invRayDir = 1.0 / rayDir;
                
                float3 t1 = (boundsMin - rayOrigin) * invRayDir;
                float3 t2 = (boundsMax - rayOrigin) * invRayDir;
                
                float3 tMin3 = min(t1, t2);
                float3 tMax3 = max(t1, t2);
                
                tMin = max(max(tMin3.x, tMin3.y), tMin3.z);
                tMax = min(min(tMax3.x, tMax3.y), tMax3.z);
                
                return tMax >= tMin && tMax > 0;
            }
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };
            
            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 viewDirWS : TEXCOORD1;
            };
            
            Varyings vert(Attributes input)
            {
                Varyings output;
                
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                
                // 计算视图方向
                float3 worldSpaceCameraPos = _WorldSpaceCameraPos;
                output.viewDirWS = normalize(output.positionWS - worldSpaceCameraPos);
                
                return output;
            }
            
            half4 frag(Varyings input) : SV_Target
            {
                // 获取对象边界（在对象空间中是-0.5到0.5的立方体）
                float3 boundsMinOS = float3(-0.5, -0.5, -0.5);
                float3 boundsMaxOS = float3(0.5, 0.5, 0.5);
                
                // 转换边界到世界空间
                float4x4 objectToWorld = GetObjectToWorldMatrix();
                float3 boundsMinWS = mul(objectToWorld, float4(boundsMinOS, 1.0)).xyz;
                float3 boundsMaxWS = mul(objectToWorld, float4(boundsMaxOS, 1.0)).xyz;
                
                // 射线参数
                float3 rayOrigin = _WorldSpaceCameraPos;
                float3 rayDir = normalize(input.positionWS - _WorldSpaceCameraPos);
                
                // 计算射线与边界框的交点
                float tMin, tMax;
                bool intersect = rayAABBIntersection(rayOrigin, rayDir, boundsMinWS, boundsMaxWS, tMin, tMax);
                
                if (!intersect || tMax < 0)
                {
                    // 射线没有与边界框相交或相机在边界框内
                    discard;
                    return half4(0, 0, 0, 0);
                }
                
                // 确保tMin不小于0（如果相机在边界框内）
                tMin = max(0, tMin);
                
                // 初始化Raymarching
                float3 entryPoint = rayOrigin + rayDir * tMin;
                float3 exitPoint = rayOrigin + rayDir * tMax;
                float rayLength = distance(exitPoint, entryPoint);
                
                float stepSize = _StepSize;
                int numSteps = (int)min(_MaxSteps, rayLength / stepSize);
                stepSize = rayLength / numSteps;
                
                float3 currentPos = entryPoint;
                float opticalDepth = 0.0;

                [unroll(64)]
                // Raymarching循环
                for (int i = 0; i < numSteps; i++)
                {
                    float density = fogDensity(currentPos, boundsMinWS, boundsMaxWS) * stepSize;
                    opticalDepth += density;
                    
                    currentPos += rayDir * stepSize;
                    
                    // 提前退出优化
                    if (opticalDepth > 10.0) break;
                }
                
                // 计算雾的透明度
                float transparency = exp(-opticalDepth);
                float alpha = 1.0 - transparency;
                
                // 最终颜色
                half3 finalColor = _FogColor.rgb;
                
                return half4(finalColor, alpha);
            }
            ENDHLSL
        }
        
        // 阴影投射Pass（可选）
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            
            ColorMask 0
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            struct Attributes
            {
                float4 positionOS : POSITION;
            };
            
            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
            };
            
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                return output;
            }
            
            half4 frag(Varyings input) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }
    }
    
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "UnityEditor.Rendering.Universal.ShaderGUI.CustomShaderGUI"
}