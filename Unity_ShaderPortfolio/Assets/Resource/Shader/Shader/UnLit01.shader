Shader "Custom/UnLit"
// shader路径名
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)

        [Header(Depth Setting)]
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("DepthTest",float) = 4
        [Toggle] _ZWrite("DepthWrite",float) = 1

        // 透明混合用（不透明：One/Zero；透明：SrcAlpha/OneMinusSrcAlpha）
        [Header(Blend Setting)]
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("SrcBlend", float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("DstBlend", float) = 0

        //模版测试
        // ★ 修正：Range(0.255) -> Range(0,255)，否则语法错误
        _StencilRef("Stencil", Range(0,255)) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp("Stencil Comparsion",float) = 8
        // 8 = Always，表示模板测试永远通过（默认当没开模板）
    }

    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"//不透明物体
            // 正确的 URP 标记：
            "RenderPipeline" = "UniversalRenderPipeline"
            //告诉unity- URP
            "Queue" = "Geometry"
            //渲染队列，普通几何体（在透明物体之前）
        }

        Pass
        //第一次绘制过程
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }
            //这个 Pass 用来做 URP 的前向（Forward）主渲染（画最终颜色的那一步）

            // 固定管线状态（非常关键）
            ZTest  [_ZTest]
            ZWrite [_ZWrite]
            Blend  [_SrcBlend] [_DstBlend]



            // ★★ 新增：真正启用模板测试 ★★
            Stencil
            {
                Ref [_StencilRef]        // 使用面板里的模板值
                Comp [_StencilComp]      // 使用面板里的比较函数（Always/Equal 等）
                Pass Replace             // 通过测试时把模板缓冲写成 Ref 的值
            }


            HLSLPROGRAM//接下来是HLSL代码
            // 函数名要和下面一致
            #pragma vertex vert//顶点着色器的名叫vert
            #pragma fragment frag//片元着色器#
            #pragma enable_d3d11_debug_symbols

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
            //GPU常量缓冲区
                float4 _Color;
            CBUFFER_END

            struct Attributes
            //这个字段是顶点位置
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                //Clip Space裁剪空间-SV_POSITION 是“系统值”，告诉 GPU
            };

            Varyings vert (Attributes input)
            {
                //把模型的空间坐标变换为屏幕坐标
                Varyings output;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = vertexInput.positionCS;
                return output;
            }

            half4 frag (Varyings input) : SV_Target
            //片元着色器，给每个像素上色
            {
                return _Color;   // 使用正确的变量名
                //这个物体上所有像素都会被画成同一种颜色（材质里设定的 _Color）
            }

            ENDHLSL
        }
    }
}
