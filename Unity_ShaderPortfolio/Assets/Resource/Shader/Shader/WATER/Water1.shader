Shader "Custom/Environment/Water1"
{
    Properties
    {
        _BaseMap   ("BaseMap", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (1,1,1,1)

        _Roughness ("Roughness", Range(0,1)) = 0.06
        _Metallic  ("Metallic",  Range(0,1)) = 0
        _Occlusion ("Occlusion", Range(0,1)) = 1

        _BumpMap   ("Normal Map", 2D) = "bump" {}
        _BumpScale ("Bump Scale", Range(0,3)) = 1

        _FlowX     ("Flow X", Range(-1,1)) = 0.2
        _FlowY     ("Flow Y", Range(-1,1)) = 0.3
        _FlowSpeed ("Flow Speed", Range(-10,10)) = 1

        _Tiling    ("Tiling1", Range(0,1000)) = 1
        _Tiling2   ("Tiling2", Range(0,1000)) = 1

        _ScatteringColor ("Scatter Color", Color) = (0.5,0.5,0.5,1)

        // Water2 关键新增（少量）
        _ShallowColor ("Shallow Color", Color) = (0.2,0.6,0.8,1)
        _DeepColor    ("Deep Color",    Color) = (0.1,0.3,0.5,1)

        _DepthGradient ("Depth Fade", Range(0,5)) = 1
        _WaterClean    ("Water Clean", Range(0,3)) = 1

        _RefractionStrength   ("Refraction", Range(0,1)) = 0.1
        _ReflecionDistortion  ("Reflection Distortion", Range(0,1)) = 0.1
        _ReflectionIntensity  ("Reflection Intensity", Range(0,5)) = 0.5

        _FoamMap ("Foam Map", 2D) = "black" {}
        _FoamDepth ("Foam Depth", Range(0,10)) = 1
        _FoamIntensity ("Foam Intensity", Range(0,100)) = 0.2
        _FoamTiling ("Foam Tiling", Range(0,10)) = 1

        // -----------------------
        // Caustics（新增：焦散）
        // -----------------------
        [Header(Caustics)]
        _CausticMap ("Caustic Map (RGB)", 2D) = "white" {}
        _CausticTiling ("Caustic Tiling", Range(0,10)) = 1
        _CausticSpeed ("Caustic Speed", Range(0,10)) = 1
        _CausticIntensity ("Caustic Intensity", Range(0,5)) = 1
        _Channel_Offset ("Channel Offset (0-100)", Vector) = (0,33,67,0)
    }

    SubShader
    {
        Tags
        {
            "RenderType"="Transparent"
            "RenderPipeline"="UniversalRenderPipeline"
            "Queue"="Transparent"
        }

        Blend One Zero
        Cull Off
        LOD 100

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma enable_d3d11_debug_symbols

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile_fog

            #define _WATER

            // --- include 顺序很关键：SurfaceData 必须在 Lighting 前 ---
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

            // 自定义 SurfaceData（里面有 scaterringColor / reflectionColor）
            #include "Assets/Resource/Shader/Shaderlibrary/SurfaceData.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // 光照封装（提供 StandardLighting）
            #include "Assets/Resource/Shader/Shaderlibrary/LightingModel.hlsl"
            #include "Assets/Resource/Shader/Shaderlibrary/CustomBRDF_Water.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float4 tangentOS  : TANGENT;
                float2 texcoord   : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS  : SV_POSITION;
                float2 uv          : TEXCOORD0;
                float3 positionWS  : TEXCOORD1;
                float3 normalWS    : TEXCOORD2;
                float4 tangentWS   : TEXCOORD3;
                float3 viewDirWS   : TEXCOORD4;
                float4 shadowCoord : TEXCOORD5;

                float4 worldUV     : TEXCOORD6; // xy=tiling1, zw=tiling2
                float4 screenPos   : TEXCOORD7;
            };

            TEXTURE2D(_BaseMap);           SAMPLER(sampler_BaseMap);
            TEXTURE2D(_BumpMap);           SAMPLER(sampler_BumpMap);
            TEXTURE2D(_FoamMap);           SAMPLER(sampler_FoamMap);

            // Planar Reflection 脚本提供（如果没脚本就是黑）
            TEXTURE2D(_PlanarReflection);  SAMPLER(sampler_PlanarReflection);

            // Caustics（新增）
            TEXTURE2D(_CausticMap);        SAMPLER(sampler_CausticMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float  _Roughness;
                float  _Metallic;
                float  _Occlusion;

                float  _FlowX;
                float  _FlowY;
                float  _FlowSpeed;
                float  _Tiling;
                float  _Tiling2;
                float  _BumpScale;

                float4 _ScatteringColor;

                float4 _ShallowColor;
                float4 _DeepColor;
                float  _DepthGradient;
                float  _WaterClean;

                float  _RefractionStrength;
                float  _ReflecionDistortion;
                float  _ReflectionIntensity;

                float  _FoamTiling;
                float  _FoamIntensity;
                float  _FoamDepth;

                // Caustics（新增）
                float  _CausticTiling;
                float  _CausticSpeed;
                float  _CausticIntensity;
                float4 _Channel_Offset;
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings o;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs   normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                o.positionCS = vertexInput.positionCS;
                o.positionWS = vertexInput.positionWS;

                o.normalWS   = normalInput.normalWS;
                o.tangentWS  = float4(normalInput.tangentWS, input.tangentOS.w * GetOddNegativeScale());

                o.uv = input.texcoord;
                o.viewDirWS   = GetCameraPositionWS() - vertexInput.positionWS;
                o.shadowCoord = GetShadowCoord(vertexInput);

                o.screenPos = ComputeScreenPos(o.positionCS);

                // world xz * 0.01，再乘 tiling1/2
                float2 wsXZ = vertexInput.positionWS.xz * 0.01;
                o.worldUV.xy = wsXZ * _Tiling;
                o.worldUV.zw = wsXZ * _Tiling2;

                return o;
            }

            half4 frag(Varyings input, float vface : VFACE) : SV_Target
            {
                float2 flowDir = float2(_FlowX, _FlowY);
                float  speed   = _Time.x * _FlowSpeed;

                // phase 计算方式
                half phase0   = frac(speed + 0.5);
                half phase1   = frac(speed + 1.0);
                half flowlerp = saturate(abs(0.5 - phase0) / 0.5);

                half4 n1 = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.worldUV.xy + phase0 * flowDir);
                half4 n2 = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.worldUV.xy + phase1 * flowDir);
                half4 bump1 = lerp(n1, n2, flowlerp);
                bump1.xyz = UnpackNormalScale(bump1, _BumpScale * 0.25h);

                half4 n3 = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.worldUV.zw + phase0 * flowDir);
                half4 n4 = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.worldUV.zw + phase1 * flowDir);
                half4 bump2 = lerp(n3, n4, flowlerp);
                bump2.xyz = UnpackNormalScale(bump2, _BumpScale * 0.25h);

                half3 normalTS = lerp(bump1.xyz, bump2.xyz, 0.5h);

                // 泡沫（）
                half4 foamA = SAMPLE_TEXTURE2D(_FoamMap, sampler_FoamMap, input.worldUV.xy * _FoamTiling + flowDir * speed * 2);
                half4 foamB = SAMPLE_TEXTURE2D(_FoamMap, sampler_FoamMap, input.worldUV.zw * _FoamTiling + flowDir * speed * 2);
                half  foam  = lerp(foamA.r, foamB.r, 0.5h);

                // --- 深度 fade（）---
                float2 screenUV = input.screenPos.xy / input.screenPos.w;

                float sceneDepth = SampleSceneDepth(screenUV); 
                sceneDepth = LinearEyeDepth(sceneDepth, _ZBufferParams);

                float surfaceDepth = -TransformWorldToView(input.positionWS).z;
                float waterDepth = max(0, sceneDepth - surfaceDepth);

                float depthFactor   = saturate(exp2(-waterDepth * _DepthGradient));//深度指数衰减
                float alphaFactor   = 1 - saturate(exp2(-waterDepth * _WaterClean));
                float foamFactor    = saturate(exp2(-waterDepth * _FoamDepth));

                half3 baseTex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv).rgb * _BaseColor.rgb;

                half3 depthCol = lerp(_DeepColor.rgb, _ShallowColor.rgb, depthFactor);
                half3 albedoCol = depthCol * baseTex + foam * _FoamIntensity * foamFactor;

                // -----------------------
                // Caustics（新增：焦散）
                // -----------------------
                half causitcFactor = (1.0h - (half)alphaFactor) * (half)depthFactor;

                float3 channel_offset = _Channel_Offset.xyz * 0.01;
                float causticSpeed = speed * _CausticSpeed;

                float r1 = SAMPLE_TEXTURE2D(_CausticMap, sampler_CausticMap,
                            input.worldUV.xy * _CausticTiling + causticSpeed * flowDir + channel_offset.x).r;
                float g1 = SAMPLE_TEXTURE2D(_CausticMap, sampler_CausticMap,
                            input.worldUV.xy * _CausticTiling + causticSpeed * flowDir + channel_offset.y).g;
                float b1 = SAMPLE_TEXTURE2D(_CausticMap, sampler_CausticMap,
                            input.worldUV.xy * _CausticTiling + causticSpeed * flowDir + channel_offset.z).b;
                half3 caustics1 = half3(r1, g1, b1) * _CausticIntensity;

                float r2 = SAMPLE_TEXTURE2D(_CausticMap, sampler_CausticMap,
                            0.8 * causticSpeed * flowDir - input.worldUV.xy * _CausticTiling + channel_offset.x).r;
                float g2 = SAMPLE_TEXTURE2D(_CausticMap, sampler_CausticMap,
                            0.8 * causticSpeed * flowDir - input.worldUV.xy * _CausticTiling + channel_offset.y).g;
                float b2 = SAMPLE_TEXTURE2D(_CausticMap, sampler_CausticMap,
                            0.8 * causticSpeed * flowDir - input.worldUV.xy * _CausticTiling + channel_offset.z).b;
                half3 caustics2 = half3(r2, g2, b2) * _CausticIntensity;

                half3 caustic = min(caustics1, caustics2) * causitcFactor;

                albedoCol.rgb += caustic;

                // --- normalWS ---
                half3 normalWS = TransformTangentToWorld(
                    normalTS,
                    half3x3(input.tangentWS.xyz,
                            cross(input.normalWS.xyz, input.tangentWS.xyz) * input.tangentWS.w,
                            input.normalWS.xyz)
                );
                normalWS = NormalizeNormalPerPixel(normalWS);

                normalWS *= (vface > 0.0) ? 1.0 : -1.0;

                // 折射：采样屏幕颜色（OpaqueTexture）
                half2 distortedUV = screenUV + normalWS.xz * _RefractionStrength;
                half sceneDistortDepth = SampleSceneDepth(distortedUV);
                sceneDistortDepth = LinearEyeDepth(sceneDistortDepth, _ZBufferParams);

                // 防止折射采到“水面前面”的像素 
                half tmp = step(saturate(sceneDistortDepth - surfaceDepth), 0);
                distortedUV = tmp * screenUV + (1 - tmp) * distortedUV;
                //+++++++++++++++++++++需要采样偏移后的UV做比较保证水上的坐标不扭曲++++++++++++++++++++++++++++++++++++++++//

                float3 underWaterColor = SampleSceneColor(distortedUV);

                // 平面反射（脚本提供 _PlanarReflection）
                half2 reflectionDistortion = normalWS.xz * _ReflecionDistortion;
                half4 reflectionColor = SAMPLE_TEXTURE2D(_PlanarReflection, sampler_PlanarReflection, screenUV + reflectionDistortion) * _ReflectionIntensity;

                // InputData
                InputData lightingInput = (InputData)0;
                lightingInput.positionWS      = input.positionWS;
                lightingInput.normalWS        = normalWS;
                lightingInput.viewDirectionWS = SafeNormalize(input.viewDirWS);
                lightingInput.shadowCoord     = input.shadowCoord;
                lightingInput.fogCoord        = 0;
                lightingInput.vertexLighting  = 0;

                // SurfaceData
                SurfaceData surfaceData = (SurfaceData)0;
                surfaceData.albedo     = albedoCol;
                surfaceData.alpha      = 1;
                surfaceData.metallic   = 0;
                surfaceData.smoothness = saturate(1.0h - _Roughness);
                surfaceData.occlusion  = _Occlusion;
                surfaceData.normalTS   = normalTS;

                // Water2
                surfaceData.reflectionColor  = reflectionColor;
                surfaceData.scaterringColor  = _ScatteringColor;

                half4 color = StandardLighting(lightingInput, surfaceData);
                color.rgb = color.rgb * alphaFactor + (1 - alphaFactor) * underWaterColor;
                return color;
            }
            ENDHLSL
        }
    }
}
