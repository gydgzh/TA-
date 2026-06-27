Shader "TA/Portal/PortalMask"
{
    Properties
    {
        _Radius("Radius", Range(0.01, 1.0)) = 0.46
        _EdgeSoftness("Edge Softness", Range(0.001, 0.30)) = 0.03
        [IntRange]_StencilRef("Stencil Ref", Range(0, 255)) = 2
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "Queue"="Transparent" "RenderType"="Transparent" }

        Pass
        {
            Name "PortalMask"
            Tags { "LightMode"="SRPDefaultUnlit" }

            Cull Off
            ZWrite Off
            Blend One Zero
            ColorMask 0

            Stencil
            {
                Ref [_StencilRef]
                Comp Always
                Pass Replace
            }

            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float _Radius;
                float _EdgeSoftness;
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

                float alpha = 1.0 - smoothstep(_Radius, _Radius + _EdgeSoftness, r);
                clip(alpha - 0.001);

                return half4(0, 0, 0, 0);
            }
            ENDHLSL
        }
    }
}
