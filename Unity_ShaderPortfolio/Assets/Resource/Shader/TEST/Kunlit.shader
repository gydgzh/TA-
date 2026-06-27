// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "CS0102/01Unlit_Kunlit"//shader的名字，写脚本的时候是调用这个名字，外面的文件名字只是文件的命名
//名字可以采用目录式结构
{
    Properties
    {
        //对应材质参数面板的参数
        _MainText("MainText",2D)="black"{}     // 贴图
        _Float("Float",Float) = 0.0
        //_Float_变量的名字，可以随便起_("Float"_外面显示的文本，也可以叫“浮点数_,Float_固定，参数类型_) = 0.0_默认值，默认状态下的值
        _Range("Range",Range(0.0,1.0))=0.0//代范围可以拖拽的数值
        _Vector("Vector",Vector)=(1,1,1,1)//多维可调整参数
        _Color("Color",Color)=(0.5,0.5,0.5,0.5)//颜色块
        //_Texture("Texture",2D)="white"{}//贴图，默认状态是白色贴图
    }
    SubShader
    {
        Pass//里面写shader代码：一个完整的GPU渲染管线
        //模型数据-定点shader-图元装配以及光栅化-片段Shader-输出合并
        //可以写多个Pass
        {
            CGPROGRAM//这些都属于一个unityCG的代码范围之内
            #pragma vertex vert
            #pragma fragment frag 
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION ;//特定的语义词表示模型的定点坐标
                float2 uv     : TEXCOORD0;//如果拿到uv希望实现贴图效果-TEXCOORD0值的是第一套uv
                //最多可以写4套UV
                // float2 uv2    : TEXCOORD1;
                // float2 uv3    : TEXCOORD2;
                // float2 uv4    : TEXCOORD3;
                // float3 normal : NORMAL;
                // float4 color  : COLOR;
            };

            struct v2f//
            {
                float4 pos : SV_POSITION;
                float2 uv  : TEXCOORD0;//储存器 通用 ，可以从0-15，总共有16个可用
                // float3 normal : TEXCOORD0;

            };
            
            float4 _Color;//Pass里声明同样的变量，和上面模块链接
            sampler2D _MainText;//接受来自材质参数面板的数据.sampler2D贴图类型
            float4 _MainText_ST;//和贴图的四个参数产生链接（Tiling/Offset）

            v2f vert (appdata v)//之前的vert函数，定点着色器
            {
                v2f o;
                // float4 pos_world = mul(unity_ObjectToWorld, v.vertex);//mul矩阵乘法,模型空间转换到世界空间
                // float4 pos_view  = mul(UNITY_MATRIX_V, pos_world);//世界空间转换到相机空间（注意这里 MATRIX 拼写）
                // float4 pos_clip  = mul(UNITY_MATRIX_P, pos_view);//转换到裁剪空间

                //一步从模型空间转换到裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);

                // o.pos = pos_clip;
                o.uv  = v.uv * _MainText_ST.xy + _MainText_ST.zw ;   // xy-缩放；zw-偏移
                return o;
            }

            //精度；
            //float = 32 坐标点
            //half = 16 UV，大部分向量使用
            //fixed = 8 颜色，很少用了

            //片元Shader
            float4 frag(v2f i) : SV_Target//渲染的目标
            {
                float4 col = tex2D(_MainText,i.uv);//贴图采样
                return col * _Color;  
            }

            ENDCG

        }
    }
}
