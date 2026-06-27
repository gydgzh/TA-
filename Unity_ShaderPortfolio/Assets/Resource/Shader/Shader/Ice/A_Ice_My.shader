Shader "Custom/Environment/A_Ice_My"
{
    Properties
    {
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        [MainColor] _BaseColor("Base Color", Color) = (1,1,1,1)

        // 里层（内部）纹理
        _InnerMap("InnerMap",2D) = "white"{}
        _InnerColor("InnerColor",Color) = (1,1,1,1)
        _InnerTiling("InnerTiling",Range(0,100)) = 1

        _BumpMap("Normal Map", 2D) = "bump" {}
        _BumpScale("Normal Scale", Range(0,1)) = 1.0

        _ORMMap("OcclusionRoughnessMetalic", 2D) = "white" {}
        _OcclusionStrength("Occlusion Strength", Range(0.0, 1.0)) = 1.0
        _Metallic("Metallic", Range(-1, 1)) = 0.0
        _Smoothness("Smoothness", Range(-1, 1)) = 0.5

        // 高度图（用于“让内部纹理随视角漂移”，制造皮下错觉）
        _HeighMap("HeightMap",2D) = "white"{}
        _Height("Height",Range(-1,1)) = 0
        _HeightTilling("HeightTilling",Range(0,100)) = 1

        // 散射颜色（皮下感主要靠这个进入 ShadingModels 的散射项）
        _ScatterColor("ScatterColor",Color) = (1,1,1,1)

        // MatCap（增强反射）
        _MatCap("MatCap",2D) = "white"{}
        _MatCapIntensity("MatCapIntensity",Range(0,2)) = 0.5
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Geometry"
        }

        Pass
        {
            Cull Off
            Blend One Zero
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma enable_d3d11_debug_symbols

            #define _ICE

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Assets/Resource/Shader/ShaderLibrary/SurfaceData.hlsl"
            #define scaterringColor scatteringColor // 兼容拼写

            #include "Assets/Resource/Shader/ShaderLibrary/ShadingModels.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 texcoord     : TEXCOORD0;
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
            };

            TEXTURE2D(_BaseMap);   SAMPLER(sampler_BaseMap);
            TEXTURE2D(_InnerMap);  SAMPLER(sampler_InnerMap);
            TEXTURE2D(_BumpMap);   SAMPLER(sampler_BumpMap);
            TEXTURE2D(_ORMMap);    SAMPLER(sampler_ORMMap);

            // 高度图（注意名字是 _HeighMap）
            TEXTURE2D(_HeighMap);  SAMPLER(sampler_HeighMap);

            // [CHG1] MatCap 的名字必须和 Properties 对齐：_MatCap / _MatCapIntensity
           
            TEXTURE2D(_MatCap);    SAMPLER(sampler_MatCap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half4  _BaseColor;

                half4  _InnerColor;
                half   _InnerTiling;

                half   _BumpScale;
                half   _OcclusionStrength;
                half   _Metallic;
                half   _Smoothness;

                half   _Height;
                half   _HeightTilling;

                half4  _ScatterColor;

                // [CHG1] 名字对齐
                half   _MatCapIntensity;
            CBUFFER_END

            // 视差偏移（只给 Inner 用：制造“内部在表皮下漂移”的感觉）
            half2 BumpOffset(float2 uv, half3 viewDirTS, half height)
            {
                // 防止 viewDirTS.z 太小导致 UV 飞掉
                half vz = max(abs(viewDirTS.z), 0.2h);
                half2 offset = (viewDirTS.xy / vz) * height;
                return uv + offset;
            }

            Varyings vert(Attributes input)
            {
                Varyings output;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput   = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                output.normalWS   = normalInput.normalWS;
                output.tangentWS  = float4(normalInput.tangentWS.xyz, input.tangentOS.w * GetOddNegativeScale());
                output.uv         = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.viewDirWS  = GetCameraPositionWS() - vertexInput.positionWS;
                output.shadowCoord = GetShadowCoord(vertexInput);
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                // =========================
                // 1) 基础采样
                // =========================
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                half3 baseAlbedo = baseMap.rgb * _BaseColor.rgb;
                half  alpha = baseMap.a * _BaseColor.a;

                // =========================
                // 2) 法线（表面）与 ORM（表面）——用原始UV
                // =========================
                half4 normalSample = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.uv);
                half3 normalTS = UnpackNormalScale(normalSample, _BumpScale);

                half3 normalWS = TransformTangentToWorld(
                    normalTS,
                    half3x3(
                        input.tangentWS.xyz,
                        cross(input.normalWS, input.tangentWS.xyz) * input.tangentWS.w,
                        input.normalWS
                    )
                );
                normalWS = NormalizeNormalPerPixel(normalWS);

                half4 mask = SAMPLE_TEXTURE2D(_ORMMap, sampler_ORMMap, input.uv);
                half occlusion  = LerpWhiteTo(mask.r, _OcclusionStrength);

                // G 作为 roughness(越大越粗糙)，所以 smoothness = 1 - roughness + _Smoothness
                half smoothness = saturate(1.0h - mask.g + _Smoothness);
                half metallic   = saturate(mask.b + _Metallic);

                half3 V = normalize(input.viewDirWS);
                half  NdotV = saturate(dot(normalWS, V));

                // =========================
                // 3) Inner（内部）——用高度图 + 视角做 UV 偏移（只影响内部）
                // =========================
                // [CHG3] height 用 (h*2-1) 拉满到 [-1,1]，比 (h-0.5) 更“明显”，更容易看出内部漂移
                half h = SAMPLE_TEXTURE2D(_HeighMap, sampler_HeighMap, input.uv * _HeightTilling).r;
                half height = (h * 2.0h - 1.0h) * _Height;

                half3 bitTangentWS = cross(input.normalWS, input.tangentWS.xyz) * input.tangentWS.w;
                half3x3 TBN = half3x3(input.tangentWS.xyz, bitTangentWS, input.normalWS);
                
                half3 viewTS = mul(TBN, V);

                half2 uvInner = BumpOffset(input.uv * _InnerTiling, viewTS, height);
                half3 innerTex = SAMPLE_TEXTURE2D(_InnerMap, sampler_InnerMap, uvInner).rgb;
                half3 innerCol = innerTex * _InnerColor.rgb;

                // [CHG5] InnerWeight：让内部在“边缘/掠射角”更明显（更像在表皮下面）
           
                half edge = pow(1.0h - NdotV, 2.0h);
                half innerWeight = saturate(0.25h + edge); // 正面也有一点点，边缘更强

                // =========================
                // 4) MatCap（反射增强）——修复命名 + 加边缘权重更明显
                // =========================
                // [CHG1] MatCap 纹理/强度对齐后才会真正有值
                half3 viewNormal = normalize(TransformWorldToViewDir(normalWS));
                float2 matcapUV = viewNormal.xy * 0.5 + 0.5;

                half matcapWeight = pow(1.0h - NdotV, 4.0h); // 边缘更像反射
                half3 matcap = SAMPLE_TEXTURE2D(_MatCap, sampler_MatCap, matcapUV).rgb;
                half3 matcapCol = matcap * (_MatCapIntensity * matcapWeight);

                // =========================
                // 5) 最终表面颜色：表面(base) + 少量 matcap；内部主要走 scatteringColor
                //    [CHG6] 关键：不要把 Inner 大量混进 albedo，否则看起来像贴在表面
                // =========================
                half3 albedo = baseAlbedo + matcapCol;

                // =========================
                // =========================
                InputData lightingInput = (InputData)0;
                lightingInput.positionWS = input.positionWS;
                lightingInput.normalWS = normalWS;
                lightingInput.viewDirectionWS = SafeNormalize(input.viewDirWS);
                lightingInput.shadowCoord = input.shadowCoord;
                lightingInput.fogCoord = 0;
                lightingInput.vertexLighting = half3(0, 0, 0);

                SurfaceData surfaceInput = (SurfaceData)0;
                surfaceInput.albedo = albedo;
                surfaceInput.alpha = alpha;
                surfaceInput.metallic = metallic;
                surfaceInput.smoothness = smoothness;
                surfaceInput.occlusion = occlusion;
                surfaceInput.normalTS = normalTS;

                surfaceInput.scaterringColor = _ScatterColor * half4(innerCol * innerWeight, 1);

                surfaceInput.specularScale = 1;

               
                clip(surfaceInput.alpha - 0.33);

                half4 color = StandardLighting(lightingInput, surfaceInput);
                return color;
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            HLSLPROGRAM
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthNormals"
            Tags { "LightMode" = "DepthNormals" }

            ZWrite On
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitDepthNormalsPass.hlsl"
            ENDHLSL
        }
    }
    FallBack "Universal Render Pipeline/Lit"
}
