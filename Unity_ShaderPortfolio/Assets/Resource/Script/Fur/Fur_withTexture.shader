Shader "Custom/Character/Fur_My"
{
    Properties
    {
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        [MainColor] _BaseColor("Base Color", Color) = (1,1,1,1)

        _FurControlMap1("FurControlMap1",2D) = "white"{}
        _FurControlMap2("FurControlMap2",2D) = "white"{}

        //   FurMask
        _FurMask("FurMask", 2D) = "white" {}

        _FurThinness1("FurThinness1",Range(0,100)) = 1
        _FurThinness2("FurThinness2",Range(0,100)) = 1
        _FurLength("FurLength",Range(0,2)) = 0.5

        _CurFactor("CurlFactor",Range(0,10)) = 0.5
        _CurRadius("CurlRadius",Range(0,10)) = 1

        //   AO / CutOff / 力 / 光滑度 / 速度
        _AOFallOff("AOFallOff",Range(0,2)) = 1
        _CutOffStart("CutOffStart", Range(0, 10)) = 1
        _FurGForce("FurGForce",Vector) = (0,0,0,1)
        _Smoothness("Smoothness",Range(0,1)) = 0.3
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
            ZWrite On
            Cull Off

            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma enable_d3d11_debug_symbols
            #pragma target 4.5
            #pragma require instancing          
            #pragma multi_compile_instancing

            #include "Assets/Resource/Shader/ShaderLibrary/ShadingModels.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS  : POSITION;
                float3 normalOS    : NORMAL;
                float4 tangentOS   : TANGENT;
                float2 texcoord    : TEXCOORD0;
                uint   instanceID  : SV_InstanceID;
            };

            struct Varings
            {
                float4 positionCS  : SV_POSITION;

                //   baseUV（带Tiling/Offset）+ 原始UV（给control/mask用）
                float2 uv          : TEXCOORD0;
                float2 uv0         : TEXCOORD6;   

                float3 positionWS  : TEXCOORD1;
                float3 normalWS    : TEXCOORD2;
                float4 tangentWS   : TEXCOORD3;
                float3 viewDirWS   : TEXCOORD4;
                float4 shadowCoord : TEXCOORD5;

                float  furStep     : TEXCOORD7;     //   传furStep

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            //防止毛发太均匀，添加一个扰动
            //添加一个矩阵旋转（也可以用其他的）
            float4x4 rotationMatrix(float3 axis,float angle)
            {
                axis = normalize(axis);
                float s = sin(angle);//旋转的角度
                float c = cos(angle);
                float oc = 1.0f - c;
                return float4x4(oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s, oc * axis.z * axis.x + axis.y * s, 0.0,
                oc * axis.x * axis.y + axis.z * s, oc * axis.y * axis.y + c, oc * axis.y * axis.z - axis.x * s, 0.0,
                oc * axis.z * axis.x - axis.y * s, oc * axis.y * axis.z + axis.x * s, oc * axis.z * axis.z + c, 0.0,
                0.0, 0.0, 0.0, 1.0);//复制的旋转矩阵
            }
            //之后扰动用的随机数算法（网上找一个就行）
            float RND( float seed )
            {
                seed = round(seed * 255) / 255;//fix
                return frac(sin(dot(float2(seed,seed*seed), float2(12.9898, 78.233))) * 43758.5453);
            }
            //旋转之后进行一个扰动-沿着法线方向
            float3 FurCurl(float3 n,float3 t,float f,float id,float CurNumber,float CurRadius)
            {
                float r = RND(id);//获得一个随机数
                return mul(rotationMatrix(n,2 * 3.1415926 * f * CurNumber * r),float4(t,0) * CurRadius * 0.1 * (r-f));
                //沿着法线方向做一个扰动
            }

            //  BaseMap / FurMask
            TEXTURE2D(_BaseMap);          SAMPLER(sampler_BaseMap);
            TEXTURE2D(_FurMask);          SAMPLER(sampler_FurMask);

            TEXTURE2D(_FurControlMap1);   SAMPLER(sampler_FurControlMap1);
            TEXTURE2D(_FurControlMap2);   SAMPLER(sampler_FurControlMap2);

            //  物理贴图（一般是全局纹理由RenderFeature/脚本塞进来）
            TEXTURE2D(_XFurPhysics);      SAMPLER(sampler_XFurPhysics);

            CBUFFER_START(UnityPerMaterial)
                //   为了让面板 Tiling/Offset 真正生效，需要用 *_ST
                float4 _BaseMap_ST;
                float4 _FurControlMap1_ST;
                float4 _FurControlMap2_ST;
                float4 _FurMask_ST;

                half _FurLength;
                half4 _BaseColor;        

                half _FurThinness1;
                half _FurThinness2;

                half _CurFactor;
                half _CurRadius;

              
                half _AOFallOff;
                half _CutOffStart;
                half4 _FurGForce;
                half _Smoothness;
                half _Velocity;
            CBUFFER_END

            UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(half,_FurStep)
            UNITY_INSTANCING_BUFFER_END(Props)

            //怎么去生成壳
            Varings vert(Attributes input)
            {
                Varings output;
                UNITY_SETUP_INSTANCE_ID(input);
                //获取下标
                UNITY_TRANSFER_INSTANCE_ID(input,output);

                float furStep = UNITY_ACCESS_INSTANCED_PROP(Props,_FurStep);
                // 默认知道ID是多少

                output.furStep = furStep;

                //  原始UV保留一份（control/mask用它）
                output.uv0 = input.texcoord;

                //   FurMask（让“没毛的地方”不外扩）
                float2 uvMask = TRANSFORM_TEX(input.texcoord, _FurMask);
                half mask = saturate(SAMPLE_TEXTURE2D_LOD(_FurMask, sampler_FurMask, uvMask, 0).r);

                //沿法线往外扩,furStep:偏移半径；
                //   * mask
                half3 positonOffset = furStep * _FurLength * mask * input.normalOS.xyz;
                input.positionOS.xyz += positonOffset;//加上偏移值

                //旋转
                //   controlmap也支持Tiling/Offset + thinness
                float2 uvN1 = TRANSFORM_TEX(input.texcoord, _FurControlMap1) * _FurThinness1;
                half noise = SAMPLE_TEXTURE2D_LOD(_FurControlMap1, sampler_FurControlMap1, uvN1, 0).r;
                //这个noise是采样的什么？
                half3 curVector = FurCurl(input.normalOS, input.tangentOS.xyz, _CurFactor, noise, furStep, _CurRadius);
                //furStep,_CurRadius加半径在外层让效果扭曲的大一点

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                //  屏幕空间采样物理贴图（没接的话默认黑=0，不会动）
                float2 screenUV = vertexInput.positionCS.xy / vertexInput.positionCS.w * 0.5 + 0.5;
                half3 motionVectorColor = SAMPLE_TEXTURE2D_LOD(_XFurPhysics, sampler_XFurPhysics, screenUV, 0).rgb * _Velocity;

                half3 gforce = _FurGForce.xyz * _FurGForce.w;

                //  模拟重力和风力：物理 + 卷曲
                input.positionOS.xyz += (clamp(motionVectorColor, -1, 1) + gforce + curVector) * furStep * _FurLength * mask;

                vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

                //初始化数字属性
                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);  //   base map tiling/offset
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

                //   片元优先用传下来的furStep（避免某些平台实例化读取怪）
                float furStep = input.furStep;

                float2 uvBase = input.uv;   // BaseMap 用变换后的UV
                float2 uv0    = input.uv0;  // Control/Mask 用原始UV再各自 TRANSFORM_TEX

                //   Albedo贴图作为颜色
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uvBase);
                half3 albedo  = baseMap.rgb * _BaseColor.rgb;

                //   controlmap 支持Tiling/Offset + thinness
                float2 uvC1 = TRANSFORM_TEX(uv0, _FurControlMap1) * _FurThinness1;
                float2 uvC2 = TRANSFORM_TEX(uv0, _FurControlMap2) * _FurThinness2;

                //  明确取.r（避免half4->half隐式导致问题）
                half noise1 = SAMPLE_TEXTURE2D(_FurControlMap1, sampler_FurControlMap1, uvC1).r;
                half noise2 = SAMPLE_TEXTURE2D(_FurControlMap2, sampler_FurControlMap2, uvC2).r;
                half noise  = max(noise1, noise2);

                //   FurMask（让没毛区域彻底不显示壳）
                float2 uvMask = TRANSFORM_TEX(uv0, _FurMask);
                half mask = saturate(SAMPLE_TEXTURE2D(_FurMask, sampler_FurMask, uvMask).r);

                half alpha = saturate(noise * _CutOffStart - (furStep * furStep));
                alpha = max(0.0h, alpha);

                //   mask也影响透明（否则mask黑的地方仍可能有一层壳在渲染）
                alpha *= mask;

                //   AO：根部更暗，越外越亮
                half absorb = lerp(0.5h, 1.0h, furStep * 1.7h);
                absorb = saturate(absorb * _AOFallOff);
                albedo *= absorb;

                half3 normalWS = NormalizeNormalPerPixel(input.normalWS);

                //光照PBR理论
                InputData lightingInput = (InputData)0;
                lightingInput.positionWS = input.positionWS;
                lightingInput.normalWS = normalWS;//先不用环境图
                lightingInput.viewDirectionWS = SafeNormalize(input.viewDirWS);
                lightingInput.shadowCoord = input.shadowCoord;
                lightingInput.fogCoord = 0;
                lightingInput.vertexLighting = half3(0, 0, 0);

                SurfaceData surfaceInput = (SurfaceData)0;
                surfaceInput.albedo = albedo;
                surfaceInput.metallic = 0;
                surfaceInput.smoothness = _Smoothness; //  
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
