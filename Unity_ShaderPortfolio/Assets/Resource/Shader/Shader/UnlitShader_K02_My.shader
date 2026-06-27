// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/KKK/UnlitShader_K02_My"//shader的名字
{
    Properties
    //对应材质面板控制的参数
    {
        _Float("浮点数",Float) = 0.0
        //可以生成可调节的数值
        //_MyFloat-变量的名字，可以随便起-("float-外面显示的名字",Float-参数类型) = 0.0-默认值
        
        //带范围可以拖拽的浮点数值
        _Range("带范围的浮点数值",Range(0.0,1.0)) = 0.0
        
        //多维数据
        _Vector("Vector",Vector) = (1,1,1,1)
        _Color("Color",Color) = (0.5,0.5,0.5,0.5)
        
        //贴图
        _MainTexture("MainTexture", 2D) = "white"{}//默认白色贴图
        
        
    }
    SubShader
    {
        Pass//在Pass里面写shader代码、一个shader里也可以有多个PASS
        {
            Cull Off //如果想把背面剔除关掉
            
            //虽然这个笔记里用CG，但是因为CG已经不更新了所以之后都会换成HLSL
            CGPROGRAM
            #pragma vertex vert
            //定义一个定点shader名字叫vert
            #pragma fragment frag 
            //定义片元shader
            
            //一些头文件
            #include  "UnityCG.cginc"
            
            //想CPU端拿一些数据
            struct appdata
            {
                float4 vertex : POSITION;//拿这个图形的顶点坐标，vertex随便填
                float2 uv : TEXCOORD0;//第一套UV（最多可以写4套uv
                // float2 uv2 : TEXCOORD2;
                // float2 uv3 : TEXCOORD3;
                // float2 uv4 : TEXCOORD4;
                float3 normal : NORMAL;
                float4 color : COLOR;
                //这些都是特定的语义词
                
            };
             
            //输出的结构体定义
            struct v2f
            {
                float4 pos : SV_POSITION;//输出定点坐标，SV_POSITION是特定的语义词
                
                //定义结构体输出UV值
                float2 uv : TEXCOORD0;//储存器 插值器,通用，可以存放任何数据
                //可以从0 写到15，总共16个可用
                
                // float3 normal : TEXCOORD1;
            };
            
            //调整颜色，和上面Properties的_Color一致
            float4 _Color;
            //接收贴图
            sampler2D _MainTexture;
            //如果想调整材质的tilling面板数值
            float4 _MainTexture_ST;
            
            
            //写顶点shader，名字是前面这个-#pragma vertex vert一样的，就能找到
            v2f vert(appdata v)//定点着色器
            {
                //先初始化输出数据
                v2f o;
                
                // //顶点v.vertex从模型空间转化成世界空间
                // //mul矩阵乘法
                // float4 pos_world = mul(unity_ObjectToWorld, v.vertex); // 世界坐标
                // // 或者：float4 clipPos = UnityObjectToClipPos(v.vertex);   // 直接到裁剪空间
                //  
                // //世界空间转换成相机空间
                // float4 pos_view = mul(UNITY_MATRIX_I_V,pos_world);
                // //转换到裁剪空间
                // float4 pos_clip = mul(UNITY_MATRIX_P,pos_view);
                // //把裁剪空间上的坐标点赋予o.pos
                // o.pos = pos_clip;
                o.pos = UnityObjectToClipPos(v.vertex);
                //unity改版了
                
                //贴图效果实现
                o.uv = v.uv * _MainTexture_ST.xy + _MainTexture_ST.zw;

                return o;
            }
            
            //片元shader（unity改版了2022现在用这个）
            float4 frag(v2f i) : SV_Target//渲染的目标
            {
                float4 col = tex2D(_MainTexture,i.uv);
                // return _Color;//输出一个颜色值
                return col;
            }
            
            ENDCG
            //精度：float-32位（给坐标点使用）、half-16（UV、大部分向量）、fixed-8（颜色）

        }
    }
}