#ifndef UNIVERSAL_SURFACE_DATA_INCLUDED
#define UNIVERSAL_SURFACE_DATA_INCLUDED

// Extended SurfaceData for custom materials (FOLIAGE / ICE / WATER / SILK).
// IMPORTANT: This file must be included BEFORE URP's Lighting.hlsl in shaders that need the extra fields,
// otherwise URP's own SurfaceData will be included first and your extra fields won't exist.

// Backward-compatibility: older files used a misspelling "scaterringColor".
#ifndef scaterringColor
    #define scaterringColor scatteringColor
#endif

struct SurfaceData
{
    half3 albedo;
    half3 specular;
    half  metallic;
    half  smoothness;
    half3 normalTS;
    half3 emission;
    half  occlusion;
    half  alpha;
    half  clearCoatMask;
    half  clearCoatSmoothness;

    // -------- Extended fields --------

    #if defined(_FOLIAGE) || defined(_ICE) || defined(_WATER)
    half4 scatteringColor;
    #endif

    #if defined(_ICE) || defined(_WATER)
    half  specularScale;
    #endif

    #ifdef _WATER
    half4 reflectionColor;
    half  scatter;
    #endif

    #ifdef _ICE
    half  thickness;
    #endif

    #ifdef _SILK
    half3 tangentWS;
    half  aniso;
    #endif
};

#endif // UNIVERSAL_SURFACE_DATA_INCLUDED
