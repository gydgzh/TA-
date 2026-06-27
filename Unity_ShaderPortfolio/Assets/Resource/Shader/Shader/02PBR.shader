Shader "Custom/Environment/Lit2"
{
    Properties
    {
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        _ORMMap("OcclusionRoughnessMetalic", 2D) = "white" {}
        _Color("Color", Color) = (1,1,1,0)
        _Roughness("Roughness",Range(0,1)) = 0.5
        _Metallic("Metallic",Range(0,1)) = 0
        _BumpMap("BumMap",2D) = "bump"{} 
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
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // #pragma enable_d3d11_debug_symbols
            

            #include "Assets/Resource/Shader/ShaderLibrary/ShadingModels.hlsl"
            #include "Assets/Resource/Shader/ShaderLibrary/CommonBRDF2.hlsl"

            

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
                float3 normalWS : TEXCOORD2;
                float3 viewDirWS : TEXCOORD3;
                float4 tangentWS : TEXCOORD4;
            };

            TEXTURE2D(_BaseMap);  SAMPLER(sampler_BaseMap);
            TEXTURE2D(_ORMMap);   SAMPLER(sampler_ORMMap);
            TEXTURE2D(_BumpMap);  SAMPLER(sampler_BumpMap);
            CBUFFER_START(UnityPerMaterial)
                half4 _Color;
                half _Roughness;
                half _Metallic;
            CBUFFER_END

            

            Varyings vert(Attributes input)
            {
                Varyings output;
                
                // 顶点变换
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normal_inputs = GetVertexNormalInputs(input.normalOS,input.tangentOS);
                
                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                output.normalWS = normal_inputs.normalWS;
                output.tangentWS = float4(normal_inputs.tangentWS.xyz, input.tangentOS.w * GetOddNegativeScale());
                output.viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
                output.uv = input.texcoord;
                
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                Light light = GetMainLight();

                
                half4 normalTS = SAMPLE_TEXTURE2D(_BumpMap,sampler_BumpMap,input.uv);
                normalTS.rgb = UnpackNormalScale(normalTS,1);

                half3 normalWS = TransformTangentToWorld(normalTS, 
                    half3x3(input.tangentWS.xyz, 
                    cross(input.normalWS, input.tangentWS.xyz) * input.tangentWS.w, 
                    input.normalWS));
                normalWS = NormalizeNormalPerPixel(normalWS);
                
                half3 N = normalWS;
                
                half3 L = normalize(light.direction);
                half3 V = normalize(input.viewDirWS);
                half3 H = normalize(L + V);
 


                half NoL = saturate(dot(N,L));
                half NoV = saturate(dot(N,V));

                half3 albedo = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,input.uv) * _Color;

                half3 ORM = SAMPLE_TEXTURE2D(_ORMMap,sampler_ORMMap,input.uv);
                half AO = ORM.r;
                half roughness = max(0.02,ORM.g * _Roughness);
                half metallic = ORM.b * _Metallic;
                
                
                half3 F0 = lerp(0.04,albedo,metallic);
                half D = D_GGX_TR(N,H,roughness);
                half G = GeometrySmith2(N,V,L,roughness);

                half3 F = FresnelSchlick(max(dot(H,V),0),F0);

                
                half3 diffsue = albedo * (1 - metallic);
                //
                half3 radience = light.color * light.shadowAttenuation * NoL;
                half3 directDiffuse = diffsue / PI;
                
                half denominator = 4 * NoV * NoL;
                half3 directSpecular =  (D * F * G) / max(denominator,0.000001);

                half3 DirectLight = (directDiffuse + directSpecular) * radience;

                half3 indirectDiffuse= SampleSH(N) * diffsue;

                half3 R = reflect(-V,N);
                half3 indirectSpecular = GlossyEnvironmentReflection(R,roughness,1);
                indirectSpecular *= EnvBRDFApprox(F0,roughness,NoV);

                half3 LightingResult = DirectLight + indirectSpecular + indirectDiffuse;
                
                half4 Color = half4(LightingResult,1);
                return Color;
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
    }
    FallBack "Universal Render Pipeline/Lit"
}