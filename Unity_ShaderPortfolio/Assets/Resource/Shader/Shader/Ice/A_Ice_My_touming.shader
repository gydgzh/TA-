Shader "Custom/Environment/A_Ice_My_touming" // 半透明冰（最小改动版）
{
    Properties
    {
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        [MainColor] _BaseColor("Base Color", Color) = (1,1,1,1)

        _BumpMap("Normal Map", 2D) = "bump" {}
        _BumpScale("Normal Scale", Range(0,1)) = 1.0

        // ORM: R=AO, G=Roughness(或Smoothness反向), B=Metallic
        _ORMMap("OcclusionRoughnessMetalic", 2D) = "white" {}
        _OcclusionStrength("Occlusion Strength", Range(0.0, 1.0)) = 1.0
        _Metallic("Metallic", Range(-1, 1)) = 0.0
        _Smoothness("Smoothness", Range(-1, 1)) = 0.5

        _ScatterColor("ScatterColor", Color) = (1,1,1,1)

        _MatCap("MatCap", 2D) = "white" {}
        _MatCapIntensity("MatCapIntensity", Range(0,2)) = 0.5

        _Distance("Distance", Range(0,2)) = 0.1
        _NoiseMap("NosieMap", 2D) = "white" {}

        _SceneColorIntensity("SceneColorIntensity", Range(0,3)) = 0.15
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent"
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
            #define scaterringColor scatteringColor
            #include "Assets/Resource/Shader/ShaderLibrary/ShadingModels.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

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
                float4 screenPos   : TEXCOORD6;
            };

            TEXTURE2D(_BaseMap);  SAMPLER(sampler_BaseMap);
            TEXTURE2D(_BumpMap);  SAMPLER(sampler_BumpMap);
            TEXTURE2D(_ORMMap);   SAMPLER(sampler_ORMMap);
            TEXTURE2D(_NoiseMap); SAMPLER(sampler_NoiseMap);
            TEXTURE2D(_MatCap);   SAMPLER(sampler_MatCap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half4  _BaseColor;
                half   _BumpScale;
                half   _OcclusionStrength;
                half   _Metallic;
                half   _Smoothness;
                half4  _ScatterColor;
                half   _MatCapIntensity;
                half   _Distance;
                half   _SceneColorIntensity;
            CBUFFER_END

            half2 BumpOffset(float2 uv, half3 viewDirTS, half height)
            {
                half vz = max(abs(viewDirTS.z), 0.2h);
                half2 offset = (viewDirTS.xy / vz) * height;
                return uv + offset;
            }

            // 旋转模糊
            half3 SprialBur(half4 positionCS, int RadialSteps, int DistanceSteps, half distance)
            {
                float2 ScenePixels = positionCS.xy;
                float2 Randomsamp = (uint(ScenePixels.x) + 2 * (uint)ScenePixels.y) % 5;
                Randomsamp = SAMPLE_TEXTURE2D(_NoiseMap, sampler_NoiseMap, Randomsamp).r;
                Randomsamp /= 5;
                Randomsamp -= 0.5; // 原来这里减 5 会把模糊采样彻底带偏

                float3 CurColor = 0;
                float2 BaseUV = positionCS.xy / _ScreenParams.xy;
                float CurDistance = 0;
                float2 NewUV = BaseUV;
                float2 CurOffset = 0;
                float TwoPi = 6.283185f;
                half TempAARotation = 1;
                half TempAADistance = 1;
                float StepSize = distance / max((int)DistanceSteps, 1);
                TempAARotation *= Randomsamp;
                TempAADistance *= StepSize * Randomsamp;
                float Substep = 0;
                half RadialOffset = 0.314;

                int i = 0;
                while (i < (int)DistanceSteps)
                {
                    for (int j = 0; j < RadialSteps; j++)
                    {
                        CurOffset.x = cos(TwoPi * (TempAARotation + (Substep) / RadialSteps));
                        CurOffset.y = sin(TwoPi * ((TempAARotation + Substep) / RadialSteps));
                        NewUV.x = BaseUV.x + (CurOffset.x * (CurDistance + (Randomsamp * TempAADistance)));
                        NewUV.y = BaseUV.y + (CurOffset.y * (CurDistance + (Randomsamp * TempAADistance)));
                        CurColor += SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, NewUV);
                        Substep++;
                    }
                    CurDistance += StepSize;
                    Substep += RadialOffset;
                    i++;
                }

                CurColor = CurColor / max((DistanceSteps * RadialSteps), 1);
                return CurColor;
            }

            Varyings vert(Attributes input)
            {
                Varyings output;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                output.normalWS = normalInput.normalWS;
                output.tangentWS = float4(normalInput.tangentWS.xyz, input.tangentOS.w * GetOddNegativeScale());
                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
                output.shadowCoord = GetShadowCoord(vertexInput);
                output.screenPos = ComputeScreenPos(output.positionCS);
                return output;
            }

            half Frenel(half3 n, half3 v, half powIntensity)
            {
                half NdotV = saturate(dot(n, v));
                half f = pow(1.0h - NdotV, powIntensity);
                return saturate(f);
            }

            half4 frag(Varyings input) : SV_Target
            {
                // 基础贴图
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                half3 baseAlbedo = baseMap.rgb * _BaseColor.rgb;
                half  alpha = baseMap.a * _BaseColor.a;

                // 法线
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

                // ORM
                half4 mask = SAMPLE_TEXTURE2D(_ORMMap, sampler_ORMMap, input.uv);
                half occlusion = LerpWhiteTo(mask.r, _OcclusionStrength);
                half smoothness = saturate(1.0h - mask.g + _Smoothness);
                half metallic = saturate(mask.b + _Metallic);

                half3 V = SafeNormalize(input.viewDirWS);
                half NdotV = saturate(dot(normalWS, V));

                half3 viewNormal = normalize(TransformWorldToViewDir(normalWS));
                float2 matcapUV = viewNormal.xy * 0.5 + 0.5;
                half matcapWeight = pow(1.0h - NdotV, 4.0h);
                half3 matcap = SAMPLE_TEXTURE2D(_MatCap, sampler_MatCap, matcapUV).rgb;
                half3 matcapCol = matcap * (_MatCapIntensity * matcapWeight);

                // PBR 本体
                InputData lightingInput = (InputData)0;
                lightingInput.positionWS = input.positionWS;
                lightingInput.normalWS = normalWS;
                lightingInput.viewDirectionWS = V;
                lightingInput.shadowCoord = input.shadowCoord;
                lightingInput.fogCoord = 0;
                lightingInput.vertexLighting = half3(0, 0, 0);

                SurfaceData surfaceInput = (SurfaceData)0;
                surfaceInput.albedo = baseAlbedo;
                surfaceInput.alpha = alpha;
                surfaceInput.metallic = metallic;
                surfaceInput.smoothness = smoothness;
                surfaceInput.occlusion = occlusion;
                surfaceInput.normalTS = normalTS;
                surfaceInput.scaterringColor = _ScatterColor; // 原代码漏了这一句
                surfaceInput.specularScale = 1;

                clip(surfaceInput.alpha - 0.33);

                half4 color = StandardLighting(lightingInput, surfaceInput);

                // 再叠 MatCap，而不是先加进 albedo
                color.rgb += matcapCol;

                half f = 0.2h + Frenel(normalWS, V, 5.0h);
                half blurDistance = _Distance * (1.0h - f);
                half3 sceneColor = SprialBur(input.positionCS, 16, 16, blurDistance);
                color.rgb += sceneColor * _SceneColorIntensity;

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
