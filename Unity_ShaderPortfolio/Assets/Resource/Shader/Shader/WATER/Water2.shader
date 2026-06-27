//Shader "Custom/Environment/Water2"
//{
//    Properties
//    {
//        _ShallowColor("浅水颜色",Color) = (0.2,0.6,0.8,1)
//        _DeepColor("深水颜色",Color) = (0.1,0.3,0.5,1)
//        [HDR]_mScatterColor("ScatterColor",Color) = (0.5,0.5,0.5,1)
//        _BumpMap("NormalMap",2D) = "bump"{}
//        _FoamMap("FoamMap",2D) = "black"{}
//        _CausticMap("CausticMap",2D) = "white"{}
//        
//        
//        [Header(Flow)]
//        _FlowX("FlowX",Range(-1,1)) = 0.2
//        _FlowY("FlowY",Range(-1,1)) = 0.3
//        _FlowSpeed("FlowSpeed",Range(-10,10)) = 1
//        _Tiling1("Tiling1",Range(0,100)) = 1
//        _Tiling2("Tiling2",Range(0,100)) = 1
//        
//        [Header(Reflection)]
//        _DepthGradient("DepthFade",Range(0,5)) = 1
//        _WaterClean("WaterClean",Range(0,3)) = 1
//        _RefractionStrength("Refraction",Range(0,1)) = 0.1
//        _ReflecionDistortion("ReflecionDistortion",Range(0,1)) = 0.1
//        _ReflectionIntensity("ReflectionIntensity",Range(0,5)) = 0.1
//        
//        [Header(Wave)]
//        _NoiseMap("NoiseMap",2D) = "white"{}
//        _HeightTilingX("HeightTilingX",Range(0,2)) = 1
//        _HeightTilingY("HeightTilingY",Range(0,2)) = 1
//        _HeightFactor("HeightFactor",Range(0,0.01)) = 1
//        _FlowVertexDirX("FlowVertexDirX",Range(0,10)) = 1
//        _FlowVertexDirY("FlowVertexDirY",Range(0,10)) = 1
//        //定点偏移
//        
//        [Header(Foam)]
//        _FoamDepth("FoamDepth",Range(0,10)) = 1
//        _FoamIntensity("FoamIntesnity",Range(0,100)) = 0.1
//        _FoamTiling("FoamTiling",Range(0,10)) = 1
//        
//        [Header(Caustic)]
//        
//        _CausticDepth("CausticDepth",Range(0,10)) = 1
//        _CausticIntensity("CausticIntesnity",Range(0,100)) = 0.1
//        _CausticTiling("CausticTiling",Range(0,100)) = 1
//        _Channel_Offset("CausticOffset",Vector) = (0.1,0.2,0.3,1)
//        _CausticSpeed("CausticSpeed",Range(0,10)) = 1
//        
////        [Header(Wave Settings)]
////        _WaveAmplitude1("Wave 1 Amplitude", Range(0, 2)) = 0.5
////        _WaveLength1("Wave 1 Length", Range(0, 50)) = 10
////        _WaveSpeed1("Wave 1 Speed", Range(0, 5)) = 1
////        _WaveDirection1("Wave 1 Direction", Range(0, 360)) = 0
////        
////        _WaveAmplitude2("Wave 2 Amplitude", Range(0, 2)) = 0.4
////        _WaveLength2("Wave 2 Length", Range(0, 50)) = 8
////        _WaveSpeed2("Wave 2 Speed", Range(0, 5)) = 1.2
////        _WaveDirection2("Wave 2 Direction", Range(0, 360)) = 45
////        
////        _WaveAmplitude3("Wave 3 Amplitude", Range(0, 2)) = 0.3
////        _WaveLength3("Wave 3 Length", Range(0, 50)) = 15
////        _WaveSpeed3("Wave 3 Speed", Range(0, 5)) = 0.8
////        _WaveDirection3("Wave 3 Direction", Range(0, 360)) = 90
////        
////        _WaveAmplitude4("Wave 4 Amplitude", Range(0, 2)) = 0.2
////        _WaveLength4("Wave 4 Length", Range(0, 50)) = 20
////        _WaveSpeed4("Wave 4 Speed", Range(0, 5)) = 0.6
////        _WaveDirection4("Wave 4 Direction", Range(0, 360)) = 135
////        
////        _WaveAmplitude5("Wave 5 Amplitude", Range(0, 2)) = 0.15
////        _WaveLength5("Wave 5 Length", Range(0, 50)) = 25
////        _WaveSpeed5("Wave 5 Speed", Range(0, 5)) = 0.4
////        _WaveDirection5("Wave 5 Direction", Range(0, 360)) = 180
////        
////        _WaveAmplitude6("Wave 6 Amplitude", Range(0, 2)) = 0.1
////        _WaveLength6("Wave 6 Length", Range(0, 50)) = 30
////        _WaveSpeed6("Wave 6 Speed", Range(0, 5)) = 0.3
////        _WaveDirection6("Wave 6 Direction", Range(0, 360)) = 225
//    }
//    SubShader
//    {
//        Tags 
//        { 
//            "RenderType"="Transparent"
//            "Renderpipeline" = "UniversalPipeline"
//            "Queue" = "Geometry"   
//        }
//        Blend One Zero
//        Cull Off
//        LOD 100
//
//        Pass
//        {
//            Name "ForwardLit"
//            Tags {"LightMode" = "UniversalForward"}
//            HLSLPROGRAM
//            
//            #pragma vertex vert
//            #pragma fragment frag
//            #pragma enable_d3d11_debug_symbols
//            #define _WATER
//            
//            #include "Assets/Resource/Shader/ShaderLibrary/LightingModel.hlsl"
//            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
//            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
//
//            struct Attributes
//            {
//                float4 positionOS : POSITION;
//                float3 normalOS : NORMAL;
//                float4  tangentOS : TANGENT;
//                float2 texcoord : TEXCOORD0;
//                float4 color : Color;
//            };
//
//            struct Varings
//            {
//                float4 positionCS : SV_POSITION;
//                float2 uv : TEXCOORD0;
//                float3 positionWS : TEXCOORD1;
//                float3 normalWS : TEXCOORD2;
//                float4 tangentWS : TEXCOORD3;
//                float3 viewDirWS : TEXCOORD4;
//                float4 shadowCoord : TEXCOORD5;
//
//                float4 worldUV : TEXCOORD6;
//                float4 screenPos : TEXCOORD7;
//                float height : TEXCOORD8;
//            };
//            
//            TEXTURE2D(_BumpMap);             SAMPLER(sampler_BumpMap);
//            TEXTURE2D(_PlanarReflection);    SAMPLER(sampler_PlanarReflection);
//            TEXTURE2D(_NoiseMap);            SAMPLER(sampler_NoiseMap);
//            TEXTURE2D(_FoamMap);             SAMPLER(sampler_FoamMap);
//            TEXTURE2D(_CausticMap);          SAMPLER(sampler_CausticMap);
//            
//            CBUFFER_START(UnityPerMaterial)
//                float _FlowX;
//                float _FlowY;
//                float _FlowSpeed;
//                float _Tiling1;
//                float _Tiling2;
//                float _DepthGradient;
//                float4 _ShallowColor;
//                float4 _DeepColor;
//                float4 _mScatterColor;
//                float _RefractionStrength;
//                float _ReflecionDistortion;
//                float _ReflectionIntensity;
//                float _WaterClean;
//
//            	float _HeightTilingX;
//				float _HeightTilingY;
//				float _HeightFactor;
//                float _FlowVertexDirX;
//                float _FlowVertexDirY;
//                float _FoamTiling;
//                float _FoamIntensity;
//                float _FoamDepth;
//
//                float _CausticIntensity;
//                float4 _Channel_Offset;
//                float _CausticTiling;
//                float _CausticSpeed;
//                float _CausticDepth;
//
//
//                // Wave properties
//                float _WaveAmplitude1, _WaveLength1, _WaveSpeed1, _WaveDirection1;
//                float _WaveAmplitude2, _WaveLength2, _WaveSpeed2, _WaveDirection2;
//                float _WaveAmplitude3, _WaveLength3, _WaveSpeed3, _WaveDirection3;
//                float _WaveAmplitude4, _WaveLength4, _WaveSpeed4, _WaveDirection4;
//                float _WaveAmplitude5, _WaveLength5, _WaveSpeed5, _WaveDirection5;
//                float _WaveAmplitude6, _WaveLength6, _WaveSpeed6, _WaveDirection6;
//                
//            CBUFFER_END
//
//
//    
//
//
//
//            Varings vert(Attributes input)
//            {
//                Varings output;
//
//                float3 waveDisplacement = float3(0, 0, 0);
//                float3 tangent = float3(1, 0, 0);
//                float3 binormal = float3(0, 0, 1);
//                
//                // Apply all 6 Gerstner waves
//                // waveDisplacement += GerstnerWave(input.positionOS.xyz, _WaveAmplitude5, _WaveLength5, _WaveSpeed5, _WaveDirection5, tangent, binormal);
//                // waveDisplacement += GerstnerWave(input.positionOS.xyz, _WaveAmplitude6, _WaveLength6, _WaveSpeed6, _WaveDirection6, tangent, binormal);
//
//                input.positionOS.xyz += waveDisplacement * _HeightFactor;
//                float3 normal = normalize(cross(binormal, tangent));
//                half3 normalWS = TransformObjectToWorldNormal(normal);
//                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
//                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS,input.tangentOS);
//                
//                //
//                // output.worldUV.xy = vertexInput.positionWS.xz * 0.001 *  _Tiling1;
//                // output.worldUV.zw = vertexInput.positionWS.xz * 0.001 *  _Tiling2;
//
//                // half4 screenUV2 = ComputeScreenPos(vertexInput.positionCS);
//                // // float sceneDepth = SampleSceneDepth(screenUV2);
//                // float sceneDepth = SAMPLE_TEXTURE2D_LOD(_CameraDepthTexture, sampler_CameraDepthTexture, UnityStereoTransformScreenSpaceTex(screenUV2),0).r;
//                // float waterDepth = sceneDepth - vertexInput.positionCS.z / vertexInput.positionCS.w;
//                //
//                // waterDepth = max(0,waterDepth);
//
//                
//                float2 flowDir = _Time.x * float2(_FlowVertexDirX,_FlowVertexDirY);
//                float2 uv = vertexInput.positionWS.xz * 0.01;
//                float2 offsetUV = uv * half2(_HeightTilingX,_HeightTilingY);
//                float2 offsetUV1 = offsetUV + flowDir;
//                float2 offsetUV2 = (offsetUV + float2(0.4,0.35)) * 1.6 + flowDir;
//                
//                half height1 = SAMPLE_TEXTURE2D_LOD(_NoiseMap,sampler_NoiseMap,offsetUV1,0);
//                half height2 = SAMPLE_TEXTURE2D_LOD(_NoiseMap,sampler_NoiseMap,offsetUV2,0);
//                half offset = (height1 + height2) * _HeightFactor;
//                
//
//                
//                input.positionOS.xyz += float3(0,0,offset);
//                vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
//
//                output.positionCS = vertexInput.positionCS;
//                output.positionWS = vertexInput.positionWS;
//                output.normalWS = normalInput.normalWS;
//                output.tangentWS = float4(normalInput.tangentWS,input.tangentOS.w * GetOddNegativeScale());
//                output.uv = input.texcoord;
//                output.viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
//                output.shadowCoord = GetShadowCoord(vertexInput);
//                
//                output.screenPos = ComputeScreenPos(output.positionCS);
//                output.worldUV.xy = vertexInput.positionWS.xz * 0.001 *  _Tiling1;
//                output.worldUV.zw = vertexInput.positionWS.xz * 0.001 *  _Tiling2;
//                output.height = waveDisplacement;
//                
//                
//                return output;
//                
//            }
//
//            half4 frag(Varings input,float vface : VFACE) : SV_Target
//            {
//                float2 flowDir = float2(_FlowX,_FlowY);
//                float speed = _Time.x * _FlowSpeed;
//
//                
//                half phase0 = frac(speed + 0.5);
//                half phase1 = frac(speed + 1.0);
//                half flowlerp = saturate(abs(0.5-phase0) / 0.5);
//                
//                //flowmap
//                half4 normalMap1 = SAMPLE_TEXTURE2D(_BumpMap,sampler_BumpMap,input.worldUV.xy + phase0 * flowDir);
//                half4 normalMap2 = SAMPLE_TEXTURE2D(_BumpMap,sampler_BumpMap,input.worldUV.xy + phase1 * flowDir);
//                half4 bump1 = lerp(normalMap1,normalMap2,flowlerp);
//                
//                bump1.xyz = UnpackNormalScale(bump1,0.25);
//
//                half4 normalMap3 = SAMPLE_TEXTURE2D(_BumpMap,sampler_BumpMap,input.worldUV.zw + phase0 * flowDir);
//                half4 normalMap4 = SAMPLE_TEXTURE2D(_BumpMap,sampler_BumpMap,input.worldUV.zw + phase1 * flowDir);
//                
//                half4 bump2 = lerp(normalMap3,normalMap4,flowlerp);
//                bump2.xyz  = UnpackNormalScale(bump2,0.25);
//                
//                half3 normalTS = lerp(bump1,bump2,0.5);
//
//
//                half4 foam1 = SAMPLE_TEXTURE2D(_FoamMap,sampler_FoamMap,input.worldUV.xy  * _FoamTiling + flowDir * speed * 2);
//                half4 foam4 = SAMPLE_TEXTURE2D(_FoamMap,sampler_FoamMap,input.worldUV.zw  * _FoamTiling + flowDir * speed * 2);
//                half4 foamlerp2 = lerp(foam1,foam4,0.5);
//
//
//                //depth fade
//                float2 screenUV = input.screenPos.xy / input.screenPos.w;
//                float sceneDepth = SampleSceneDepth(screenUV);
//                sceneDepth = LinearEyeDepth(sceneDepth,_ZBufferParams); 
//               float surfaceDepth = -TransformWorldToView(input.positionWS).z;
//                float waterDepth = sceneDepth - surfaceDepth;
//                waterDepth = max(0,waterDepth);
//
//                float depthFactor = saturate(exp2(-waterDepth * _DepthGradient));
//                float alphaFactor = 1 - saturate(exp2(-waterDepth * _WaterClean));
//                float foamFactor = saturate(exp2(-waterDepth * _FoamDepth));
//                float causitcFactor = saturate(exp2(-waterDepth * _CausticDepth));
//
//                half4 albedo = lerp(_DeepColor,_ShallowColor,depthFactor) + foamlerp2.r  * _FoamIntensity * foamFactor;
//                
//                half3 normalWS = TransformTangentToWorld(normalTS,half3x3(input.tangentWS.xyz, cross(input.normalWS.xyz,input.tangentWS.xyz) * input.tangentWS.w ,input.normalWS.xyz));
//                normalWS = NormalizeNormalPerPixel(normalWS);
//
//                half2 distortedUV = screenUV + normalWS.xz * _RefractionStrength;
//                half sceneDistortDepth = SampleSceneDepth(distortedUV);
//                sceneDistortDepth = LinearEyeDepth(sceneDistortDepth,_ZBufferParams); 
//                half tmp = step(saturate(sceneDistortDepth - surfaceDepth),0);
//
//                
//                distortedUV.xy = tmp * screenUV + (1 - tmp) * distortedUV;
//
//                half2 reflectionDistortion = normalWS.xz * _ReflecionDistortion;
//                half4 reflectionColor = SAMPLE_TEXTURE2D(_PlanarReflection,sampler_PlanarReflection,screenUV + reflectionDistortion) * _ReflectionIntensity;
//                
//                float3 underWaterColor = SampleSceneColor(distortedUV);
//
//
//                //焦散
//                float3 channel_offset = _Channel_Offset * 0.01;
//                speed *= _CausticSpeed;
//                float r1 = SAMPLE_TEXTURE2D(_CausticMap, sampler_CausticMap, input.worldUV.xy * _CausticTiling + speed * flowDir + channel_offset.x).r;
//                float g1= SAMPLE_TEXTURE2D(_CausticMap, sampler_CausticMap, input.worldUV.xy * _CausticTiling + speed * flowDir + channel_offset.y).g;
//                float b1 = SAMPLE_TEXTURE2D(_CausticMap, sampler_CausticMap, input.worldUV.xy * _CausticTiling + speed * flowDir + channel_offset.z).b;
//                half3 caustics1 = half3(r1, g1, b1) * _CausticIntensity;
//                
//                float r2 = SAMPLE_TEXTURE2D(_CausticMap, sampler_CausticMap,   0.8 * speed * flowDir - input.worldUV.xy * _CausticTiling + channel_offset.x).r;
//                float g2 = SAMPLE_TEXTURE2D(_CausticMap, sampler_CausticMap, 0.8 * speed * flowDir - input.worldUV.xy * _CausticTiling + channel_offset.y).g;
//                float b2 = SAMPLE_TEXTURE2D(_CausticMap, sampler_CausticMap, 0.8 * speed * flowDir - input.worldUV.xy * _CausticTiling + channel_offset.z).b;
//                half3 caustics2 = half3(r2, g2, b2) * _CausticIntensity;
//                half3 caustic = min(caustics1,caustics2) * causitcFactor;
//
//                albedo.rgb += caustic;
//
//                normalWS *= vface > 0 ? 1: -1;
//
//                InputData lightingInput = (InputData) 0;
//                
//                lightingInput.positionWS = input.positionWS;
//                lightingInput.normalWS = normalWS;
//                lightingInput.viewDirectionWS = SafeNormalize(input.viewDirWS);
//                lightingInput.shadowCoord = input.shadowCoord;
//                lightingInput.fogCoord = 0;
//                lightingInput.vertexLighting = 0;
//
//                SurfaceData surfaceData = (SurfaceData) 0;
//                
//                surfaceData.albedo = albedo;
//                surfaceData.alpha = 1;
//                surfaceData.metallic = 0;
//                surfaceData.smoothness = 0.92;
//                surfaceData.occlusion = 1;
//                surfaceData.normalTS = normalTS;
//                surfaceData.reflectionColor = reflectionColor;
//                surfaceData.scaterringColor = _mScatterColor;
//
//                
//
//                half4 color = StandardLighting(lightingInput,surfaceData);
//                color.rgb = color * alphaFactor + (1 - alphaFactor) * underWaterColor;
//                return color;
//                                
//            }
//            
//            ENDHLSL
//
//        }
//        
//    }
//}
