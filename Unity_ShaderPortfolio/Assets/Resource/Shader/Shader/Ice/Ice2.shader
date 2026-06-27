Shader "Custom/Environment/Ice2"
{
    Properties
    {
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        [MainColor] _BaseColor("Base Color", Color) = (1,1,1,1)
        
        _InnerMap("InnerMap",2D) = "white"{}
        _RoughnessMap("RoughnessMap",2D) = "white"{}
        _Smoothness("Smoothness",Range(-1,1)) = 0
        
        _ThicknessMap("ThicknessMap",2D) = "white"{}
        _Thickness("Thickness",Range(0,10)) = 1
        
        _NoiseMap("NoiseMap",2D) = "white"{}
        _Distance("Distance",Range(0,1)) = 0.1
        
        [HDR]
        _InnerColor("InnerColor",Color) = (1,1,1,1)
        _ScatterColor("ScatterColor",Color) = (1,1,1,1)
        _SpecularScale("SpecularScale",Range(0,100)) = 1
        
        _FrenelBias("FrenelBias",Range(0,1)) = 0
        _FrenelScale("FrenelScale",Range(0,5)) = 0
        _FrenelPow("FrenelPow",Range(0,10)) = 5
        
        _BumpMap("Normal Map", 2D) = "bump" {}
        _BumpScale("Normal Scale", Range(0,1)) = 1.0
            
        _HeightMap("HeightMap",2D) = "white"{}
        _HeightTiling("HeighTiling",Range(0.01,100)) = 1
        _Height("Height",Range(-1,1)) = 1
        


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
            Blend One Zero
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma enable_d3d11_debug_symbols
            #define _ICE
            

            #include "Assets/Resource/Shader/ShaderLibrary/LightingModel.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

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
            TEXTURE2D(_BaseMap);        SAMPLER(sampler_BaseMap);
            TEXTURE2D(_BumpMap);        SAMPLER(sampler_BumpMap);
            TEXTURE2D(_HeightMap);      SAMPLER(sampler_HeightMap);
            TEXTURE2D(_InnerMap);       SAMPLER(sampler_InnerMap);
            TEXTURE2D(_ThicknessMap);   SAMPLER(sampler_ThicknessMap);
            TEXTURE2D(_NoiseMap);       SAMPLER(sampler_NoiseMap);
            TEXTURE2D(_RoughnessMap);   SAMPLER(sampler_RoughnessMap);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half4 _BaseColor;
                half _BumpScale;
                half _Height;
                half _HeightTiling;
                half4 _InnerColor;
                half4 _ScatterColor;
                float _SpecularScale;
                half _Thickness;
                half _Distance;

                half _FrenelBias;
                half _FrenelScale;
                half _FrenelPow;
                half _Smoothness;
            CBUFFER_END


            half Frenel(half3 n, half3 v, half powIntensity)
            {
                half NdotV = saturate(dot(n,v));
                half f = pow(1.0 - NdotV,powIntensity);
                f = saturate(f);
                return f;
            }

            half3 SpiralBlur(float4 positionCS,int RadialSteps,int DistanceSteps,half Distance)
            {
                
                float2 ScenePixels = positionCS;
                float2 RandomSamp = ((uint)(ScenePixels.x) + 2 * (uint)(ScenePixels.y)) % 5;
                RandomSamp = SAMPLE_TEXTURE2D(_NoiseMap,sampler_NoiseMap,RandomSamp).r;
                RandomSamp/=5;
                RandomSamp-=0.5;
                
                float3 CurColor = 0;
                float2 BaseUV = positionCS / _ScreenParams.xy;
                float CurDistance = 0;
                float2 NewUV = BaseUV;
                float2 CurOffset = 0;
                float TwoPi = 6.283185f;
                half TempAARotation = 1;
                half TempAADistance = 1;
                float StepSize = Distance / (int) DistanceSteps;
                TempAARotation*=RandomSamp;
                TempAADistance*=StepSize*RandomSamp;
                float Substep = 0;
                half RadialOffset = 0.314;
                int i=0;
                while (i < (int)DistanceSteps)
                {
                    for (int j = 0; j < RadialSteps; j++)
                    {
                        CurOffset.x = cos(TwoPi * (TempAARotation + (Substep) / RadialSteps));
                        CurOffset.y = sin(TwoPi * ((TempAARotation + Substep) / RadialSteps));
                        NewUV.x = BaseUV.x + (CurOffset.x * (CurDistance +(RandomSamp * TempAADistance)));
                        NewUV.y = BaseUV.y + (CurOffset.y * (CurDistance+ (RandomSamp * TempAADistance)));
                        CurColor += SAMPLE_TEXTURE2D(_CameraOpaqueTexture,
                            sampler_CameraOpaqueTexture, NewUV);
                        Substep++;
                    }
                    CurDistance+=StepSize;
                    Substep+=RadialOffset;
                    i++;
                }
                CurColor = CurColor / (DistanceSteps*RadialSteps);
                return CurColor;
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

            half2 BumpOffset(half2 uv,half3 viewDir,half height)
            {
                half2 offset = (viewDir.xy/viewDir.z) * height;
                uv = uv + offset;
                return uv;
            }

            half4 frag(Varyings input) : SV_Target
            {


                half3 bitTangentWS = cross(input.normalWS, input.tangentWS.xyz) * input.tangentWS.w;
                half3x3 TBN = half3x3(input.tangentWS.xyz,bitTangentWS.xyz,input.normalWS.xyz);
                half3 V = normalize(input.viewDirWS);
                half3 viewTS = mul(TBN,V);

                half height = SAMPLE_TEXTURE2D(_HeightMap,sampler_HeightMap,input.uv * _HeightTiling).r * _Height;
                half2 offset = BumpOffset(input.uv,viewTS,height);

                                // 从贴图采样
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                half3 albedo = baseMap.rgb * _BaseColor.rgb;

                half4 innerColor = SAMPLE_TEXTURE2D(_InnerMap, sampler_InnerMap, offset) * _InnerColor;
                albedo += innerColor.rgb;

                half3 thickness = SAMPLE_TEXTURE2D(_ThicknessMap, sampler_ThicknessMap, input.uv) * _Thickness;
                
                // 法线计算
                half4 normalSample = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.uv);
                half3 normalTS = UnpackNormalScale(normalSample, _BumpScale);
                half3 normalWS = TransformTangentToWorld(normalTS, 
                    half3x3(input.tangentWS.xyz, 
                    cross(input.normalWS, input.tangentWS.xyz) * input.tangentWS.w, 
                    input.normalWS));
                normalWS = NormalizeNormalPerPixel(normalWS);

                half4 roughness = SAMPLE_TEXTURE2D(_RoughnessMap, sampler_RoughnessMap, input.uv);
                
                
                half occlusion = 1;
                half smoothness = 1 - roughness + _Smoothness;
                half metallic = 0;
                
                half f = _FrenelBias + _FrenelScale * Frenel(normalWS,V,_FrenelPow);
                f = saturate(f);
                
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
                surfaceInput.alpha = 1;
                surfaceInput.metallic = metallic;
                surfaceInput.smoothness = smoothness;
                surfaceInput.occlusion = occlusion;
                surfaceInput.normalTS = normalTS;
                surfaceInput.scaterringColor = _ScatterColor * half4(thickness,1);
                surfaceInput.specularScale = _SpecularScale;
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