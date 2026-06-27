Shader "Custom/Environment/Water1_GentleShoreWake"
{
    Properties
    {
        _BaseMap   ("BaseMap", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (1,1,1,1)

        _Roughness ("Roughness", Range(0,1)) = 0.08
        _Metallic  ("Metallic",  Range(0,1)) = 0
        _Occlusion ("Occlusion", Range(0,1)) = 1

        _BumpMap   ("Normal Map", 2D) = "bump" {}
        _BumpScale ("Bump Scale", Range(0,3)) = 0.62

        _FlowX     ("Flow X", Range(-1,1)) = -0.55
        _FlowY     ("Flow Y", Range(-1,1)) = 0
        _FlowSpeed ("Flow Speed", Range(-10,10)) = 1.15

        _Tiling    ("Tiling1", Range(0,1000)) = 34
        _Tiling2   ("Tiling2", Range(0,1000)) = 92

        _ScatteringColor ("Scatter Color", Color) = (0.58,0.72,0.80,1)
        _ShallowColor ("Shallow Color", Color) = (0.54,0.86,0.88,1)
        _DeepColor    ("Deep Color",    Color) = (0.09,0.25,0.32,1)

        _DepthGradient ("Depth Fade", Range(0,5)) = 1.05
        _WaterClean    ("Water Clean", Range(0,3)) = 0.42

        _RefractionStrength   ("Refraction", Range(0,1)) = 0.28
        _ReflecionDistortion  ("Reflection Distortion", Range(0,1)) = 0.18
        _ReflectionIntensity  ("Reflection Intensity", Range(0,5)) = 0.9

        _FoamMap ("Foam Map", 2D) = "black" {}
        _FoamDepth ("Foam Depth", Range(0,10)) = 1.4
        _FoamIntensity ("Foam Intensity", Range(0,100)) = 0.35
        _FoamTiling ("Foam Tiling", Range(0,10)) = 1

        [Header(Caustics)]
        _CausticMap ("Caustic Map (RGB)", 2D) = "white" {}
        _CausticTiling ("Caustic Tiling", Range(0,10)) = 1
        _CausticSpeed ("Caustic Speed", Range(0,10)) = 0.65
        _CausticIntensity ("Caustic Intensity", Range(0,5)) = 0.25
        _Channel_Offset ("Channel Offset (0-100)", Vector) = (0,33,67,0)

        [Header(Showcase Color And Transparency)]
        _WaterBrightness ("Water Brightness", Range(0,5)) = 1.35
        _MinWaterColor ("Minimum Water Color", Color) = (0.06,0.16,0.20,1)
        _SceneColorBlend ("Scene Color Blend", Range(0,1)) = 0.68
        _SurfaceOpacity ("Surface Opacity", Range(0,1)) = 0.36
        _FresnelPower ("Fresnel Power", Range(0.5,10)) = 4.0
        _FresnelIntensity ("Fresnel Reflection", Range(0,3)) = 0.75
        _SpecularBoost ("Specular Boost", Range(0,3)) = 0.55

        [Header(Gerstner Waves)]
        _GerstnerDirA ("Gerstner Dir A (XZ)", Vector) = (1,0,0,0)
        _GerstnerDirB ("Gerstner Dir B (XZ)", Vector) = (0.7,0.7,0,0)
        _GerstnerDirC ("Gerstner Dir C (XZ)", Vector) = (-0.6,0.8,0,0)
        _GerstnerAmpA ("Gerstner Amp A", Range(0,0.2)) = 0.006
        _GerstnerAmpB ("Gerstner Amp B", Range(0,0.2)) = 0.004
        _GerstnerAmpC ("Gerstner Amp C", Range(0,0.2)) = 0.002
        _GerstnerLengthA ("Gerstner Length A", Range(0.2,20)) = 6.0
        _GerstnerLengthB ("Gerstner Length B", Range(0.2,20)) = 4.2
        _GerstnerLengthC ("Gerstner Length C", Range(0.2,20)) = 2.8
        _GerstnerSteepness ("Gerstner Steepness", Range(0,1)) = 0.04
        _GerstnerSpeed ("Gerstner Speed", Range(0,5)) = 0.38
        _GerstnerVertexStrength ("Gerstner Vertex Strength", Range(0,10)) = 1.0

        [Header(Edge And Shore Foam)]
        _EdgeWidth ("Edge Width", Range(0,5)) = 1.2
        _EdgeWaveBoost ("Edge Wave Boost", Range(0,3)) = 0.18
        _EdgeFoamBoost ("Edge Foam Boost", Range(0,5)) = 0.55
        _ShoreFoamWidth ("Shore Foam Width", Range(0,1)) = 0.32
        _ShoreFoamSoftness ("Shore Foam Softness", Range(0.01,1)) = 0.25
        _ShoreFoamSpeed ("Shore Foam Speed", Range(0,5)) = 0.65
        _ShoreFoamTiling ("Shore Foam Tiling", Range(0,10)) = 1.15
        _ShoreFoamIntensity ("Shore Foam Intensity", Range(0,10)) = 0.75
        _ShoreFoamContrast ("Shore Foam Contrast", Range(0.1,8)) = 1.15
        _ShoreEdgeAssist ("Shore Edge Assist", Range(0,2)) = 0.8

        [Header(Contact Mouse Wake Foam)]
        _WakePositionWS ("Wake Position WS", Vector) = (0,0,0,0)
        _WakeDirectionWS ("Wake Direction WS", Vector) = (1,0,0,0)
        _WakeActive ("Wake Active", Range(0,1)) = 0
        _WakeRadius ("Contact Foam Width", Range(0.05,20)) = 3.0
        _WakeStrength ("Wake Height Strength", Range(0,2)) = 0.16
        _WakeFoamStrength ("Contact Foam Intensity", Range(0,20)) = 1.8
        _WakeNormalStrength ("Wake Normal Strength", Range(0,20)) = 3.2
        _WakeSpeed ("Wake Speed", Range(0,20)) = 0
        _WakeRippleFrequency ("Wake Ripple Frequency", Range(1,80)) = 16
        _WakeRippleSpeed ("Wake Ripple Speed", Range(0,30)) = 5
        _ContactFoamSoftness ("Contact Foam Softness", Range(0.01,2)) = 0.7
        _ContactFoamWhiteness ("Contact Foam Whiteness", Range(0,1)) = 0.65
    }

    SubShader
    {
        Tags
        {
            "RenderType"="Transparent"
            "RenderPipeline"="UniversalRenderPipeline"
            "Queue"="Transparent"
        }

        // Original project manually blends with SceneColor, so keep opaque blend state.
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

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile_fog

            #define _WATER

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
            #include "Assets/Resource/Shader/Shaderlibrary/SurfaceData.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Assets/Resource/Shader/Shaderlibrary/LightingModel.hlsl"
            #include "Assets/Resource/Shader/Shaderlibrary/CustomBRDF_Water.hlsl"

            #define WATER_PI 3.14159265359
            #define WATER_TWO_PI 6.28318530718

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
                float4 worldUV     : TEXCOORD6;
                float4 screenPos   : TEXCOORD7;
                float  edgeMask    : TEXCOORD8;
            };

            TEXTURE2D(_BaseMap);           SAMPLER(sampler_BaseMap);
            TEXTURE2D(_BumpMap);           SAMPLER(sampler_BumpMap);
            TEXTURE2D(_FoamMap);           SAMPLER(sampler_FoamMap);
            TEXTURE2D(_PlanarReflection);  SAMPLER(sampler_PlanarReflection);
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

                float  _CausticTiling;
                float  _CausticSpeed;
                float  _CausticIntensity;
                float4 _Channel_Offset;

                float  _WaterBrightness;
                float4 _MinWaterColor;
                float  _SceneColorBlend;
                float  _SurfaceOpacity;
                float  _FresnelPower;
                float  _FresnelIntensity;
                float  _SpecularBoost;

                float4 _GerstnerDirA;
                float4 _GerstnerDirB;
                float4 _GerstnerDirC;
                float  _GerstnerAmpA;
                float  _GerstnerAmpB;
                float  _GerstnerAmpC;
                float  _GerstnerLengthA;
                float  _GerstnerLengthB;
                float  _GerstnerLengthC;
                float  _GerstnerSteepness;
                float  _GerstnerSpeed;
                float  _GerstnerVertexStrength;

                float  _EdgeWidth;
                float  _EdgeWaveBoost;
                float  _EdgeFoamBoost;
                float  _ShoreFoamWidth;
                float  _ShoreFoamSoftness;
                float  _ShoreFoamSpeed;
                float  _ShoreFoamTiling;
                float  _ShoreFoamIntensity;
                float  _ShoreFoamContrast;
                float  _ShoreEdgeAssist;

                float4 _WakePositionWS;
                float4 _WakeDirectionWS;
                float  _WakeActive;
                float  _WakeRadius;
                float  _WakeStrength;
                float  _WakeFoamStrength;
                float  _WakeNormalStrength;
                float  _WakeSpeed;
                float  _WakeRippleFrequency;
                float  _WakeRippleSpeed;
                float  _ContactFoamSoftness;
                float  _ContactFoamWhiteness;
            CBUFFER_END

            float2 SafeNormalize2(float2 v)
            {
                return v / max(length(v), 0.0001);
            }

            void ApplyGerstnerWave(inout float3 positionWS, float2 dir, float amplitude, float wavelength, float phaseOffset)
            {
                dir = SafeNormalize2(dir);
                float k = WATER_TWO_PI / max(wavelength, 0.001);
                float phase = k * dot(dir, positionWS.xz) + _Time.y * _GerstnerSpeed + phaseOffset;
                float s = sin(phase);
                float c = cos(phase);
                float amp = amplitude * _GerstnerVertexStrength;

                positionWS.xz += dir * (c * amp * _GerstnerSteepness);
                positionWS.y += s * amp;
            }

            void ComputeWake(float3 positionWS, out float wakeMask, out float wakeRipple, out float2 wakeDir)
            {
                float active = saturate(_WakeActive);
                float radius = max(_WakeRadius, 0.001);

                float2 delta = positionWS.xz - _WakePositionWS.xz;
                float dist = length(delta);

                wakeDir = SafeNormalize2(_WakeDirectionWS.xz);
                float2 sideDir = float2(-wakeDir.y, wakeDir.x);

                // Positive behindDist means the point is behind the moving mouse.
                float behindDist = dot(delta, -wakeDir);
                float sideDist = abs(dot(delta, sideDir));

                float contact = saturate(1.0 - dist / (radius * 0.65));
                contact = pow(contact, 1.6);

                float trailLength = radius * 3.2;
                float trailWidth = radius * 0.42;
                float behind = smoothstep(-radius * 0.15, radius * 0.25, behindDist) * saturate(1.0 - behindDist / trailLength);
                float side = smoothstep(trailWidth, 0.0, sideDist);
                float trail = saturate(behind * side);

                float speedMask = saturate(0.35 + _WakeSpeed * 0.09);
                wakeMask = saturate(max(contact * 0.55, trail) * active * speedMask);

                float t = _Time.y * _WakeRippleSpeed;
                float rippleA = sin(dist * _WakeRippleFrequency - t);
                float rippleB = sin((behindDist * 0.85 + sideDist * 1.6) * _WakeRippleFrequency * 0.55 - t * 1.4);
                wakeRipple = (rippleA * 0.5 + rippleB * 0.5) * wakeMask;
            }

            float ComputeEdgeMask(float2 uv)
            {
                float2 edgeDist = min(uv, 1.0 - uv);
                float d = min(edgeDist.x, edgeDist.y);
                float width = saturate(_ShoreFoamWidth);
                float softness = max(_ShoreFoamSoftness, 0.001);
                return 1.0 - smoothstep(width, width + softness, d);
            }

            Varyings vert(Attributes input)
            {
                Varyings o;

                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);

                float edgeMask = ComputeEdgeMask(input.texcoord);
                float edgeWaveMult = 1.0 + edgeMask * _EdgeWaveBoost;

                float3 wavePos = positionWS;
                ApplyGerstnerWave(wavePos, _GerstnerDirA.xy, _GerstnerAmpA * edgeWaveMult, _GerstnerLengthA, 0.0);
                ApplyGerstnerWave(wavePos, _GerstnerDirB.xy, _GerstnerAmpB * edgeWaveMult, _GerstnerLengthB, 1.7);
                ApplyGerstnerWave(wavePos, _GerstnerDirC.xy, _GerstnerAmpC * edgeWaveMult, _GerstnerLengthC, 3.1);

                float wakeMask;
                float wakeRipple;
                float2 wakeDir;
                ComputeWake(positionWS, wakeMask, wakeRipple, wakeDir);
                wavePos.y += wakeRipple * _WakeStrength * 0.10;

                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                o.positionCS = TransformWorldToHClip(wavePos);
                o.positionWS = wavePos;
                o.normalWS = normalInput.normalWS;
                o.tangentWS = float4(normalInput.tangentWS, input.tangentOS.w * GetOddNegativeScale());
                o.uv = input.texcoord;
                o.viewDirWS = GetCameraPositionWS() - wavePos;
                o.shadowCoord = TransformWorldToShadowCoord(wavePos);
                o.screenPos = ComputeScreenPos(o.positionCS);
                o.edgeMask = edgeMask;

                float2 wsXZ = wavePos.xz * 0.01;
                o.worldUV.xy = wsXZ * _Tiling;
                o.worldUV.zw = wsXZ * _Tiling2;

                return o;
            }

            half4 frag(Varyings input, float vface : VFACE) : SV_Target
            {
                float wakeMask;
                float wakeRipple;
                float2 wakeDir;
                ComputeWake(input.positionWS, wakeMask, wakeRipple, wakeDir);

                float2 flowDir = SafeNormalize2(float2(_FlowX, _FlowY));
                float speed = _Time.x * _FlowSpeed;

                half phase0 = frac(speed + 0.5);
                half phase1 = frac(speed + 1.0);
                half flowlerp = saturate(abs(0.5 - phase0) / 0.5);

                float2 wakeUVOffset = wakeDir * wakeMask * _WakeStrength * 0.055;

                half4 n1 = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.worldUV.xy + phase0 * flowDir + wakeUVOffset);
                half4 n2 = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.worldUV.xy + phase1 * flowDir + wakeUVOffset);
                half4 bump1 = lerp(n1, n2, flowlerp);
                bump1.xyz = UnpackNormalScale(bump1, _BumpScale * (0.25h + input.edgeMask * 0.10h));

                half4 n3 = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.worldUV.zw + phase0 * flowDir - wakeUVOffset);
                half4 n4 = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.worldUV.zw + phase1 * flowDir - wakeUVOffset);
                half4 bump2 = lerp(n3, n4, flowlerp);
                bump2.xyz = UnpackNormalScale(bump2, _BumpScale * (0.25h + input.edgeMask * 0.10h));

                half3 normalTS = normalize(lerp(bump1.xyz, bump2.xyz, 0.5h));

                float2 delta = input.positionWS.xz - _WakePositionWS.xz;
                float2 radial = SafeNormalize2(delta);
                float2 wakeNormal = (radial * wakeRipple + wakeDir * wakeMask * 0.55) * (_WakeNormalStrength * 0.055);
                normalTS.xy += wakeNormal;
                normalTS = normalize(normalTS);

                half4 foamA = SAMPLE_TEXTURE2D(_FoamMap, sampler_FoamMap, input.worldUV.xy * _FoamTiling + flowDir * speed * 2 + wakeUVOffset);
                half4 foamB = SAMPLE_TEXTURE2D(_FoamMap, sampler_FoamMap, input.worldUV.zw * _FoamTiling + flowDir * speed * 2 - wakeUVOffset);
                half foam = lerp(foamA.r, foamB.r, 0.5h);

                float shoreNoise = SAMPLE_TEXTURE2D(_FoamMap, sampler_FoamMap, input.uv * _ShoreFoamTiling + _Time.y * _ShoreFoamSpeed * float2(0.15, 0.08)).r;
                float shoreFoamBase = pow(saturate(input.edgeMask * (0.35 + shoreNoise) * _ShoreEdgeAssist), _ShoreFoamContrast) * _ShoreFoamIntensity;

                float contactFoam = smoothstep(0.0, max(_ContactFoamSoftness, 0.001), wakeMask) * _WakeFoamStrength;
                contactFoam *= lerp(0.25, 0.75, abs(wakeRipple));

                float2 screenUV = input.screenPos.xy / input.screenPos.w;
                float sceneDepth = LinearEyeDepth(SampleSceneDepth(screenUV), _ZBufferParams);
                float surfaceDepth = -TransformWorldToView(input.positionWS).z;
                float waterDepth = max(0, sceneDepth - surfaceDepth);

                float depthFactor = saturate(exp2(-waterDepth * _DepthGradient));
                float alphaFactor = 1 - saturate(exp2(-waterDepth * _WaterClean));
                float foamFactor = saturate(exp2(-waterDepth * _FoamDepth));
                float shallowFoamMask = foamFactor;
                float shoreFoam = shoreFoamBase * shallowFoamMask;
                float naturalFoam = foam * _FoamIntensity * shallowFoamMask * saturate(input.edgeMask * 1.75);
                contactFoam *= lerp(0.18, 1.0, shallowFoamMask);

                half3 baseTex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv).rgb * _BaseColor.rgb;
                half3 depthCol = lerp(_DeepColor.rgb, _ShallowColor.rgb, depthFactor);

                half3 foamColor = lerp(depthCol, half3(1.0, 1.0, 1.0), _ContactFoamWhiteness);
                half3 albedoCol = depthCol * baseTex;
                albedoCol += foamColor * (naturalFoam + shoreFoam * _EdgeFoamBoost + contactFoam);

                half causticFactor = (1.0h - (half)alphaFactor) * (half)depthFactor;
                float3 channel_offset = _Channel_Offset.xyz * 0.01;
                float causticSpeed = speed * _CausticSpeed;

                float r1 = SAMPLE_TEXTURE2D(_CausticMap, sampler_CausticMap, input.worldUV.xy * _CausticTiling + causticSpeed * flowDir + channel_offset.x).r;
                float g1 = SAMPLE_TEXTURE2D(_CausticMap, sampler_CausticMap, input.worldUV.xy * _CausticTiling + causticSpeed * flowDir + channel_offset.y).g;
                float b1 = SAMPLE_TEXTURE2D(_CausticMap, sampler_CausticMap, input.worldUV.xy * _CausticTiling + causticSpeed * flowDir + channel_offset.z).b;
                half3 caustics1 = half3(r1, g1, b1) * _CausticIntensity;

                float r2 = SAMPLE_TEXTURE2D(_CausticMap, sampler_CausticMap, 0.8 * causticSpeed * flowDir - input.worldUV.xy * _CausticTiling + channel_offset.x).r;
                float g2 = SAMPLE_TEXTURE2D(_CausticMap, sampler_CausticMap, 0.8 * causticSpeed * flowDir - input.worldUV.xy * _CausticTiling + channel_offset.y).g;
                float b2 = SAMPLE_TEXTURE2D(_CausticMap, sampler_CausticMap, 0.8 * causticSpeed * flowDir - input.worldUV.xy * _CausticTiling + channel_offset.z).b;
                half3 caustics2 = half3(r2, g2, b2) * _CausticIntensity;

                half3 caustic = min(caustics1, caustics2) * causticFactor;
                albedoCol.rgb += caustic;

                half3 normalWS = TransformTangentToWorld(
                    normalTS,
                    half3x3(input.tangentWS.xyz,
                            cross(input.normalWS.xyz, input.tangentWS.xyz) * input.tangentWS.w,
                            input.normalWS.xyz)
                );
                normalWS = NormalizeNormalPerPixel(normalWS);
                normalWS *= (vface > 0.0) ? 1.0 : -1.0;

                half2 distortedUV = screenUV + normalWS.xz * (_RefractionStrength + wakeMask * 0.055);
                half sceneDistortDepth = LinearEyeDepth(SampleSceneDepth(distortedUV), _ZBufferParams);
                half tmp = step(saturate(sceneDistortDepth - surfaceDepth), 0);
                distortedUV = tmp * screenUV + (1 - tmp) * distortedUV;
                float3 underWaterColor = SampleSceneColor(distortedUV);

                float3 viewDir = SafeNormalize(input.viewDirWS);
                half fresnel = pow(1.0h - saturate(dot(viewDir, normalWS)), _FresnelPower);

                half2 reflectionDistortion = normalWS.xz * (_ReflecionDistortion + wakeMask * 0.055);
                half4 reflectionColor = SAMPLE_TEXTURE2D(_PlanarReflection, sampler_PlanarReflection, screenUV + reflectionDistortion) * (_ReflectionIntensity + fresnel * _FresnelIntensity);

                InputData lightingInput = (InputData)0;
                lightingInput.positionWS = input.positionWS;
                lightingInput.normalWS = normalWS;
                lightingInput.viewDirectionWS = viewDir;
                lightingInput.shadowCoord = input.shadowCoord;
                lightingInput.fogCoord = 0;
                lightingInput.vertexLighting = 0;

                SurfaceData surfaceData = (SurfaceData)0;
                surfaceData.albedo = albedoCol;
                surfaceData.alpha = 1;
                surfaceData.metallic = 0;
                surfaceData.smoothness = saturate(1.0h - _Roughness);
                surfaceData.occlusion = _Occlusion;
                surfaceData.normalTS = normalTS;
                surfaceData.reflectionColor = reflectionColor;
                surfaceData.scaterringColor = _ScatteringColor;

                half4 lit = StandardLighting(lightingInput, surfaceData);

                half3 waterLit = lit.rgb * _WaterBrightness;
                waterLit += reflectionColor.rgb * (0.25 + fresnel * 0.65);
                waterLit += fresnel * _SpecularBoost * 0.18;
                waterLit = max(waterLit, _MinWaterColor.rgb);

                float manualOpacity = saturate(_SurfaceOpacity + alphaFactor * 0.18 + fresnel * 0.10 + input.edgeMask * 0.05 + wakeMask * 0.04);
                float sceneBlend = saturate((1.0 - manualOpacity) * _SceneColorBlend + (1.0 - alphaFactor) * _SceneColorBlend * 0.28);
                half3 finalColor = lerp(waterLit, underWaterColor, sceneBlend);
                finalColor += (shoreFoam + contactFoam) * 0.018;
                lit.rgb = finalColor;
                lit.a = 1;
                return lit;
            }
            ENDHLSL
        }
    }
}
