Shader "Hidden/HeightFog"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        //接收source图，_MainTex
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }
        LOD 100
        
        //URP shader
        Pass
        {
            //后处理的shader
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
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
            //雾的其实距离和高度
            
            
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
            
            
            //很常用的在后处理中通过深度缓冲拿到世界位置的公式
            float3 ReconstructWorldPosition(float2 uv, float depth)
            {
                // NDC坐标，投影空间 / w
                float4 ndc = float4(uv * 2 - 1, depth, 1);
                #if UNITY_UV_STARTS_AT_TOP
                    ndc.y = -ndc.y;
                #endif

                // 深度缓冲存储的深度值是 NDC 空间下的值
                float4 worldPos = mul(unity_CameraInvProjection,ndc);
                //乘以逆矩阵
                worldPos = mul(unity_CameraToWorld,worldPos);
                worldPos /= worldPos.w;
                
                return worldPos.xyz;
            }
            
            
            half4 frag(v2f i) : SV_Target
            {
                half4 sceneColor = tex2D(_MainTex,i.uv);
                
                float depth = SampleSceneDepth(i.uv);
                //这个深度就是屏幕uv
                float linearDepth = LinearEyeDepth(depth ,_ZBufferParams);
                //把深度贴图里那种“0~1 的非线性深度值”转换成“从相机到物体的真实线性距离”，方便用来算雾等效果
                
                float3 worldPos = ReconstructWorldPosition(i.uv, depth);
                
                // 计算雾效
                float fogDistance = max(0.0, linearDepth - _FogStartDistance);
                fogDistance = min(fogDistance, _FogMaxDistance);
                
                float heightFactor = max(0.0, (_FogHeight - worldPos.y) * _FogHeightFalloff);
                float fogDensity = _FogDensity * exp(-heightFactor);
                
                float fogFactor = 1.0 - exp(-fogDensity * fogDistance);
                //距离越大 / 密度越大，雾因子越接近 1（雾越浓)
                fogFactor = saturate(fogFactor);
                
                // 混合雾颜色
                half3 finalColor = lerp(sceneColor.rgb, _FogColor.rgb, fogFactor);
                //把原画颜色和雾的颜色按照比例混合
                //fogFactor = 0 → finalColor = 原画面（没雾）
                //fogFactor = 1 → finalColor = 纯雾色（全雾）
                //fogFactor = 0.3 → 30% 雾色 + 70% 原画面
                
                return half4(finalColor, 1);
            }
            
            
            
            ENDHLSL
        }
    }
}