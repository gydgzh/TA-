Shader "Custom/Character/Fur"
{
    Properties
    {
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        [MainColor] _BaseColor("Base Color", Color) = (1,1,1,1)
        
        _FurControlMap1("FurControlMap1", 2D) = "white" {}
        _FurControlMap2("FurControlMap2", 2D) = "white" {}
        _FurMask("FurMask", 2D) = "white" {}
        
        _FurLength("FurLength", Range(0, 0.5)) = 0.0
        _FurThinness1("FurThinness1", Range(0, 100)) = 0.0
        _FurThinness2("FurThinness2", Range(0, 100)) = 0.0
        _AOFallOff("AOFallOff",Range(0,2)) = 1
        _CutOffStart("CutOffStart", Range(0, 10)) = 0.0
        _CurlRadius("CurlRadius", Range(0, 3)) = 0.0
        _CurlFactor("CurlFactor", Range(0, 3)) = 0.0
        _FurGForce("FurGForce",Vector) = (0,0,0,1)
        _Smoothness("Smoothness",Range(0,1)) = 0.1
        _Velocity("Velocity",Range(-100,100)) = 1
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
            Zwrite On
            Cull off
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            Blend SrcAlpha OneMinusSrcAlpha
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma enable_d3d11_debug_symbols
            #pragma target 4.5  // 提高编译目标级别
            #pragma require instancing  // 明确要求实例化支持
            
            // 添加这些pragma指令以支持ComputeBuffer
            // #define USE_STRUCTURED_BUFFER
            #pragma multi_compile_instancing

            #include "Assets/Resource/Shader/ShaderLibrary/ShadingModels.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS    : NORMAL;
                float4 tangentOS   : TANGENT;
                float2 texcoord     : TEXCOORD0;
                uint instanceID : SV_InstanceID;  // 添加实例ID
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
                float furStep : TEXCOORD6;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            // 材质属性
            TEXTURE2D(_BaseMap);     SAMPLER(sampler_BaseMap);
            TEXTURE2D(_FurControlMap1);     SAMPLER(sampler_FurControlMap1);
            TEXTURE2D(_FurControlMap2);     SAMPLER(sampler_FurControlMap2);
            TEXTURE2D(_FurMask);     SAMPLER(sampler_FurMask);
            TEXTURE2D(_XFurPhysics);    SAMPLER(sampler_XFurPhysics);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half4 _BaseColor;
                half _Metallic;
                half _Smoothness;
                half _BumpScale;
                half _OcclusionStrength;
                half4 _EmissionColor;
                half _FurLength;
                half _FurThinness1;
                half _FurThinness2;
                half4 _FurGForce;
                half _AOFallOff;
                half _CutOffStart;
                half _CutOffEnd;
                half _CurlRadius;
                half _CurlFactor;
                half _Velocity;
            CBUFFER_END

            // 使用ComputeBuffer而不是标准的实例化缓冲区
            #ifdef USE_STRUCTURED_BUFFER
                StructuredBuffer<float> _FurStepBuffer;
            #else
                UNITY_INSTANCING_BUFFER_START(Props)  
                    UNITY_DEFINE_INSTANCED_PROP(half, _FurStep)  
                UNITY_INSTANCING_BUFFER_END(Props)  
            #endif

            float RND( float seed )
            {
                seed = round(seed * 255) / 255;//fix
                return frac(sin(dot(float2(seed,seed*seed), float2(12.9898, 78.233))) * 43758.5453);
            }
        
            float4x4 rotationMatrix( float3 axis , float angle )
            {
                axis = normalize(axis);
                float s = sin(angle);
                float c = cos(angle);
                float oc = 1.0f - c;
                return float4x4(oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s, oc * axis.z * axis.x + axis.y * s, 0.0,
                                oc * axis.x * axis.y + axis.z * s, oc * axis.y * axis.y + c, oc * axis.y * axis.z - axis.x * s, 0.0,
                                oc * axis.z * axis.x - axis.y * s, oc * axis.y * axis.z + axis.x * s, oc * axis.z * axis.z + c, 0.0,
                                0.0, 0.0, 0.0, 1.0);
            }
            float3 FurCurl( float3 n,float3 t ,float f,float id,float CurlNumber,float CurlRadius )
            {
                float r = RND(id);
                return mul(rotationMatrix(n, 2.0 * 3.1415926 * f * CurlNumber * r), float4(t,0)*CurlRadius * 0.1*(r-f));
            }
            

            Varyings vert(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                // 获取毛发步长
                #ifdef USE_STRUCTURED_BUFFER
                    float furStep = _FurStepBuffer[input.instanceID];
                #else
                    float furStep = UNITY_ACCESS_INSTANCED_PROP(Props, _FurStep);
                #endif
                
                output.furStep = furStep;

                float2 uv = input.texcoord;
                //
                half noise = SAMPLE_TEXTURE2D_LOD(_FurControlMap1, sampler_FurControlMap1, uv * _FurThinness1, 0).r;
                half mask = saturate(SAMPLE_TEXTURE2D_LOD(_FurMask, sampler_FurMask, uv , 0).r);
                input.positionOS.xyz += input.normalOS * _FurLength * furStep * mask;

                half3 curlVector = FurCurl(input.normalOS, input.tangentOS.xyz, _CurlFactor, noise,
                       furStep, _CurlRadius);
                    

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                    
                float2 screenUV = vertexInput.positionCS.xy / vertexInput.positionCS.w * 0.5 + 0.5;
                half3 motionVectorColor = SAMPLE_TEXTURE2D_LOD(_XFurPhysics,sampler_XFurPhysics,screenUV,0).rgb * _Velocity;

                                    // 模拟重力和风力
                input.positionOS.xyz += (clamp(motionVectorColor,-1,1) + curlVector) * furStep * _FurLength * mask;
                 vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                    
                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                output.normalWS = normalInput.normalWS;
                output.tangentWS = float4(normalInput.tangentWS.xyz, input.tangentOS.w * GetOddNegativeScale());
                output.viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
                output.shadowCoord = GetShadowCoord(vertexInput);
                
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);

                float2 uv = input.uv;
                
                // 获取毛发步长
                #ifdef USE_STRUCTURED_BUFFER
                    float furStep = input.furStep;
                #else
                    float furStep = UNITY_ACCESS_INSTANCED_PROP(Props, _FurStep);
                #endif
                
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
                half3 albedo = baseMap.rgb * _BaseColor.rgb;

                half noise1 = SAMPLE_TEXTURE2D(_FurControlMap1, sampler_FurControlMap1,uv * _FurThinness1).r;
                half noise2 = SAMPLE_TEXTURE2D(_FurControlMap2, sampler_FurControlMap2,uv * _FurThinness2).r;
                
                half noise = max(noise1,noise2);

                half mask = saturate(SAMPLE_TEXTURE2D(_FurMask, sampler_FurMask, uv).r - 0);
                
                
                // half alpha = step(lerp(_CutOffStart, _CutOffEnd, furStep), noise);
                half alpha = saturate(noise * _CutOffStart - (furStep * furStep));
                alpha = max(0.0, alpha);
                // alpha *= alpha;
                
                half absorb = lerp(0.5, 1, furStep * 1.7);
                absorb = saturate(absorb * _AOFallOff);
                albedo *= absorb;
                
                half3 normalWS = NormalizeNormalPerPixel(input.normalWS);

                InputData lightingInput = (InputData)0;
                lightingInput.positionWS = input.positionWS;
                lightingInput.normalWS = normalWS;
                lightingInput.viewDirectionWS = SafeNormalize(input.viewDirWS);
                lightingInput.shadowCoord = input.shadowCoord;
                lightingInput.fogCoord = 0;
                lightingInput.vertexLighting = half3(0, 0, 0);
                
                SurfaceData surfaceInput = (SurfaceData)0;
                surfaceInput.albedo = albedo;
                surfaceInput.metallic = 0;
                surfaceInput.smoothness = _Smoothness;
                surfaceInput.occlusion = 1;
                surfaceInput.alpha = alpha;
                surfaceInput.normalTS = half3(1,0,0);
                
                half4 color = StandardLighting(lightingInput, surfaceInput);
                return color;
            }
            ENDHLSL
        }
        
        // 其他Pass保持不变...
    }
    FallBack "Universal Render Pipeline/Lit"
}