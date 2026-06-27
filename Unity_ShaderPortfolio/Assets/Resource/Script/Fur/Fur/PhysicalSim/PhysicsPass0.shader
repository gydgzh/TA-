// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "URP/PhysicsPass0"
{
	Properties
	{
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		_w("w",Range(-1,1)) = 0.0

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

			float4 _WorldPosition;


			
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
				return o;
			}

			half4 frag ( VertexOutput IN  ) : SV_Target
			{

				float3 Color = ( IN.worldpos - _WorldPosition);
				float Alpha = 1;

				return half4( Color, Alpha );
			}

			ENDHLSL
		}

	
	}
	Fallback "Hidden/InternalErrorShader"
	
}