CBUFFER_START(_Fog)
half4  _FogParam;
half4  _FogParam1;
half4  _RayFogColor;
half4  _MieFogColor;
half4 _ExtinctionColor;
CBUFFER_END

float RayleighPhase(float cos)
{
    return (1 + cos * cos) * 0.059683;
}
float MiePhase(float cos,  float g)
{
    float g2 = g * g;
    return (((1 - g2)) / (2 + g2)) * ((1 + cos * cos) / (pow((1 + g2 - 2 * g * cos), 1.5))) * 0.119367;
}

half3 CalculateScatteringColor(float3 cameraToWorld)
{
    half3 RayFogColor = _RayFogColor.rgb;
    half3 MieFogColor = _MieFogColor.rgb;
    half FogScattering = _FogParam.x;
    half MieDistance = _FogParam.y;
    half MieG = _FogParam.w;
    half FogStartDistance = _FogParam1.z;

    float3 lightDir = _MainLightPosition;

    half dist = length(cameraToWorld);
    float3 viewDir = cameraToWorld / dist;
    float cosAngle = dot(viewDir, lightDir.xyz);
    
    // dist = max(0, dist - FogStartDistance);
    // float mieIntensity = dist / max(MieDistance, 0.01); //saturate(1 - MieDistance/distance); 
    // mieIntensity = mieIntensity * mieIntensity;

    half3 rayScattering = RayFogColor * RayleighPhase(cosAngle);
    half3 mieScattering = MieFogColor * (MiePhase(cosAngle, MieG));
    
    half3 inScattering = (rayScattering+mieScattering) * FogScattering;
    return inScattering;
}

half3 CalculateTransmittance(float3 cameraToWorld,float3 positionWS)
{
    half3 ExtinctionColor = _ExtinctionColor.rgb;
    half FogDensity = _FogParam.z;
    half FogMaxHeight = _FogParam1.x;
    half FogMinHeight = _FogParam1.y;
    half FogStartDistance = _FogParam1.z;

    half distance = max(0, length(cameraToWorld)- FogStartDistance);
    half k = 5.0 / FogMaxHeight;
    float tLen = FogDensity * exp(-k * (positionWS.y - FogMinHeight));
    tLen = max(0, tLen);
    half3 transmittance = max(0.001, min(0.999, (exp(-distance * tLen * ExtinctionColor  * 5))));

    return (transmittance);
}

half3 CalculateFog(float3 positionWS,half3 color)
{
    float3 cameraToWorld = positionWS - _WorldSpaceCameraPos;
    float3 clippedCameraToWorld = cameraToWorld;

    half3 transmittance = CalculateTransmittance(clippedCameraToWorld,positionWS);
    half3 inScattering = CalculateScatteringColor(cameraToWorld);

    inScattering *= (1 - transmittance.rgb);
    half transmittance1D = dot(transmittance.rgb, half3(0.2126, 0.7152, 0.0722));
    half4 fogFactor =  half4(inScattering, transmittance1D);
    return color.rgb * fogFactor.a + fogFactor.rgb;
    
}

