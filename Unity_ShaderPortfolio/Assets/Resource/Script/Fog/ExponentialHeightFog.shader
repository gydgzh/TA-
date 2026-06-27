Shader "Hidden/ExponentialHeightFog"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma enable_d3d11_debug_symbols

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 viewVector : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            // 雾参数
            float4 _FogColor;
            float _FogDensity;
            float _FogHeightFalloff;
            float _FogStartDistance;
            float _FogHeight;
            float _FogMaxDistance;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                // 计算视图向量
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.viewVector = worldPos - _WorldSpaceCameraPos;
                
                return o;
            }

            // 从深度重建世界坐标
            float3 ReconstructWorldPosition(float2 uv, float depth)
            {
                // 获取NDC坐标
                float4 ndc = float4(uv * 2.0 - 1.0, depth, 1.0);
                #if UNITY_UV_STARTS_AT_TOP
                    ndc.y = -ndc.y;
                #endif

                // 转换到世界空间
                float4 worldPos = mul(unity_CameraInvProjection, ndc);
                worldPos = mul(unity_CameraToWorld, worldPos);
                worldPos /= worldPos.w;
                
                return worldPos.xyz;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 sceneColor = tex2D(_MainTex, i.uv);
                
                // 采样深度
                float depth = SampleSceneDepth(i.uv);
                float linearDepth = LinearEyeDepth(depth, _ZBufferParams);
                
                // 重建世界位置
                float3 worldPos = ReconstructWorldPosition(i.uv, depth);
                
                // 计算雾效
                float fogDistance = max(0.0, linearDepth - _FogStartDistance);
                fogDistance = min(fogDistance, _FogMaxDistance);
                
                float heightFactor = max(0.0, (_FogHeight - worldPos.y) * _FogHeightFalloff);
                float fogDensity = _FogDensity * exp(-heightFactor);
                
                float fogFactor = 1.0 - exp(-fogDensity * fogDistance);
                fogFactor = saturate(fogFactor);
                
                // 混合雾颜色
                half3 finalColor = lerp(sceneColor.rgb, _FogColor.rgb, fogFactor);
                return half4(finalColor, sceneColor.a);
            }
            ENDHLSL
        }
    }
}