// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "URP/PhysicsPass2"
{
	Properties
	{
		_w("w",Range(-1,1)) = 0.0
		_InputMap("Input Map", 2D) = "white" {}
        _GroomingMap("Grooming Map", 2D) = "white" {}
        _VFXMap("VFX Map",2D) = "black"{}
        _PhysicsMap("Physics Map", 2D) = "black"{}
        _HasGroomData("Has Groom Data", Float) = 0
        _InputType("Input Type", Float) = 0
        _WorldDirection("World Direction", Vector) = (0, 0, 0, 0)
        _PhysicsThreshold("Physics Threshold", Float) = 0

	}

	SubShader
	{
		LOD 0

		
		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }
		
		Cull Back
		HLSLINCLUDE
		#pragma target 2.0
		ENDHLSL

		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }
			
			

			HLSLPROGRAM
			#define _RECEIVE_SHADOWS_OFF 1
			#define ASE_SRP_VERSION 999999

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			float _w;
			

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
			};

			struct VertexOutput
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 worldpos : TEXCOORD1;
			};

                float _XFurBasicMode;
                float4x4 _XFurObjectMatrix;
                float4 _WorldPosition;


			    sampler2D _InputMap;
                sampler2D _PhysicsMap;
                float _PhysicsThreshold;
                float _InputType;
                float4 _InputMap_ST;
                float4 _WorldDirection;
                float _XFurGravityStrength;
                float _XFurPhysicsSensitivity;

			
			VertexOutput vert ( VertexInput v  )
			{

				VertexOutput o = (VertexOutput)0;

				#if UNITY_UV_STARTS_AT_TOP
				v.ase_texcoord.y = 1.0 - v.ase_texcoord.y;
                #endif

				float4 appendResult9 = float4(v.ase_texcoord.x * 2.0 - 1 , v.ase_texcoord.y * 2 -1 , 0.0 ,1);
				float3 worldpos = mul( GetObjectToWorldMatrix(), v.vertex).xyz;

				o.vertex = appendResult9;
				o.worldpos = worldpos;
				o.uv = v.ase_texcoord;
				return o;
			}

			half4 frag ( VertexOutput IN  ) : SV_Target
			{
				#if UNITY_UV_STARTS_AT_TOP
				IN.uv.y = 1.0 - IN.uv.y;
                #endif

				float4 col1 = tex2D( _InputMap, IN.uv.xy );
                float4 col2 = tex2D( _PhysicsMap, IN.uv.xy );
                float4 norm = lerp( col2, col1, 0.25 );
                        //norm.xyz += _WorldDirection.xyz*0.25;
				return norm;

			}

			ENDHLSL
		}

	
	}
	Fallback "Hidden/InternalErrorShader"
	
}
