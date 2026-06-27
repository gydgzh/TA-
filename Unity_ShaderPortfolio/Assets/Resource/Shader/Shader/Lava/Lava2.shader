Shader "Custom/Environment/Lava2"
{
    Properties
    {
        _AlbedoMap("AlbedoMap",2D) = "white"{}
        _BumpMap("NormalMap",2D) = "bump"{}
        _FlowMap("FlowMap",2D) = "white"{}
        _BumpScale("BumpScale",Range(0,1)) = 1
        
        [HDR] _HotLavaColor("HotLavaColor",Color) = (1,1,1,1)
        [HDR] _ColdLavaColor("ColdLavaColor",Color) = (1,1,1,1)
        
        _HotLavaThrehold("HotLavaThrehold",Range(0,1)) = 0.5
        _HotLavaPower("HotLavaPower",Range(0,10)) = 1
        
        _Smoothness("Smoothness",Range(0,1)) = 0.2
        
        [Header(Flow)]
        _FlowX("FlowX",Range(-1,1)) =0.2
        _FlowY("FlowY",Range(-1,1)) = 0.3
        _FlowSpeed("FlowSpeed",Range(-10,10)) = 1
        _Tiling("Tiling",Range(0,100)) = 1
        _PeriodSec("PeriodSec",Range(0,2)) = 0.5

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
            #define _ADDITIONAL_LIGHTS
            

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

                half4 worldUV : TEXCOORD6;
            };

            TEXTURE2D(_BumpMap);             SAMPLER(sampler_BumpMap);
            TEXTURE2D(_AlbedoMap);           SAMPLER(sampler_AlbedoMap);
            TEXTURE2D(_FlowMap);             SAMPLER(sampler_FlowMap);

            CBUFFER_START(UnityPerMaterial)
                float _FlowX;
                float _FlowY;
                float _FlowSpeed;
                float _Tiling;
                float _HotLavaThrehold;
                float _HotLavaPower;
                float4 _HotLavaColor;
                float4 _ColdLavaColor;
                float _PeriodSec;
                float _Smoothness;
                half _Height;
                half _BumpScale;
            CBUFFER_END
            

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
                output.uv = input.texcoord;
                output.viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
                output.shadowCoord = GetShadowCoord(vertexInput);

                output.worldUV.xy = vertexInput.positionWS.xz * 0.001 * _Tiling;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float2 flowDir = (SAMPLE_TEXTURE2D(_FlowMap,sampler_FlowMap,input.uv).rg * 2 - 1) * float2(_FlowX,_FlowY);

                half halfPeriodSec = 0.5 * _PeriodSec;
                half speed = _Time.x * _FlowSpeed;
                half phase0 = frac(speed) * halfPeriodSec;
                half phase1 = frac(speed + 0.5) * halfPeriodSec;
                half flowlerp = saturate(abs(halfPeriodSec-phase0) / halfPeriodSec);
                
                //flowmap
                half4 normalMap1 = SAMPLE_TEXTURE2D(_BumpMap,sampler_BumpMap,input.worldUV.xy + phase0 * flowDir);
                half4 normalMap2 = SAMPLE_TEXTURE2D(_BumpMap,sampler_BumpMap,input.worldUV.xy + phase1 * flowDir);
                half4 bump1 = lerp(normalMap1,normalMap2,flowlerp);
                bump1.rgb = UnpackNormalScale(bump1,_BumpScale);


                half4 baseColor1 = SAMPLE_TEXTURE2D(_AlbedoMap,sampler_AlbedoMap,input.worldUV.xy + phase0 * flowDir);
                half4 baseColor2 = SAMPLE_TEXTURE2D(_AlbedoMap,sampler_AlbedoMap,input.worldUV.xy + phase1 * flowDir);
                half4 baseColor = lerp(baseColor1,baseColor2,flowlerp);

                half hotLavaMask = pow(saturate(baseColor.a - _HotLavaThrehold), 10.0/(_HotLavaPower));
                
                // 法线计算
      
                half3 normalWS = TransformTangentToWorld(bump1, 
                    half3x3(input.tangentWS.xyz, 
                    cross(input.normalWS, input.tangentWS.xyz) * input.tangentWS.w, 
                    input.normalWS));
                normalWS = NormalizeNormalPerPixel(normalWS);
                
                half occlusion = 1;
                half smoothness = _Smoothness;
                half metallic = 0;

                InputData lightingInput = (InputData)0;
                lightingInput.positionWS = input.positionWS;
                lightingInput.normalWS = normalWS;
                lightingInput.viewDirectionWS = SafeNormalize(input.viewDirWS);
                lightingInput.shadowCoord = input.shadowCoord;
                lightingInput.fogCoord = 0;
                lightingInput.vertexLighting = half3(0, 0, 0);
                
                // 表面属性
                SurfaceData surfaceInput = (SurfaceData)0;
                surfaceInput.albedo = baseColor * _ColdLavaColor;
                surfaceInput.alpha = 1;
                surfaceInput.metallic = metallic;
                surfaceInput.smoothness = smoothness;
                surfaceInput.occlusion = occlusion;
                surfaceInput.normalTS = bump1;
                surfaceInput.emission = hotLavaMask * _HotLavaColor;
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