Shader "TA/Portal/PortalTunnelGlitch"
{
    Properties
    {
        _Color("Color", Color) = (0.20, 0.90, 1.0, 1.0)
        _Brightness("Brightness", Range(0.0, 10.0)) = 2.5
        _ScrollSpeed("Scroll Speed", Range(0.0, 10.0)) = 1.6
        _StripeTiling("Stripe Tiling", Range(1.0, 40.0)) = 12.0
        _TwistAmount("Twist Amount", Range(0.0, 30.0)) = 8.0
        _GlitchAmount("Glitch Amount", Range(0.0, 2.0)) = 0.5
        _FadeStart("Fade Start", Range(0.0, 1.0)) = 0.65
        _FadeLength("Fade Length", Range(0.001, 1.0)) = 0.30
        _Opacity("Opacity", Range(0.0, 3.0)) = 1.0
        [IntRange]_StencilRef("Stencil Ref", Range(0, 255)) = 2
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "Queue"="Transparent+2" "RenderType"="Transparent" }

        Pass
        {
            Name "PortalTunnel"
            Tags { "LightMode"="SRPDefaultUnlit" }

            Cull Front
            ZWrite Off
            Blend SrcAlpha One

            Stencil
            {
                Ref [_StencilRef]
                Comp Equal
                Pass Keep
            }

            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float _Brightness;
                float _ScrollSpeed;
                float _StripeTiling;
                float _TwistAmount;
                float _GlitchAmount;
                float _FadeStart;
                float _FadeLength;
                float _Opacity;
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
                p = frac(p * float2(127.1, 311.7));
                p += dot(p, p + 34.123);
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

            float StripeField(float2 uv, float t)
            {
                float a = sin((uv.x * _StripeTiling + (uv.y + t * _ScrollSpeed) * _TwistAmount) * 6.2831853);
                float b = sin(((1.0 - uv.x) * (_StripeTiling * 0.75) - (uv.y + t * _ScrollSpeed * 0.65) * (_TwistAmount * 1.25)) * 6.2831853);

                return saturate(a * 0.5 + 0.5) * 0.7 + saturate(b * 0.5 + 0.5) * 0.3;
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
                float2 uv = IN.uv;
                float t = _Time.y;

                float row = floor((uv.y + t * 1.5) * 24.0);
                float burst = step(1.0 - saturate(_GlitchAmount) * 0.45, Hash21(float2(row, floor(t * 10.0))));
                uv.x += (Hash21(float2(row, floor(t * 17.0))) - 0.5) * burst * _GlitchAmount * 0.08;

                float stripe = StripeField(uv, t);
                float sparkle = pow(Noise(uv * float2(48.0, 160.0) + float2(t * 5.0, -t * 9.0)), 8.0);

                float fade = 1.0 - smoothstep(_FadeStart, _FadeStart + _FadeLength, uv.y);
                float side = smoothstep(0.02, 0.12, uv.x) * smoothstep(0.02, 0.12, 1.0 - uv.x);

                float alpha = saturate((stripe * 0.9 + sparkle * 1.6 + burst * 0.3) * fade * side) * _Opacity;

                float3 col = _Color.rgb * alpha * _Brightness;
                col += burst * _GlitchAmount * 0.20;

                return half4(col, alpha);
            }
            ENDHLSL
        }
    }
}
