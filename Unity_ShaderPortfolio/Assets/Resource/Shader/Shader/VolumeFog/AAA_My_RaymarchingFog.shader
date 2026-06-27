Shader "Custom/Unlit/RaymarchingFog_my"
{
    Properties
    {
        _FogColor ("Fog Color", Color) = (0.5, 0.6, 0.7, 1.0)
        _FogDensity ("Fog Density", Range(0,5)) = 1.0                // [修改] 补上 Fog Density 属性
        _StepSize ("Step Size", Range(0.01, 1)) = 0.1               // 步长-控制的参数
        _FadeDistance ("Fade Distance", Range(0, 10)) = 1.0
        _HeightGradient ("Height Gradient", Range(0, 10)) = 1.0     // 指数的雾的参数
        _Noise3D ("3D Noise Texture", 3D) = "white" {}
        _NoiseScale ("Noise Scale", Range(0.01, 10)) = 1.0
        _NoiseStrength ("Noise Strength", Range(0, 1)) = 0.5
        _NoiseSpeed ("Noise Speed", Vector) = (0.1, 0.2, 0.3, 0)//扰动
        _MaxSteps ("Max Steps", Range(1, 256)) = 64
        [Toggle] _UseHeightGradient ("Use Height Gradient", Float) = 1
        [Toggle] _UseWorldSpace ("Use World Space", Float) = 1
    }

    SubShader
    {
        Tags
        {
            "RenderType"="Transparent" 
            "Queue"="Transparent"
            "RenderPipeline" = "UniversalPipeline"
            "IgnoreProjector" = "True"
        }
        LOD 100

        Pass
        {
            Name "RaymarchingFog_my"//这个命名要和上面一致吗？这个是控制unity里那一部分的命名
            Tags { "LightMode" = "UniversalForward" }
            
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Back
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
             
            // --------- 材质属性（放到 UnityPerMaterial CBUFFER 里）---------
            // [修改]：放进 CBUFFER，保证 Inspector 里的值正确传进来
            CBUFFER_START(UnityPerMaterial)
                float4 _FogColor;
                float  _FogDensity;
                float  _NoiseScale;
                float  _NoiseStrength;
                float4 _NoiseSpeed;
                int    _MaxSteps;
                float  _StepSize;
                float  _FadeDistance;
                float  _HeightGradient;
                float  _UseHeightGradient;
                float  _UseWorldSpace;
            CBUFFER_END
            
            // 3D 噪声纹理
            TEXTURE3D(_Noise3D);
            SAMPLER(sampler_Noise3D);
            
            struct Attributes//读顶点数据
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };
            
            //体积云布尔函数
            // 计算射线与AABB的交点-矩形和boundingbox求交的算法
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
            
            //3D 噪声采样函数
            // 采样 3D 噪声
            float sampleNoise3D(float3 position)
            {
                // 应用缩放和时间偏移
                float3 samplePos = position * _NoiseScale + _NoiseSpeed.xyz * _Time.y;//_NoiseScale加一个扰动，一些基于时间的变化
                return SAMPLE_TEXTURE3D(_Noise3D, sampler_Noise3D, samplePos).r;
            }
            
            //计算雾函数的密度（用世界空间计算，更直观）
            // posWS: 当前采样点世界坐标
            half fogDensity(float3 posWS, float3 boundsMinWS, float3 boundsMaxWS)
            {
                float3 distToEdge = min(posWS - boundsMinWS, boundsMaxWS - posWS);
                //边缘衰减
                float edgeFactor = min(min(distToEdge.x, distToEdge.y), distToEdge.z);
                
                // 边缘淡化
                float fade = smoothstep(0, _FadeDistance, edgeFactor);//smoothstep是非线性的有层次感
                //float fade = lerp(0,1,edgeFactor);
                // 高度梯度
                float heightFactor = 1.0;
                // [修改]：只有勾选 UseHeightGradient 时才计算高度
                if (_UseHeightGradient > 0.5)
                {
                    float heightRange = max(boundsMaxWS.y - boundsMinWS.y, 1e-3);
                    float normalizedHeight = (posWS.y - boundsMinWS.y) / heightRange;//得到高度
                    heightFactor = 1.0 - exp(-_HeightGradient * normalizedHeight);
                }
                 
                // 采样 3D 噪声
                float3 noisePos = (_UseWorldSpace > 0.5)
                                  ? posWS
                                  : (posWS - boundsMinWS) / max(boundsMaxWS - boundsMinWS, 1e-3);
                float noiseValue = sampleNoise3D(noisePos);
                // 用 _NoiseStrength 控制噪声影响
                noiseValue = lerp(0.0, noiseValue, _NoiseStrength);
                
                return _FogDensity * fade * heightFactor * (1.0 + noiseValue);
            }
            
            struct Varyings//顶点数据传给片元着色器数据
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS  : TEXCOORD0;
                float3 viewDirWS   : TEXCOORD1;
            };
            
            //vert 决定“这个点在屏幕哪里 + 传什么数据”
            Varyings vert(Attributes input)
            {
                Varyings output;
                
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionWS  = TransformObjectToWorld(input.positionOS.xyz);
                
                // 计算视图方向
                float3 worldSpaceCameraPos = _WorldSpaceCameraPos;
                output.viewDirWS = normalize(output.positionWS - worldSpaceCameraPos);
                
                return output;
            }
            
            //frag 决定“这个像素显示什么颜色”
            half4 frag (Varyings input) : SV_Target
            {
                // 在对象空间中定义一个立方体 [-0.5, 0.5]^3
                float3 boundsMinOS = float3(-0.5, -0.5, -0.5);
                float3 boundsMaxOS = float3( 0.5,  0.5,  0.5);
                
                // [修改]：在对象空间做射线求交，避免 Cube 上 AABB 计算出错
                float3 rayOriginWS = _WorldSpaceCameraPos; // 相机世界空间
                float3 rayDirWS    = normalize(input.positionWS - rayOriginWS);

                float4x4 worldToObject = unity_WorldToObject;
                float4x4 objectToWorld = unity_ObjectToWorld;

                float3 rayOriginOS = mul(worldToObject, float4(rayOriginWS, 1.0)).xyz;
                float3 rayDirOS    = normalize(mul((float3x3)worldToObject, rayDirWS));

                float tMin, tMax;
                bool intersect = rayAABBIntersection(rayOriginOS, rayDirOS, boundsMinOS, boundsMaxOS, tMin, tMax);

                // 如果没相交 / 交点都在相机后面，直接丢弃
                if (!intersect || tMax <= 0.0)
                {
                    discard;
                    return half4(0, 0, 0, 0);
                }
                
                tMin = max(0.0, tMin);//不要小于0 ，保护操作
                
                // 初始化 Raymarching（在对象空间里走步进）
                float3 entryPointOS = rayOriginOS + rayDirOS * tMin;
                float3 exitPointOS  = rayOriginOS + rayDirOS * tMax;
                float  rayLength    = distance(exitPointOS, entryPointOS); // 光线在体积中的长度
                
                float  stepSize = _StepSize;
                int    numSteps = (int)min((float)_MaxSteps, max(rayLength / stepSize, 1.0));
                stepSize = rayLength / numSteps;
                
                float3 currentPosOS = entryPointOS;// 光学深度积分起点
                float  opticalDepth = 0.0;

                // 先算一遍世界空间下的包围盒，给 fogDensity 用
                float3 boundsMinWS = mul(objectToWorld, float4(boundsMinOS, 1.0)).xyz;
                float3 boundsMaxWS = mul(objectToWorld, float4(boundsMaxOS, 1.0)).xyz;

                [loop] // [修改]：loop 就够了，不强制 unroll 64
                //[unroll(64)]强制64次循环版本
                for (int i = 0; i < numSteps; i++)
                {
                    float3 currentPosWS = mul(objectToWorld, float4(currentPosOS, 1.0)).xyz;

                    //按密度计算
                    float density = fogDensity(currentPosWS, boundsMinWS, boundsMaxWS) * stepSize;
                    opticalDepth += density;//当前深度
                    
                    currentPosOS += rayDirOS * stepSize;
                    
                    // 提前退出优化（可选）
                    if (opticalDepth > 20.0) break;
                }

                // 计算雾的透明度
                float transparency = exp(-opticalDepth);
                float alpha = saturate(1.0 - transparency);
                
                // 最终颜色
                half3 finalColor = _FogColor.rgb;
                
                return half4(finalColor, alpha);
            }
            
            ENDHLSL
        }
    }
}
