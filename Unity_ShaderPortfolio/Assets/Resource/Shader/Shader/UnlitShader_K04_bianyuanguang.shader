// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/KKK/UnlitShader_K04_bianyuanguang"
{
    Properties
    {
        _Float("浮点数",Float) = 0.0
        _Range("带范围的浮点数值",Range(0.0,1.0)) = 0.0
        _Vector("Vector",Vector) = (1,1,1,1)
        _Color("Color",Color) = (0.5,0.5,0.5,0.5)

        _MainTexture("MainTexture", 2D) = "white" {}
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("CullMode", float) = 2
        _MainColor("MainColor",Color) = (1,1,1,1)

        // 【新增】和教程一致：发光强度 & 边缘收敛
        _Emiss("Emiss", Range(0,10)) = 1
        _RimPower("RimPower", Range(0.1,8)) = 2
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" "RenderPipeline"="UniversalPipeline" }

        Pass
        {
            Tags { "LightMode"="SRPDefaultUnlit" }

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull [_CullMode]

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv     : TEXCOORD0;
                float3 normal : NORMAL;
                float4 color  : COLOR;
            };

            struct v2f
            {
                float4 pos          : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 normal_world : TEXCOORD1;
                float3 view_world   : TEXCOORD2;
            };

            sampler2D _MainTexture;
            float4 _MainTexture_ST;

            float4 _MainColor;
            float  _Emiss;
            float  _RimPower;

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                // 跟教程写法非常接近
                o.normal_world = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject).xyz);

                float3 pos_world = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.view_world = normalize(_WorldSpaceCameraPos.xyz - pos_world);

                o.uv = v.uv * _MainTexture_ST.xy + _MainTexture_ST.zw;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float3 n = normalize(i.normal_world);
                float3 v = normalize(i.view_world);

                float NdV = saturate(dot(n, v));
                float rim = pow(1.0 - NdV, _RimPower) * _Emiss;

                float mask = tex2D(_MainTexture, i.uv).r;

                float3 col   = _MainColor.rgb * rim;
                float  alpha = saturate(mask) * _MainColor.a * rim;

                return float4(col, alpha);
            }
            ENDCG
        }
    }
}
