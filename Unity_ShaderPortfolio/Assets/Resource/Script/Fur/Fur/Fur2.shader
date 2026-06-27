Shader "Custom/Character/Fur2"
{
    Properties
    {
        _FurControlMap1("FurControlMap1",2D) = "white"{}
        _FurControlMap2("FurControlMap2",2D) = "white"{}
        _FurThinness1("FurThinness1",Range(0,100)) = 1
        _FurThinness2("FurThinness2",Range(0,100)) = 1
        _FurLength("FurLength",Range(0,2)) = 0.5
        _Color("Color",Color) = (1,0,0,1)
        _CurFactor("CurFactor",Range(0,10)) = 0.5
        _CurRadius("CurRadius",Range(0,10)) = 1
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
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            Blend SrcAlpha OneMinusSrcAlpha
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma enable_d3d11_debug_symbols
            #pragma target 4.5
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
                uint instanceID : SV_InstanceID;
            };

            struct Varings
            {
                float4 positionCS  : SV_POSITION;
                float2 uv          : TEXCOORD0;
                float3 positionWS  : TEXCOORD1;
                float3 normalWS    : TEXCOORD2;
                float4 tangentWS   : TEXCOORD3;
                float3 viewDirWS   : TEXCOORD4;
                float4 shadowCoord : TEXCOORD5;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };


            float RND( float seed )
            {
                seed = round(seed * 255) / 255;//fix
                return frac(sin(dot(float2(seed,seed*seed), float2(12.9898, 78.233))) * 43758.5453);
            }

            float4x4 rotationMatrix(float3 axis,float angle)
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

            float3 FurCurl(float3 n,float3 t,float f,float id,float CurNumber,float CurRadius)
            {
                float r = RND(id);
                return mul(rotationMatrix(n,2 * 3.1415926 * f * CurNumber * r),float4(t,0) * CurRadius * 0.1 * (r-f));
            }

            TEXTURE2D(_FurControlMap1);     SAMPLER(sampler_FurControlMap1);
            TEXTURE2D(_FurControlMap2);     SAMPLER(sampler_FurControlMap2);
            CBUFFER_START(UnityPerMaterial)
                half _FurLength;
                half4 _Color;
                half _FurThinness1;
                half _FurThinness2;
                half _CurFactor;
                half _CurRadius;
            CBUFFER_END
            
            UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(half,_FurStep)
            UNITY_INSTANCING_BUFFER_END(Props)

            Varings vert(Attributes input)
            {
                Varings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input,output);

                float furStep = UNITY_ACCESS_INSTANCED_PROP(Props,_FurStep);
                half3 positonOffset = furStep * _FurLength * input.normalOS.xyz;
                
                
                input.positionOS.xyz += positonOffset;
                half noise = SAMPLE_TEXTURE2D_LOD(_FurControlMap1,sampler_FurControlMap1,input.texcoord * _FurThinness1,0).r;
                half3 curVector = FurCurl(input.normalOS,input.tangentOS,_CurFactor,noise,furStep,_CurRadius);

                input.positionOS.xyz += curVector * _FurLength * furStep;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                output.uv = input.texcoord;
                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                output.normalWS = normalInput.normalWS;
                output.tangentWS = float4(normalInput.tangentWS.xyz, input.tangentOS.w * GetOddNegativeScale());
                output.viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
                output.shadowCoord = GetShadowCoord(vertexInput);

                return output;
            }

            half4 frag(Varings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);

                float furStep = UNITY_ACCESS_INSTANCED_PROP(Props,_FurStep);
                half noise1 = SAMPLE_TEXTURE2D(_FurControlMap1,sampler_FurControlMap1,input.uv * _FurThinness1);
                half noise2 = SAMPLE_TEXTURE2D(_FurControlMap2,sampler_FurControlMap2,input.uv * _FurThinness2);
                half noise = max(noise1,noise2);
                
                half alpha = noise - (furStep * furStep);
                alpha = saturate(alpha);

                InputData lightingInput = (InputData)0;
                lightingInput.positionWS = input.positionWS;
                lightingInput.normalWS = input.normalWS;
                lightingInput.viewDirectionWS = SafeNormalize(input.viewDirWS);
                lightingInput.shadowCoord = input.shadowCoord;
                lightingInput.fogCoord = 0;
                lightingInput.vertexLighting = half3(0, 0, 0);
                
                SurfaceData surfaceInput = (SurfaceData)0;
                surfaceInput.albedo = _Color.rgb;
                surfaceInput.metallic = 0;
                surfaceInput.smoothness = 0.3;
                surfaceInput.occlusion = 1;
                surfaceInput.alpha = alpha;
                surfaceInput.normalTS = half3(1,0,0);
                half4 color = StandardLighting(lightingInput, surfaceInput);
                
                return color;
            }
            
            ENDHLSL
        }
    }
    
    
}