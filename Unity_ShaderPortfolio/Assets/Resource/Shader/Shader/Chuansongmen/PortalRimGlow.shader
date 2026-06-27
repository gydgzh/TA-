Shader "TA/Portal/PortalRimGlow"
{
    Properties
    {
        _Color("Color", Color) = (1.00, 0.30, 1.00, 1.0)
        _Intensity("Intensity", Range(0.0, 10.0)) = 4.0
        _InnerRadius("Inner Radius", Range(0.0, 1.0)) = 0.42
        _OuterRadius("Outer Radius", Range(0.0, 1.0)) = 0.50
        _Softness("Softness", Range(0.001, 0.30)) = 0.03
        _PulseSpeed("Pulse Speed", Range(0.0, 10.0)) = 4.0
        _SegmentCount("Segment Count", Range(1.0, 64.0)) = 18.0
        _Breakup("Breakup", Range(0.0, 1.0)) = 0.35
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "Queue"="Transparent+3" "RenderType"="Transparent" }

        Pass
        {
            Name "PortalRim"
            Tags { "LightMode"="SRPDefaultUnlit" }

            Cull Off
            ZWrite Off
            Blend SrcAlpha One

            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float _Intensity;
                float _InnerRadius;
                float _OuterRadius;
                float _Softness;
                float _PulseSpeed;
                float _SegmentCount;
                float _Breakup;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv          : TEXCOORD0;
            };

            float Hash21(float2 p)
            {
                p = frac(p * float2(123.34, 345.45));
                p += dot(p, p + 34.23);
                return frac(p.x * p.y);
            }

            float Noise(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);

                float a = Hash21(i);
                float b = Hash21(i + float2(1.0, 0.0));
                float c = Hash21(i + float2(0.0, 1.0));
                float d = Hash21(i + float2(1.0, 1.0));

                float2 u = f * f * (3.0 - 2.0 * f);
                return lerp(lerp(a, b, u.x), lerp(c, d, u.x), u.y);
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float2 p = IN.uv * 2.0 - 1.0;
                float r = length(p);
                float angle = atan2(p.y, p.x);
                float t = _Time.y;

                float inner = smoothstep(_InnerRadius, _InnerRadius + _Softness, r);
                float outer = 1.0 - smoothstep(_OuterRadius, _OuterRadius + _Softness, r);
                float ring = saturate(inner * outer);

                float breakupNoise = 0.5 + 0.5 * sin(angle * _SegmentCount + t * 5.5 + Noise(p * 5.0 + t) * 6.0);
                float breakup = lerp(1.0, saturate(breakupNoise * 1.25), _Breakup);

                float flicker = 0.82 + 0.18 * sin(t * _PulseSpeed + Noise(float2(angle * 2.0, t * 0.8)) * 6.2831);

                float alpha = ring * breakup * flicker;
                clip(alpha - 0.001);

                float3 col = _Color.rgb * alpha * _Intensity;
                return half4(col, alpha);
            }
            ENDHLSL
        }
    }
}
