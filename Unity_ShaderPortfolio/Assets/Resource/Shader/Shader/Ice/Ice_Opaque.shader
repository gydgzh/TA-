Shader "Custom/Environment/IceOpaque"
{
    Properties
    {
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        [MainColor] _BaseColor("Base Color", Color) = (1,1,1,1)
        
        _InnerMap("InnerMap",2D) = "white"{}
        _InnerColor("InnerColor",Color) = (1,1,1,1)
        _InnerTiling("InnerTiling",Range(0,100)) = 1
        
        _BumpMap("Normal Map", 2D) = "bump" {}
        _BumpScale("Normal Scale", Range(0,1)) = 1.0
        _ORMMap("OcclusionRoughnessMetalic", 2D) = "white" {}
        _OcclusionStrength("Occlusion Strength", Range(0.0, 1.0)) = 1.0
        _Metallic("Metallic", Range(-1, 1)) = 0.0
        _Smoothness("Smoothness", Range(-1, 1)) = 0.5
        
        _HeightMap("HeightMap",2D) = "white"{}
        _Height("Height",Range(-1,1)) = 0
        _HeightTiling("HeightTiling",Range(0,100)) = 1
        
        _ScatterColor("ScatterColor",Color) = (1,1,1,1)
        
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
            Cull off
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma enable_d3d11_debug_symbols
            #define _ICE
            

            #include "Assets/Resource/Shader/ShaderLibrary/ShadingModels.hlsl"

            

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS    : NORMAL;
                float4 tangentOS   : TANGENT;
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

            // 材质属性
            TEXTURE2D(_BaseMap);     SAMPLER(sampler_BaseMap);
            TEXTURE2D(_BumpMap);     SAMPLER(sampler_BumpMap);
            TEXTURE2D(_ORMMap);      SAMPLER(sampler_ORMMap);
            TEXTURE2D(_EmissionMap); SAMPLER(sampler_EmissionMap);
            TEXTURE2D(_HeightMap);   SAMPLER(sampler_HeightMap);
            TEXTURE2D(_InnerMap);    SAMPLER(sampler_InnerMap);
            TEXTURE2D(_MatCap);      SAMPLER(sampler_MatCap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half4 _BaseColor;
                half _Metallic;
                half _Smoothness;
                half _BumpScale;
                half _OcclusionStrength;
                half4 _EmissionColor;
                half _HeightTiling;
                half _Height;
                half4 _InnerColor;
                half4 _ScatterColor;
                half _MatCapIntensity;
                half _InnerTiling;
            CBUFFER_END

            half2 BumpOffset(float2 uv,half3 viewDir,half height)
            {
                half2 offset = (viewDir.xy / viewDir.z) * height;
                uv = uv + offset;
                return uv;
            }
            

            Varyings vert(Attributes input)
            {
                Varyings output;
                
                // 顶点变换
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                
                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                output.normalWS = normalInput.normalWS;
                output.tangentWS = float4(normalInput.tangentWS.xyz, input.tangentOS.w * GetOddNegativeScale());
                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
                output.shadowCoord = GetShadowCoord(vertexInput);
                
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {

                half height = SAMPLE_TEXTURE2D(_HeightMap,sampler_HeightMap,input.uv * _HeightTiling) * _Height;
                half3 bitTangentWS = cross(input.normalWS,input.tangentWS.xyz) * input.tangentWS.w;
                half3x3 TBN = half3x3(input.tangentWS.xyz,bitTangentWS,input.normalWS.xyz);
                half3 V = normalize(input.viewDirWS);
                half3 viewTS = mul(TBN,V);
                half2 uvOffset = BumpOffset(input.uv * _InnerTiling,viewTS,height);
                // 从贴图采样
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                half4 innerColor = SAMPLE_TEXTURE2D(_InnerMap,sampler_InnerMap,uvOffset);
                half3 albedo = (baseMap.rgb * _BaseColor.rgb + innerColor * _InnerColor) * 0.5;
                
                half alpha = baseMap.a * _BaseColor.a;
                

                // 法线计算
                half4 normalSample = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.uv);
                half3 normalTS = UnpackNormalScale(normalSample, _BumpScale);
                half3 normalWS = TransformTangentToWorld(normalTS, 
                    half3x3(input.tangentWS.xyz, 
                    cross(input.normalWS, input.tangentWS.xyz) * input.tangentWS.w, 
                    input.normalWS));
                normalWS = NormalizeNormalPerPixel(normalWS);


                half3 viewNormal = normalize(TransformWorldToViewDir(normalWS));
                float2 matcapUV = viewNormal.xy * 0.5 + 0.5;
                half3 reflectColor = SAMPLE_TEXTURE2D(_MatCap,sampler_MatCap,matcapUV) * _MatCapIntensity;

                albedo.rgb += reflectColor;
                // 环境光遮蔽
                half4 mask = SAMPLE_TEXTURE2D(_ORMMap, sampler_ORMMap, input.uv);
                
                half occlusion = LerpWhiteTo(mask.r, _OcclusionStrength);
                half smoothness = saturate(1 - mask.g + _Smoothness);
                half metallic = saturate(mask.b + _Metallic);

                InputData lightingInput = (InputData)0;
                lightingInput.positionWS = input.positionWS;
                lightingInput.normalWS = normalWS;
                lightingInput.viewDirectionWS = SafeNormalize(input.viewDirWS);
                lightingInput.shadowCoord = input.shadowCoord;
                lightingInput.fogCoord = 0;
                lightingInput.vertexLighting = half3(0, 0, 0);
                
                // 表面属性
                SurfaceData surfaceInput = (SurfaceData)0;
                surfaceInput.albedo = albedo;
                surfaceInput.alpha = alpha;
                surfaceInput.metallic = metallic;
                surfaceInput.smoothness = smoothness;
                surfaceInput.occlusion = occlusion;
                surfaceInput.normalTS = normalTS;
                surfaceInput.scaterringColor = _ScatterColor;
                surfaceInput.specularScale = 1;
                            clip(surfaceInput.alpha - 0.33);
                // PBR光照计算
                half4 color = StandardLighting(lightingInput, surfaceInput);
                return color;
            }
            ENDHLSL
        }
        
        // 阴影投射Pass
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
            Tags
            {
                "LightMode" = "DepthNormals"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            // -------------------------------------
            // Universal Pipeline keywords
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitDepthNormalsPass.hlsl"
            ENDHLSL
        }
    }
    FallBack "Universal Render Pipeline/Lit"
}