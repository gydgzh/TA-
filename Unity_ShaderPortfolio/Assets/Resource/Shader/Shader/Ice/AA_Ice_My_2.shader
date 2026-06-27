Shader "Custom/Environment/Ice"
{
    Properties
    {
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        [MainColor] _BaseColor("Base Color", Color) = (1,1,1,1)
        [HDR]
        _InnerColor("Inner Color", Color) = (1,1,1,1)
        [HDR]
        _ScatterColor("ScatterColor",Color) = (1,1,1,1)
        
        _InnerMap("InnerMap", 2D) = "white"{}
        _BumpMap("Normal Map", 2D) = "bump" {}
        _BumpScale("Normal Scale", Range(0,1)) = 1.0
        _ORMMap("OcclusionRoughnessMetalic", 2D) = "white" {}
        
        
        _NoiseMap("NoiseMap",2D) = "white"{}
        _Distance("Distance",Range(0,0.4)) = 0.2
        _Alpha("Alpha",Range(0,1)) = 0.5
        _RefractIntensity("Refract",Range(0,1)) = 0.5
        
        
        _HeightMap("HeightMap",2D) = "black"{}
        _MatcapMap("MatcapMap",2D) = "black"{}
        _HeightTiling("HeightTiling",Range(0,10)) = 1
        _Height("Height",Range(-1,1)) = 0.5
        _MatcapIntensity("MatCapIntensity",Range(0,2)) = 0.2
        _ViewNormalIntensity("ViewNormalInten",Range(0,2)) = 1
        _FrenelBias("FrenelBias",Range(0,1)) = 0
        _FrenelScale("FrenelScale",Range(0,5)) = 0
        _FrenelPow("FrenelPow",Range(0,10)) = 5
        _FrenelColor("FrenelColor",Color) = (1,1,1,1)
        _SpecularScale("SpecularScale",Range(1,10)) = 1
        
        _AlphaFrenelBias("AlphaFrenelBias",Range(0,1)) = 0
        _AlphaFrenelScale("AlphaFrenelScale",Range(0,5)) = 0
        _AlphaFrenelPow("AlphaFrenelPow",Range(0,10)) = 5
        
        
        _OcclusionStrength("Occlusion Strength", Range(0.0, 1.0)) = 1.0
        _Metallic("Metallic", Range(-1, 1)) = 0.0
        _Smoothness("Smoothness", Range(-1, 1)) = 0.5
        _EmissionMap("Emission", 2D) = "white" {}
        [HDR] _EmissionColor("Emission Color", Color) = (0,0,0,1)


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
            // #define _ICE
            // #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
            //
            //
            // #include "Assets/Resource/Shader/ShaderLibrary/ShadingModels.hlsl"
            //改为
            #define _ICE

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Assets/Resource/Shader/ShaderLibrary/SurfaceData.hlsl"

            // 兼容拼写：scaterringColor -> scatteringColor
            #define scaterringColor scatteringColor

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
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
                float4 screenPos : TEXCOORD7;
            };

            // 材质属性
            TEXTURE2D(_BaseMap);     SAMPLER(sampler_BaseMap);
            TEXTURE2D(_BumpMap);     SAMPLER(sampler_BumpMap);
            TEXTURE2D(_ORMMap);      SAMPLER(sampler_ORMMap);
            TEXTURE2D(_EmissionMap); SAMPLER(sampler_EmissionMap);
            TEXTURE2D(_HeightMap);   SAMPLER(sampler_HeightMap);
            TEXTURE2D(_MatcapMap);   SAMPLER(sampler_MatcapMap);
            TEXTURE2D(_InnerMap);    SAMPLER(sampler_InnerMap);
            TEXTURE2D(_NoiseMap);    SAMPLER(sampler_NoiseMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half4 _BaseColor;
                half _Metallic;
                half _Smoothness;
                half _BumpScale;
                half _OcclusionStrength;
                half4 _EmissionColor;
                half _MatcapIntensity;
                half _Height;
                half _FrenelBias;
                half _FrenelScale;
                half _FrenelPow;

                half _AlphaFrenelBias;
                half _AlphaFrenelScale;
                half _AlphaFrenelPow;
                half4 _FrenelColor;
                half4 _InnerColor;
                half4 _ScatterColor;
                half _Distance;
                half _Alpha;
                half _SpecularScale;
                half _HeightTiling;
                half _RefractIntensity;
            CBUFFER_END

            half2 BumpOffset(float2 uv,half3 viewDir,half height)
            {

                half2 offset = (viewDir.xy/viewDir.z) * height;
                uv = uv + offset;
                return uv;
            }

            half3 matCapColor(half3 N,half3 V,float3 P)
            {
                half3 normalVS = TransformWorldToView(N);
                float3 positionVS = TransformWorldToView(P);
                float3 r = reflect(positionVS, normalVS);
                float m = 2.0f * sqrt(pow( r.x, 2.0f) + pow( r.y, 2.0f) + pow( r.z + 1.0, 2.0f));
                half2 capCoord = (r.xy / m) + 0.5;
                half3 result= SAMPLE_TEXTURE2D(_MatcapMap, sampler_MatcapMap, capCoord).rgb * _MatcapIntensity;
                return result;
            }


            half Frenel(half3 n, half3 v, half powIntensity)
            {
                half NdotV = saturate(dot(n,v));
                half f = pow(1.0 - NdotV,powIntensity);
                f = saturate(f);
                return f;
            }

            half3 SpiralBlur(float4 positionCS,int RadialSteps,int DistanceSteps,half Distance,Varyings input)
            {
                
                float2 ScenePixels = positionCS;
                float2 RandomSamp = ((uint)(ScenePixels.x) + 2 * (uint)(ScenePixels.y)) % 5;
                RandomSamp = SAMPLE_TEXTURE2D(_NoiseMap,sampler_NoiseMap,RandomSamp).r;
                RandomSamp/=5;
                RandomSamp-=0.5;

                
                half3 normalTS = SAMPLE_TEXTURE2D(_BumpMap,sampler_BumpMap,RandomSamp).r;

                half3 normalWS = TransformTangentToWorld(normalTS,half3x3(input.tangentWS.xyz, cross(input.normalWS.xyz,input.tangentWS.xyz) * input.tangentWS.w ,input.normalWS.xyz));
                normalWS = NormalizeNormalPerPixel(normalWS);
                
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
                            sampler_CameraOpaqueTexture, NewUV + normalWS.xy * _RefractIntensity);
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
                output.screenPos = ComputeScreenPos(output.positionCS);
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {

                half3 bitTangentWS = cross(input.normalWS, input.tangentWS.xyz) * input.tangentWS.w;
                half3x3 TBN = half3x3(input.tangentWS.xyz,bitTangentWS.xyz,input.normalWS.xyz);
                half3 V = normalize(input.viewDirWS);
                half3 viewTS = mul(TBN,V);
                half height = SAMPLE_TEXTURE2D(_HeightMap,sampler_HeightMap,input.uv * _HeightTiling).r;
                half2 uvOffset = BumpOffset(input.uv,viewTS,height * _Height);

                
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                half3 innerColor = SAMPLE_TEXTURE2D(_InnerMap,sampler_InnerMap,uvOffset);
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
                // 环境光遮蔽
                half4 mask = SAMPLE_TEXTURE2D(_ORMMap, sampler_ORMMap, input.uv);
                
                half occlusion = LerpWhiteTo(mask.r, _OcclusionStrength);
                half metallic = saturate(mask.b + _Metallic);

                
                half3 viewNormal = normalize(TransformWorldToViewDir(normalWS));
                float2 uv = viewNormal.xy * 0.5 + 0.5;

                half3 reflectColor = SAMPLE_TEXTURE2D(_MatcapMap,sampler_MatcapMap, uv) * _MatcapIntensity;
                
                
                half f = _FrenelBias + _FrenelScale * Frenel(normalWS,V,_FrenelPow);
                f = saturate(f);
                // albedo.rgb = lerp(albedo, _FrenelColor, f);
                albedo.rgb += reflectColor;

                half alphaf = _AlphaFrenelBias + _AlphaFrenelScale * Frenel(normalWS,V,_AlphaFrenelPow);
                alphaf = saturate(alphaf);
                

                InputData lightingInput = (InputData)0;
                lightingInput.positionWS = input.positionWS;
                lightingInput.normalWS = normalWS;
                lightingInput.viewDirectionWS = SafeNormalize(input.viewDirWS);
                lightingInput.shadowCoord = input.shadowCoord;
                lightingInput.fogCoord = 0;
                lightingInput.vertexLighting = half3(0, 0, 0);
                
                // 表面属性
                SurfaceData surfaceInput = (SurfaceData)0;
                // surfaceInput.thickness = f;
                surfaceInput.scaterringColor = _ScatterColor;
                surfaceInput.albedo = albedo;
                surfaceInput.alpha = alpha;
                surfaceInput.metallic = metallic;
                surfaceInput.smoothness = _Smoothness;
                surfaceInput.occlusion = occlusion;
                surfaceInput.normalTS = normalTS;
                surfaceInput.specularScale = _SpecularScale;
                // PBR光照计算
                half4 color = StandardLighting(lightingInput, surfaceInput);

                 half3 sceneColor = SpiralBlur(input.positionCS,8,32,_Distance,input);
                // float2 screenUV = input.screenPos.xy / input.screenPos.w;
                // sceneColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture,sampler_CameraOpaqueTexture, screenUV + normalWS.yz * _RefractIntensity);
                color.rgb = color * f + sceneColor;
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