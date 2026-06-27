Shader "Custom/Environment/Lava"
{
    Properties
    {
        _AlbedoMap("AlbedoMap",2D) = "white"{}
        _BumpMap("NormalMap",2D) = "bump"{}
        _FlowMap("FlowMap",2D) = "white"{}
        
        [HDR]_HotLavaColor("HotLavaColor",Color) = (1,1,1,1)
        [HDR]_ColdLavaColor("ColdLavaColor",Color) = (1,1,1,1)
        
        _HotLavaThrehold("HotLavaThrehold",Range(0,1)) = 0.5
        _HotLavaPower("_HotLavaPower",Range(0,10)) = 1
        
                
        _HeightMap("HeightMap",2D) = "black"{}
        _MatcapMap("MatcapMap",2D) = "black"{}
        _Height("Height",Range(-1,1)) = 0.5
        
        _Smoothness("Smothness",Range(0,1)) = 0.2
        
        [Header(Flow)]
        _FlowX("FlowX",Range(-1,1)) = 0.2
        _FlowY("FlowY",Range(-1,1)) = 0.3
        _FlowSpeed("FlowSpeed",Range(-10,10)) = 1
        _Tiling1("Tiling1",Range(0,300)) = 1
        _Tiling2("Tiling2",Range(0,300)) = 1
        _PeriodSec("PeriodSec",Range(0,2)) = 0.5
        

    }
    SubShader
    {
        Tags 
        { 
            "RenderType"="Transparent"
            "Renderpipeline" = "UniversalPipeline"
            "Queue" = "Geometry"
        }
        Blend One Zero
        Cull Off
        LOD 100

        Pass
        {
            Name "ForwardLit"
            Tags {"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

                        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _ALPHATEST_ON
            #pragma enable_d3d11_debug_symbols
            
            #include "Assets/Resource/Shader/ShaderLibrary/LightingModel.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4  tangentOS : TANGENT;
                float2 texcoord : TEXCOORD0;
                float4 color : Color;
            };

            struct Varings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float4 tangentWS : TEXCOORD3;
                float3 viewDirWS : TEXCOORD4;
                float4 shadowCoord : TEXCOORD5;

                float4 worldUV : TEXCOORD6;
                float4 screenPos : TEXCOORD7;
                float height : TEXCOORD8;
            };
            
            TEXTURE2D(_BumpMap);             SAMPLER(sampler_BumpMap);
            TEXTURE2D(_AlbedoMap);           SAMPLER(sampler_AlbedoMap);
            TEXTURE2D(_FlowMap);             SAMPLER(sampler_FlowMap);
            TEXTURE2D(_HeightMap);   SAMPLER(sampler_HeightMap);
            
            CBUFFER_START(UnityPerMaterial)
                float _FlowX;
                float _FlowY;
                float _FlowSpeed;
                float _Tiling1;
                float _Tiling2;
                float _HotLavaThrehold;
                float _HotLavaPower;
                float4 _HotLavaColor;
                float4 _ColdLavaColor;
                float _PeriodSec;
                float _Smoothness;
                half _Height;
            CBUFFER_END



            Varings vert(Attributes input)
            {
                Varings output;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS,input.tangentOS);
                
                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                output.normalWS = normalInput.normalWS;
                output.tangentWS = float4(normalInput.tangentWS.xyz,input.tangentOS.w * GetOddNegativeScale());
                output.uv = input.texcoord;
                output.viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
                output.shadowCoord = GetShadowCoord(vertexInput);
                
                output.screenPos = ComputeScreenPos(output.positionCS);
                output.worldUV.xy = vertexInput.positionWS.yz * 0.001 *  _Tiling1;
                output.worldUV.zw = vertexInput.positionWS.yz * 0.001 *  _Tiling2;
                
                
                return output;
                
            }

            half2 BumpOffset(float2 uv,half3 viewDir,half height)
            {

                half2 offset = (viewDir.xy/viewDir.z) * height;
                uv = uv + offset;
                return uv;
            }

            half4 frag(Varings input,float vface : VFACE) : SV_Target
            {
                float2 flowDir = float2(_FlowX,_FlowY);

                flowDir = (SAMPLE_TEXTURE2D(_FlowMap,sampler_FlowMap,input.uv).rg * 2 - 1) *  float2(_FlowX,_FlowY);

                half halfPeriodSec = 0.5 * _PeriodSec;
                float t = _Time.x;
                half phase0 = frac(t * _FlowSpeed) * _PeriodSec;
                half phase1 = frac( t * _FlowSpeed + 0.5f) * _PeriodSec;
                half flowlerp = saturate(abs((halfPeriodSec - phase0) / halfPeriodSec));

                // input.worldUV.xy  = input.uv;
                
                
                half4 normalMap1 = SAMPLE_TEXTURE2D(_BumpMap,sampler_BumpMap,input.worldUV.xy + phase0 * flowDir);
                half4 normalMap2 = SAMPLE_TEXTURE2D(_BumpMap,sampler_BumpMap,input.worldUV.xy + phase1 * flowDir);
                half4 bump1 = lerp(normalMap1,normalMap2,flowlerp);
                bump1.xyz = UnpackNormalScale(bump1,1);

                half3 normalTS = bump1;
                
                half3 normalWS = TransformTangentToWorld(normalTS,half3x3(input.tangentWS.xyz, cross(input.normalWS.xyz,input.tangentWS.xyz) * input.tangentWS.w ,input.normalWS.xyz));
                normalWS = NormalizeNormalPerPixel(normalWS);
                
                //岩浆的颜色
                half4 baseColor1 = SAMPLE_TEXTURE2D(_AlbedoMap,sampler_AlbedoMap,input.worldUV.xy + phase0 * flowDir);
                half4 baseColor2 = SAMPLE_TEXTURE2D(_AlbedoMap,sampler_AlbedoMap,input.worldUV.xy + phase1 * flowDir);
                half4 baseColor = lerp(baseColor1,baseColor2,flowlerp);

                // 自发光-存在贴图的A通道里
                half hotLavaMask = pow(saturate(baseColor.a - _HotLavaThrehold), 10.0/(_HotLavaPower));
                

                normalWS *= vface > 0 ? 1: -1;

                InputData lightingInput = (InputData) 0;
                
                lightingInput.positionWS = input.positionWS;
                lightingInput.normalWS = normalWS;
                lightingInput.viewDirectionWS = SafeNormalize(input.viewDirWS);
                lightingInput.shadowCoord = input.shadowCoord;
                lightingInput.fogCoord = 0;
                lightingInput.vertexLighting = 0;

                SurfaceData surfaceData = (SurfaceData) 0;
                
                surfaceData.albedo = baseColor * _ColdLavaColor;
                surfaceData.alpha = 1;
                surfaceData.metallic = 0;
                surfaceData.smoothness = lerp(_Smoothness,0,hotLavaMask);
                surfaceData.occlusion = 1;
                surfaceData.normalTS = normalTS;
                surfaceData.emission = hotLavaMask * _HotLavaColor;

                half4 color = StandardLighting(lightingInput,surfaceData);
  
                return color;
                                
            }
            
            ENDHLSL

        }
        
    }
}
