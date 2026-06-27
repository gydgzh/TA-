Shader "Custom/LocalRaymarchingFog"
{
    Properties
    {
        _FogColor("FogColor",Color) = (0.5,0.6,1,1)
        _StepSize("Step Size",Range(0.01,1)) = 0.1
        _HeightGradient("HeightGradient",Range(0.1,100)) = 1
        _Noise3D("3D Noise Texture",3D) = "white"{}
        _NoiseScale("NoiseScale",Range(0.01,10)) = 0.5
        _NoiseSpeed("NoiseSpeed",Vector) = (0.1,0.2,0.3,0)
    }
    
    SubShader
    {
        Tags { 
            "RenderType"="Transparent" 
            "Queue"="Transparent"
            "RenderPipeline" = "UniversalPipeline"
            "IgnoreProjector" = "True"
        }
        LOD 100

        Pass
        {
            Name  "LocalFog"
            Tags { "LightMode" = "UniversalForward" }
            
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Back
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };
            
            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 viewDirWS : TEXCOORD1;
            };

            float _StepSize;
            float _HeightGradient;
            float _NoiseScale;
            float4 _FogColor;
            float4 _NoiseSpeed;

            TEXTURE3D(_Noise3D);
            SAMPLER(sampler_Noise3D);

            bool rayAABBIntersection(float3 rayOrigin,float3 rayDir,float3 boundsMin,float3 boundsMax,
                out float tMin,out float tMax)
            {
                float3 invRayDir = 1 / rayDir;
                float3 t1 = (boundsMin - rayOrigin) *  invRayDir;
                float3 t2 = (boundsMax - rayOrigin) * invRayDir;

                float3 tMin3 = min(t1,t2);
                float3 tMax3 = max(t1,t2);

                tMin = max(max(tMin3.x,tMin3.y),tMin3.z);
                tMax = min(min(tMax3.x,tMax3.y),tMax3.z);

                return tMax >= tMin && tMax > 0;
            }

            float sampleNoise3D(float3 position)
            {
                float3 samplePosition = position * _NoiseScale + _NoiseSpeed.xyz * _Time.y;
                return SAMPLE_TEXTURE3D(_Noise3D,sampler_Noise3D,samplePosition);
            }

            half fogDensity(float3 pos,float3 boundsMin,float3 boundsMax)
            {
                float3 distToedge = min(pos - boundsMin,boundsMax - pos);
                float edgeFactor = min(min(distToedge.x,distToedge.y),distToedge.z);

                float fade = smoothstep(0,1,edgeFactor);

                half heightFactor = 1;
                float normalizeheight = (pos.y - boundsMin.y) / (boundsMax.y - boundsMin.y);
                heightFactor = 1 - exp(-normalizeheight * _HeightGradient);

                float noiseValue = sampleNoise3D(pos);
                return fade * heightFactor * (1 + noiseValue);
            }

            Varyings vert(Attributes input)
            {
                Varyings output;
                
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                
                // 计算视图方向
                float3 worldSpaceCameraPos = _WorldSpaceCameraPos;
                output.viewDirWS = normalize(output.positionWS - worldSpaceCameraPos);
                
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float3 boudingMinOS = float3(-0.5,-0.5,-0.5);
                float3 boudingMaxOS = float3(0.5,0.5,0.5);

                float4x4 objectToWorld = GetObjectToWorldMatrix();
                float3 boundsMinWS = mul(objectToWorld,float4(boudingMinOS,1)).xyz;
                float3 boudingMaxWS = mul(objectToWorld,float4(boudingMaxOS,1)).xyz;

                float3 rayOrigin = _WorldSpaceCameraPos;
                float3 rayDir = normalize(input.positionWS - _WorldSpaceCameraPos);

                float tMin,tMax;
                bool intersect = rayAABBIntersection(rayOrigin,rayDir,boundsMinWS,boudingMaxWS,tMin,tMax);
                if(!intersect || tMax < 0 )
                {
                    discard;
                }
                tMin = max(0,tMin);

                //初始化raymarching

                float3 entryPoint = rayOrigin + rayDir * tMin;
                float3 exitPoint = rayOrigin + rayDir * tMax;
                float rayLength = distance(exitPoint,entryPoint);

                float stepSize = _StepSize;
                int numSteps = (int)min(256,rayLength/stepSize);
                stepSize = rayLength / numSteps;

                float3 currentPos = entryPoint;
                float opticalDepth = 0.0;

                [unroll(64)]
                for (int i =0;i < numSteps; i++)
                {
                    float density = fogDensity(currentPos,boundsMinWS,boudingMaxWS) * stepSize;
                    opticalDepth += density;

                    currentPos += rayDir * stepSize;
                }

                float transparancy = exp(-opticalDepth);
                float alpha = 1 -transparancy;
                half3 finalColor = _FogColor;
                return half4(finalColor,alpha);
                
            }

            

            ENDHLSL
        }
    }
}
