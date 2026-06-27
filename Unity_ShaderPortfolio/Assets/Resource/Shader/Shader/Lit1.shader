Shader "Custom/BasicCullUnlitDebug"
{
    Properties
    {
        _BaseMap ("Base Map", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (1,1,1,1)

        // Front -> Cull Back(2), Back -> Cull Front(1), Both -> Cull Off(0)
        [Enum(Front,2,Back,1,Both,0)] _RenderFace ("Render Face", Float) = 2

        [Toggle] _DebugFaces ("Debug Faces", Float) = 1
        _FrontColor ("Front Face Color", Color) = (1,0,0,1)
        _BackColor  ("Back Face Color",  Color) = (0,0,1,1)
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }

        Pass
        {
            Tags { "LightMode"="SRPDefaultUnlit" }

            Cull [_RenderFace]
            ZWrite On
            ZTest LEqual

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

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

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _BaseMap_ST;
                float  _DebugFaces;
                float4 _FrontColor;
                float4 _BackColor;
            CBUFFER_END

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            half4 frag (Varyings IN, FRONT_FACE_TYPE frontFace : FRONT_FACE_SEMANTIC) : SV_Target
            {
                half4 tex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
                half4 col = tex * _BaseColor;

                if (_DebugFaces > 0.5)
                {
                    half isFront = IS_FRONT_VFACE(frontFace, 1.0, 0.0);
                    col = lerp(_BackColor, _FrontColor, isFront);
                }

                return col;
            }
            ENDHLSL
        }
    }
}
