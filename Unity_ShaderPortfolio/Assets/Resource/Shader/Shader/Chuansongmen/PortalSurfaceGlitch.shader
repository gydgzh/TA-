Shader "TA/Portal/PortalSurfaceGlitch"
{
    Properties
    {
        _ColorA("Color A", Color) = (0.08, 0.85, 1.0, 1.0)
        _ColorB("Color B", Color) = (0.80, 0.15, 1.0, 1.0)
        _Brightness("Brightness", Range(0.0, 10.0)) = 2.2
        _SwirlSpeed("Swirl Speed", Range(0.0, 10.0)) = 1.8
        _SwirlTiling("Swirl Tiling", Range(1.0, 20.0)) = 7.0
        _GlitchAmount("Glitch Amount", Range(0.0, 2.0)) = 0.65
        _LineDensity("Scan Line Density", Range(20.0, 400.0)) = 180.0
        _RGBSplit("RGB Split", Range(0.0, 2.0)) = 0.9
        _Radius("Radius", Range(0.01, 1.0)) = 0.46
        _EdgeSoftness("Edge Softness", Range(0.001, 0.30)) = 0.04
        _PulseSpeed("Pulse Speed", Range(0.0, 10.0)) = 3.2
        [IntRange]_StencilRef("Stencil Ref", Range(0, 255)) = 2
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "Queue"="Transparent+1" "RenderType"="Transparent" }

        Pass
        {
            Name "PortalSurface"
            Tags { "LightMode"="SRPDefaultUnlit" }

            Cull Off
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

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
                float4 _ColorA;
                float4 _ColorB;
                float _Brightness;
                float _SwirlSpeed;
                float _SwirlTiling;
                float _GlitchAmount;
                float _LineDensity;
                float _RGBSplit;
                float _Radius;
                float _EdgeSoftness;
                float _PulseSpeed;
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
                p = frac(p * float2(123.34, 456.21));
                p += dot(p, p + 45.32);
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

            float FBM(float2 p)
            {
                float value = 0.0;
                float amp = 0.5;

                [unroll]
                for (int i = 0; i < 4; i++)
                {
                    value += Noise(p) * amp;
                    p = p * 2.02 + 17.13;
                    amp *= 0.5;
                }

                return value;
            }

            float PortalPattern(float2 p, float t, float channelShift)
            {
                float r = length(p);
                float ang = atan2(p.y, p.x);
                float n = FBM(p * 3.0 + float2(t * 0.55 + channelShift * 3.1, -t * 0.45));

                float swirl = sin(ang * _SwirlTiling - r * 12.0 + t * _SwirlSpeed + n * 6.2831 + channelShift);
                float bands = sin(r * 22.0 - t * 5.0 + n * 8.0);

                return saturate(0.5 + 0.30 * swirl + 0.25 * bands + 0.35 * n);
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
                float2 p = uv * 2.0 - 1.0;
                float r = length(p);

                float edge = 1.0 - smoothstep(_Radius, _Radius + _EdgeSoftness, r);
                clip(edge - 0.001);

                float t = _Time.y;

                float lineId = floor((uv.y + t * 2.0) * 42.0);
                float blockNoise = Hash21(float2(lineId, floor(t * 6.0)));
                float burstGate = step(1.0 - saturate(_GlitchAmount) * 0.35, blockNoise);

                float xOffset = (Hash21(float2(lineId, floor(t * 13.0))) - 0.5) * burstGate * _GlitchAmount * 0.18;
                p.x += xOffset;

                float split = _RGBSplit * (0.006 + burstGate * 0.020);

                float pr = PortalPattern(p + float2(split, 0.0), t, 0.70);
                float pg = PortalPattern(p, t, 0.00);
                float pb = PortalPattern(p - float2(split, 0.0), t, -0.70);

                float scan = 0.5 + 0.5 * sin((uv.y + t * 6.0) * _LineDensity);
                float core = saturate(1.0 - r * 1.35);
                float pulse = 0.75 + 0.25 * sin(t * _PulseSpeed);

                float3 col = float3(
                    lerp(_ColorA.r, _ColorB.r, pr),
                    lerp(_ColorA.g, _ColorB.g, pg),
                    lerp(_ColorA.b, _ColorB.b, pb)
                );

                col *= (0.45 + 0.55 * scan) * (0.45 + 0.55 * core) * _Brightness * pulse;
                col += burstGate * _GlitchAmount * 0.40;

                float alpha = edge * saturate(0.45 + core * 0.45 + scan * 0.20);

                return half4(col, alpha);
            }
            ENDHLSL
        }
    }
}
