Shader "Custom/Tree" 
{
    Properties
    {
        // Base
        _BaseMap("Base Map (RGBA)", 2D) = "white" {}
        _BaseColor("Base Color", Color) = (1,1,1,1)
        _Cutoff("Alpha Cutoff", Range(0, 1)) = 0.5

        // Normal
        [Normal]_BumpMap("Normal Map", 2D) = "bump" {}
        _BumpScale("Bump Scale", Range(0, 2)) = 1.0

        // ORM: R=AO, G=Roughness, B=Metallic
        _ORMMap("ORM Map", 2D) = "white" {}
        _OcclusionStrength("Occlusion Strength", Range(0,1)) = 1.0
        _Smoothness("Smoothness", Range(0,1)) = 0.0
        _Metallic("Metallic", Range(0,1)) = 0.0
        
        //风动
        [Header(WindSettings)]
        _WindDirection("Wind Direction", Vector) = (0,0,0,0)
        _WindSpeed("Wind Speed", Range(0,5)) = 1.0
        _WindStrength("Wind Strength", Range(0,2)) = 1
        // ✅ 统一拼写：必须和 CBUFFER/代码一致
        _WindFrequency("Wind Frequency", Range(0,2)) = 1
        _WindTurbulence("Wind Turbulence", Range(0,2)) = 0.2

        _LeafFlutter("Leaf Flutter", Range(0,1)) = 0.2
        _HeightInfluence("Height Influence", Range(0,5)) = 1.0

        // ✅ 防“吹飞”：默认用 UV.y 做叶片权重（叶柄=0，叶尖=1）
        [Toggle]_UseUVWindWeight("Use UV.y As Wind Weight (Leaves)", Float) = 1
        [Toggle]_InvertUVWindWeight("Invert UV Weight", Float) = 0

        // Scatter (Foliage)
        [HDR]_ScatterColor("Scatter Color", Color) = (1,1,1,1)
        _Scatter("Scattering", Range(0,2)) = 1.0
        _ScatterMap("Scatter Map", 2D) = "white" {}

        // Render Face
        [Enum(Front,2,Back,1,Both,0)] _Cull("Render Face", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "RenderType"="TransparentCutout"
            "RenderPipeline"="UniversalPipeline"
            "Queue"="AlphaTest"
        }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            Cull [_Cull]
            ZWrite On
            AlphaToMask On

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma multi_compile_fragment _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHTS_VERTEX

            #define _FOLIAGE

            #include "Assets/Resource/Shader/ShaderLibrary/ShadingModels4_my.hlsl"

            // 贴图声明
            TEXTURE2D(_BaseMap);     SAMPLER(sampler_BaseMap);
            TEXTURE2D(_BumpMap);     SAMPLER(sampler_BumpMap);
            TEXTURE2D(_ORMMap);      SAMPLER(sampler_ORMMap);
            TEXTURE2D(_ScatterMap);  SAMPLER(sampler_ScatterMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _BaseMap_ST;
                float  _Cutoff;

                float  _BumpScale;

                float4 _ORMMap_ST;
                float  _OcclusionStrength;
                float  _Smoothness;
                float  _Metallic;

                float4 _ScatterColor;
                float  _Scatter;
                float4 _ScatterMap_ST;

                //风
                float4 _WindDirection;
                float  _WindSpeed;
                float  _WindStrength;
                float  _WindFrequency;
                float  _WindTurbulence;

                float  _LeafFlutter;
                float  _HeightInfluence;

                // ✅ 防“吹飞”的开关
                float  _UseUVWindWeight;
                float  _InvertUVWindWeight;

                float  _Cull;
            CBUFFER_END
            
            
            float3 CalculateWind(float3 positionOS, float heightFactor, float time)
            {
                float3 windDir = normalize(_WindDirection.xyz);

                float baseWind = sin(time * _WindFrequency) * _WindStrength;

                float turbulence =
                    sin(time * _WindFrequency * 2.7 + positionOS.x) *
                    cos(time * _WindFrequency * 1.3 + positionOS.z) *
                    _WindTurbulence;

                // ✅ 这里原来 _LeafFlutter 报错：现在已补齐
                float leafFlutter = sin(time * _WindFrequency * 4.0 + positionOS.y * 5.0) * _LeafFlutter;

                float windEffect = (baseWind + turbulence + leafFlutter) * heightFactor;
                return windEffect * windDir;
            }


            inline half LerpWhiteTo(half v, half t)
            {
                return lerp(1.0h, v, t);
            }

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float4 tangentOS  : TANGENT;   // ✅ 法线贴图必须要 TANGENT
                float2 uv         : TEXCOORD0; // ✅ 同时用于贴图采样 + 叶片风权重
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;

                float2 uv         : TEXCOORD0;
                float3 positionWS : TEXCOORD1;

                half3  normalWS   : TEXCOORD2;
                half4  tangentWS  : TEXCOORD3; // xyz=tangent, w=sign

                float4 shadowCoord : TEXCOORD4;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                // ===== 风动（防止叶片“整体飞走”）=====
                // 树干/枝干权重：从 object space y 推一个 0~1，再做 pow
                float trunkWeight = pow(saturate(input.positionOS.y), 3.0);

                // 叶片权重：用 UV.y（叶柄 0，叶尖 1）
                float uvWeight = saturate(input.uv.y);
                uvWeight = lerp(uvWeight, 1.0 - uvWeight, _InvertUVWindWeight);
                float leafWeight = pow(uvWeight, 2.0);

                // 最终：叶片材质用 leafWeight，树干材质用 trunkWeight（由开关控制）
                float heightFactor = lerp(trunkWeight, leafWeight, _UseUVWindWeight) * _HeightInfluence;

                float time = _Time.y * _WindSpeed;
                float3 windOffset = CalculateWind(input.positionOS.xyz, heightFactor, time);

                input.positionOS.xyz += windOffset;

                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionCS = TransformWorldToHClip(output.positionWS);

                output.normalWS = TransformObjectToWorldNormal(input.normalOS);

                float3 tWS = TransformObjectToWorldDir(input.tangentOS.xyz);
                output.tangentWS = half4(normalize(tWS), input.tangentOS.w * GetOddNegativeScale());

                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);

                output.shadowCoord = TransformWorldToShadowCoord(output.positionWS);
                return output;
            }

            
            half4 frag(Varyings IN, FRONT_FACE_TYPE vface : FRONT_FACE_SEMANTIC) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(IN);

                // ===== BaseMap + Alpha =====
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
                half3 albedo = baseMap.rgb * _BaseColor.rgb;
                half  alpha  = baseMap.a   * _BaseColor.a;
                clip(alpha - _Cutoff);

                // ===== Teacher block: Normal + ORM + Scatter =====
                // 1) Normal
                half4 normalSample = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, IN.uv);
                half3 normalTS = UnpackNormalScale(normalSample, _BumpScale);

                half3 normalWS = TransformTangentToWorld(
                    normalTS,
                    half3x3(
                        IN.tangentWS.xyz,
                        cross(IN.normalWS, IN.tangentWS.xyz) * IN.tangentWS.w,
                        IN.normalWS
                    )
                );
                normalWS = NormalizeNormalPerPixel(normalWS);

                // normalWS *= vface > 0 ? 1 : -1;
                normalWS *= (IS_FRONT_VFACE(vface, true, false) ? 1.0 : -1.0);

                // 2) ORM / AO / Smoothness / Metallic
                half4 mask = SAMPLE_TEXTURE2D(_ORMMap, sampler_ORMMap, IN.uv);

                half4 scatterColor = SAMPLE_TEXTURE2D(_ScatterMap, sampler_ScatterMap, IN.uv) * _ScatterColor;

                half occlusion  = LerpWhiteTo(mask.r, _OcclusionStrength);
                half smoothness = saturate(1.0h - mask.g + _Smoothness);
                half metallic   = saturate(mask.b + _Metallic);

                InputData lightingInput = (InputData)0;
                lightingInput.positionWS      = IN.positionWS;
                lightingInput.normalWS        = normalWS;
                lightingInput.viewDirectionWS = SafeNormalize(_WorldSpaceCameraPos - IN.positionWS);
                lightingInput.shadowCoord     = IN.shadowCoord;
                lightingInput.fogCoord        = 0;
                lightingInput.vertexLighting  = half3(0,0,0);

                SurfaceData surfaceInput = (SurfaceData)0;
                surfaceInput.albedo     = albedo;
                surfaceInput.alpha      = alpha;
                surfaceInput.metallic   = metallic;
                surfaceInput.smoothness = smoothness;
                surfaceInput.occlusion  = occlusion;
                surfaceInput.normalTS   = half3(0,0,1);
                surfaceInput.emission   = 0;
                surfaceInput.specular   = 0;
                surfaceInput.clearCoatMask = 0;
                surfaceInput.clearCoatSmoothness = 0;

                surfaceInput.scaterringColor = scatterColor * _Scatter;

                return StandardLighting(lightingInput, surfaceInput);
            }

            ENDHLSL
        }
    }
}
