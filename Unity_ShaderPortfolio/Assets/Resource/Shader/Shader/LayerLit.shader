Shader "Custom/Environment/LayerLit"
{
    Properties
    {
        [Header(Mask Setting)]
        [Enum(Maskmap,0,VertexColor,1,Array,2)] _BlendMode("BlendMode",Int) = 0
        _MaskTex("Mask Texture", 2D) = "white"{}

        [Header(Layer 1)]
        [HDR]_Color1("Color1", Color) = (1,1,1,1)
        _Albedo1("Albedo1", 2D) = "white"{}                 // (保持不变)
        _NormalTex1("Normal", 2D) = "bump"{}
        _MORHTex1("Metallic AO Roughtness1", 2D) = "white"{}
        _Roughness1("Roughness1", Range(0,1)) = 1
        _Metallic1("Metallic1", Range(0,1)) = 1
        _Tiling1("Tiling1",Range(0,100)) = 1

        [Header(Layer 2)]
        [HDR]_Color2("Color2", Color) = (1,1,1,1)
        _Albedo2("Albedo2", 2D) = "white"{}                 // (保持不变)
        _NormalTex2("Normal2", 2D) = "bump"{}
        _MORHTex2("Metallic2 AO Roughtness1", 2D) = "white"{}
        _Roughness2("Roughness2", Range(0,1)) = 1
        _Metallic2("Metallic2", Range(0,1)) = 1
        _Tiling2("Tiling2",Range(0,100)) = 1

        [Header(Layer 3)]
        [HDR]_Color3("Color3", Color) = (1,1,1,1)
        _Albedo3("Albedo3", 2D) = "white"{}                 // (保持不变)
        _NormalTex3("Normal3", 2D) = "bump"{}
        _MORHTex3("Metallic3 AO Roughtness1", 2D) = "white"{}
        _Roughness3("Roughness3", Range(0,1)) = 1
        _Metallic3("Metallic3", Range(0,1)) = 1
        _Tiling3("Tiling3",Range(0,100)) = 1

        [Header(Layer 4)]
        [HDR]_Color4("Color4", Color) = (1,1,1,1)
        _Albedo4("Albedo4", 2D) = "white"{}                 // (保持不变)
        _NormalTex4("Normal4", 2D) = "bump"{}
        _MORHTex4("Metallic4 AO Roughtness1", 2D) = "white"{}
        _Roughness4("Roughness4", Range(0,1)) = 1
        _Metallic4("Metallic4", Range(0,1)) = 1
        _Tiling4("Tiling4",Range(0,100)) = 1

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
            "RenderPipeline" = "UniversalRenderPipeline"
            "Queue" = "Geometry"
        }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma enable_d3d11_debug_symbols

            // [MOD] 为了保证 GetVertexPositionInputs / InputData / SurfaceData / SAMPLE_TEXTURE2D 等一定存在
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

            #include "Assets/Resource/Shader/ShaderLibrary/ShadingModels.hlsl"
            #include "Assets/Resource/Shader/ShaderLibrary/CommonBRDF2.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float4 tangentOS  : TANGENT;
                float2 uv         : TEXCOORD0;
                float4 color      : COLOR;
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
                float4 color       : TEXCOORD6;
            };

            //材质属性
            TEXTURE2D(_MaskTex);     SAMPLER(sampler_MaskTex);

            TEXTURE2D(_NormalTex1);  SAMPLER(sampler_NormalTex1);
            TEXTURE2D(_NormalTex2);  SAMPLER(sampler_NormalTex2);
            TEXTURE2D(_NormalTex3);  SAMPLER(sampler_NormalTex3);
            TEXTURE2D(_NormalTex4);  SAMPLER(sampler_NormalTex4);

            // [MOD] 这里必须和 Properties 名字一致：_Albedo1/2/3/4
            TEXTURE2D(_Albedo1);     SAMPLER(sampler_Albedo1);
            TEXTURE2D(_Albedo2);     SAMPLER(sampler_Albedo2);
            TEXTURE2D(_Albedo3);     SAMPLER(sampler_Albedo3);
            TEXTURE2D(_Albedo4);     SAMPLER(sampler_Albedo4);

            TEXTURE2D(_MORHTex1);    SAMPLER(sampler_MORHTex1);
            TEXTURE2D(_MORHTex2);    SAMPLER(sampler_MORHTex2);
            TEXTURE2D(_MORHTex3);    SAMPLER(sampler_MORHTex3);
            TEXTURE2D(_MORHTex4);    SAMPLER(sampler_MORHTex4);

            //材质常量缓冲区，unity/URP用它把材质面板里的参数打包成一块数据
            CBUFFER_START(UnityPerMaterial)
                float  _BlendMode;
                float4 _Color1, _Color2, _Color3, _Color4;
                float  _Roughness1, _Roughness2, _Roughness3, _Roughness4;
                float  _Metallic1,  _Metallic2,  _Metallic3,  _Metallic4;
                float  _Tiling1,    _Tiling2,    _Tiling3,    _Tiling4;
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output;

                // 顶点变换
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs   normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                output.normalWS   = normalInput.normalWS;
                output.tangentWS  = float4(normalInput.tangentWS.xyz,
                                           input.tangentOS.w * GetOddNegativeScale());
                output.uv         = input.uv;

                output.viewDirWS   = GetCameraPositionWS() - vertexInput.positionWS;
                output.shadowCoord = GetShadowCoord(vertexInput);
                output.color       = input.color;

                return output;
            }

            //法线混合
            half3 BlendNormalRNM(half3 A, half3 B)
            {
                half3 t = A.xyz + half3(0.0, 0.0, 1.0);
                half3 u = B.xyz * half3(-1.0, -1.0,  1.0);
                float3 Out = t * dot(t, u) - u * t.b;
                return normalize(Out);
            }

            half4 frag(Varyings input) : SV_Target
            {
                half4 weights = (_BlendMode > 0.5)
                                ? input.color
                                : SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, input.uv);

                half2 uv1 = input.uv * _Tiling1;
                half2 uv2 = input.uv * _Tiling2;
                half2 uv3 = input.uv * _Tiling3;
                half2 uv4 = input.uv * _Tiling4;

                // [MOD] 修正 Albedo 纹理名/采样器名：_Albedo1/2/3/4
                half4 color1 = SAMPLE_TEXTURE2D(_Albedo1, sampler_Albedo1, uv1) * _Color1;
                half4 color2 = SAMPLE_TEXTURE2D(_Albedo2, sampler_Albedo2, uv2) * _Color2;
                half4 color3 = SAMPLE_TEXTURE2D(_Albedo3, sampler_Albedo3, uv3) * _Color3;
                half4 color4 = SAMPLE_TEXTURE2D(_Albedo4, sampler_Albedo4, uv4) * _Color4;

                half4 mask1 = SAMPLE_TEXTURE2D(_MORHTex1, sampler_MORHTex1, uv1);
                half4 mask2 = SAMPLE_TEXTURE2D(_MORHTex2, sampler_MORHTex2, uv2);
                half4 mask3 = SAMPLE_TEXTURE2D(_MORHTex3, sampler_MORHTex3, uv3);
                half4 mask4 = SAMPLE_TEXTURE2D(_MORHTex4, sampler_MORHTex4, uv4);

                half3 normal1 = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalTex1, sampler_NormalTex1, uv1),
                                                  1 - weights.r - weights.g - weights.b);
                half3 normal2 = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalTex2, sampler_NormalTex2, uv2),
                                                  weights.r);
                half3 normal3 = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalTex3, sampler_NormalTex3, uv3),
                                                  weights.g);
                half3 normal4 = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalTex4, sampler_NormalTex4, uv4),
                                                  weights.b);

                half4 albedo = lerp(color1, color2, weights.r);
                albedo = lerp(albedo, color3, weights.g);
                albedo = lerp(albedo, color4, weights.b);

                half metallic = lerp(mask1.r * _Metallic1, mask2.r * _Metallic2, weights.r);
                metallic      = lerp(metallic,            mask3.r * _Metallic3, weights.g);
                metallic      = lerp(metallic,            mask4.r * _Metallic4, weights.b);

                half ao = lerp(mask1.g, mask2.g, weights.r);
                ao      = lerp(ao,      mask3.g, weights.g);
                ao      = lerp(ao,      mask4.g, weights.b);

                half roughness = lerp(mask1.b * _Roughness1, mask2.b * _Roughness2, weights.r);
                roughness      = lerp(roughness,             mask3.b * _Roughness3, weights.g);
                roughness      = lerp(roughness,             mask4.b * _Roughness4, weights.b);

                // [MOD] HLSL 不支持命名参数写法 A: B:，并且函数名要一致
                half3 mixedNormalTS = BlendNormalRNM(normal1, normal2);
                mixedNormalTS = BlendNormalRNM(mixedNormalTS, normal3);
                mixedNormalTS = BlendNormalRNM(mixedNormalTS, normal4);

                half3 normalWS = TransformTangentToWorld(
                    mixedNormalTS,
                    half3x3(
                        input.tangentWS.xyz,
                        cross(input.normalWS, input.tangentWS.xyz) * input.tangentWS.w,
                        input.normalWS
                    )
                );
                normalWS = NormalizeNormalPerPixel(normalWS);

                half occlusion  = ao;
                half smoothness = 1 - roughness;

                InputData lightingInput = (InputData)0;
                lightingInput.positionWS      = input.positionWS;
                lightingInput.normalWS        = normalWS;
                lightingInput.viewDirectionWS = SafeNormalize(input.viewDirWS);
                lightingInput.shadowCoord     = input.shadowCoord;
                lightingInput.fogCoord        = 0;
                lightingInput.vertexLighting  = half3(0, 0, 0);

                SurfaceData surfaceInput = (SurfaceData)0;
                surfaceInput.albedo     = albedo.rgb;         // [MOD] SurfaceData.albedo 通常是 half3（更稳）
                surfaceInput.alpha      = 1;
                surfaceInput.metallic   = metallic;
                surfaceInput.smoothness = smoothness;
                surfaceInput.occlusion  = occlusion;
                surfaceInput.normalTS   = mixedNormalTS;

                half4 outColor = StandardLighting(lightingInput, surfaceInput);
                return outColor;
            }
            ENDHLSL
        }

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
