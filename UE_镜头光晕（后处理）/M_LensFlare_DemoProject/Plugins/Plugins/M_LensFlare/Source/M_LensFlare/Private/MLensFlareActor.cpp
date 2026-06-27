#include "MLensFlareActor.h"
#include "MLensFlarePreset.h"
#include "Components/PostProcessComponent.h"
#include "Materials/MaterialInterface.h"
#include "Materials/MaterialInstanceDynamic.h"

namespace
{
	const TCHAR* DefaultThresholdPath = TEXT("/M_LensFlare/Materials/M_LF_Threshold.M_LF_Threshold");
	const TCHAR* DefaultBlurHPath     = TEXT("/M_LensFlare/Materials/M_LF_BlurH.M_LF_BlurH");
	const TCHAR* DefaultBlurVPath     = TEXT("/M_LensFlare/Materials/M_LF_BlurV.M_LF_BlurV");
	const TCHAR* DefaultFlareGenPath  = TEXT("/M_LensFlare/Materials/M_LF_FlareGen.M_LF_FlareGen");
	const TCHAR* DefaultCompositePath = TEXT("/M_LensFlare/Materials/M_LF_Composite.M_LF_Composite");
}

AMLensFlareActor::AMLensFlareActor()
{
	PrimaryActorTick.bCanEverTick = true;
	PrimaryActorTick.bStartWithTickEnabled = true;

	PostProcess = CreateDefaultSubobject<UPostProcessComponent>(TEXT("PostProcess"));
	SetRootComponent(PostProcess);
	PostProcess->bUnbound = true;

	ThresholdMaterial = FSoftObjectPath(DefaultThresholdPath);
	BlurHMaterial     = FSoftObjectPath(DefaultBlurHPath);
	BlurVMaterial     = FSoftObjectPath(DefaultBlurVPath);
	FlareGenMaterial  = FSoftObjectPath(DefaultFlareGenPath);
	CompositeMaterial = FSoftObjectPath(DefaultCompositePath);
}

void AMLensFlareActor::OnConstruction(const FTransform& Transform)
{
	Super::OnConstruction(Transform);
	BuildPipeline();
	ApplyPreset();
}

void AMLensFlareActor::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);
	if (bUpdateEveryFrame)
	{
		ApplyPreset();
	}
}

void AMLensFlareActor::SetPreset(UMLensFlarePreset* InPreset)
{
	Preset = InPreset;
	ApplyPreset();
}

void AMLensFlareActor::BuildPipeline()
{
	PipelineMIDs.Reset();
	PostProcess->Settings.WeightedBlendables.Array.Reset();

	const TSoftObjectPtr<UMaterialInterface> Mats[] =
	{
		ThresholdMaterial, BlurHMaterial, BlurVMaterial, FlareGenMaterial, CompositeMaterial
	};

	for (const TSoftObjectPtr<UMaterialInterface>& SoftMat : Mats)
	{
		UMaterialInterface* Mat = SoftMat.LoadSynchronous();
		if (!Mat)
		{
			continue; // 材质尚未创建时静默跳过，便于插件分阶段搭建
		}
		UMaterialInstanceDynamic* MID = UMaterialInstanceDynamic::Create(Mat, this);
		PipelineMIDs.Add(MID);
		PostProcess->Settings.WeightedBlendables.Array.Emplace(1.0f, MID);
	}
}

void AMLensFlareActor::ApplyPreset()
{
	if (!Preset)
	{
		return;
	}
	for (UMaterialInstanceDynamic* MID : PipelineMIDs)
	{
		if (MID)
		{
			PushParams(MID);
		}
	}
}

void AMLensFlareActor::PushParams(UMaterialInstanceDynamic* MID) const
{
	const FMLFGlobalSettings&    G  = Preset->Global;
	const FMLFGhostSettings&     Gh = Preset->Ghost;
	const FMLFHaloSettings&      Ha = Preset->Halo;
	const FMLFStreakSettings&    St = Preset->Streak;
	const FMLFIrisSettings&      Ir = Preset->Iris;
	const FMLFStarburstSettings& Sb = Preset->Starburst;
	const FMLFLensDirtSettings&  Ld = Preset->LensDirt;

	// ---- Global ----
	MID->SetScalarParameterValue(TEXT("GlobalIntensity"), G.GlobalIntensity);
	MID->SetScalarParameterValue(TEXT("Threshold"),       G.Threshold);
	MID->SetScalarParameterValue(TEXT("SoftKnee"),        G.SoftKnee);
	MID->SetScalarParameterValue(TEXT("BlurRadius"),      G.BlurRadius);
	MID->SetVectorParameterValue(TEXT("GlobalTint"),      G.GlobalTint);
	MID->SetScalarParameterValue(TEXT("EdgeFadeStart"),   G.EdgeFadeStart);
	MID->SetScalarParameterValue(TEXT("EdgeFadePower"),   G.EdgeFadePower);

	// ---- Ghost ----
	MID->SetScalarParameterValue(TEXT("GhostEnabled"),     Gh.bEnabled ? 1.0f : 0.0f);
	MID->SetScalarParameterValue(TEXT("GhostIntensity"),   Gh.Intensity);
	MID->SetScalarParameterValue(TEXT("GhostCount"),       (float)Gh.Count);
	MID->SetScalarParameterValue(TEXT("GhostSpacing"),     Gh.Spacing);
	MID->SetScalarParameterValue(TEXT("GhostFadePower"),   Gh.FadePower);
	MID->SetScalarParameterValue(TEXT("GhostCA"),          Gh.ChromaticAberration);
	MID->SetScalarParameterValue(TEXT("GhostSpectrum"),    Gh.bSpectrumColor ? 1.0f : 0.0f);
	MID->SetScalarParameterValue(TEXT("GhostSpectrumSat"), Gh.SpectrumSaturation);
	MID->SetVectorParameterValue(TEXT("GhostTint"),        Gh.Tint);

	// ---- Halo ----
	MID->SetScalarParameterValue(TEXT("HaloEnabled"),   Ha.bEnabled ? 1.0f : 0.0f);
	MID->SetScalarParameterValue(TEXT("HaloIntensity"), Ha.Intensity);
	MID->SetScalarParameterValue(TEXT("HaloRadius"),    Ha.Radius);
	MID->SetScalarParameterValue(TEXT("HaloFalloff"),   Ha.FalloffPower);
	MID->SetScalarParameterValue(TEXT("HaloCA"),        Ha.ChromaticAberration);
	MID->SetVectorParameterValue(TEXT("HaloTint"),      Ha.Tint);

	// ---- Anamorphic Streak ----
	MID->SetScalarParameterValue(TEXT("StreakEnabled"),   St.bEnabled ? 1.0f : 0.0f);
	MID->SetScalarParameterValue(TEXT("StreakIntensity"), St.Intensity);
	MID->SetScalarParameterValue(TEXT("StreakLength"),    St.Length);
	MID->SetScalarParameterValue(TEXT("StreakFalloff"),   St.FalloffPower);
	MID->SetScalarParameterValue(TEXT("StreakSquash"),    St.VerticalSquash);
	MID->SetVectorParameterValue(TEXT("StreakTint"),      St.Tint);

	// ---- Iris ----
	MID->SetScalarParameterValue(TEXT("IrisEnabled"),   Ir.bEnabled ? 1.0f : 0.0f);
	MID->SetScalarParameterValue(TEXT("IrisIntensity"), Ir.Intensity);
	MID->SetScalarParameterValue(TEXT("IrisBlades"),    (float)Ir.BladeCount);
	MID->SetScalarParameterValue(TEXT("IrisScale"),     Ir.Scale);
	MID->SetScalarParameterValue(TEXT("IrisOffset"),    Ir.Offset);
	MID->SetScalarParameterValue(TEXT("IrisRotation"),  Ir.Rotation);
	MID->SetScalarParameterValue(TEXT("IrisSoftness"),  Ir.EdgeSoftness);
	MID->SetVectorParameterValue(TEXT("IrisTint"),      Ir.Tint);

	// ---- Starburst ----
	MID->SetScalarParameterValue(TEXT("StarEnabled"),    Sb.bEnabled ? 1.0f : 0.0f);
	MID->SetScalarParameterValue(TEXT("StarIntensity"),  Sb.Intensity);
	MID->SetScalarParameterValue(TEXT("StarRayCount"),   (float)Sb.RayCount);
	MID->SetScalarParameterValue(TEXT("StarRayLength"),  Sb.RayLength);
	MID->SetScalarParameterValue(TEXT("StarRotation"),   Sb.Rotation);
	MID->SetScalarParameterValue(TEXT("StarCameraRot"),  Sb.bRotateWithCamera ? 1.0f : 0.0f);
	MID->SetVectorParameterValue(TEXT("StarTint"),       Sb.Tint);

	// ---- Lens Dirt ----
	MID->SetScalarParameterValue(TEXT("DirtEnabled"),   Ld.bEnabled ? 1.0f : 0.0f);
	MID->SetScalarParameterValue(TEXT("DirtIntensity"), Ld.Intensity);
	if (Ld.DirtTexture)
	{
		MID->SetTextureParameterValue(TEXT("DirtTexture"), Ld.DirtTexture);
	}

	// ---- Texture Style（贴图驱动层；子层 bEnabled 关闭即把该层强度推 0）----
	const FMLFTexStyleSettings& Tx = Preset->TexStyle;
	const bool bTxOn = Tx.bEnabled;
	MID->SetScalarParameterValue(TEXT("Intensity"),          bTxOn ? Tx.Intensity : 0.0f);
	MID->SetVectorParameterValue(TEXT("SourceUV"),           FLinearColor(Tx.SourceUV.X, Tx.SourceUV.Y, 0.0f, 1.0f));
	MID->SetScalarParameterValue(TEXT("GlobalScale"),        Tx.GlobalScale);
	MID->SetScalarParameterValue(TEXT("ChromaShift"),        Tx.ChromaShift);
	MID->SetScalarParameterValue(TEXT("TexGhostCount"),      (float)Tx.GhostCount);
	MID->SetScalarParameterValue(TEXT("TexGhostSpacing"),    Tx.GhostSpacing);
	MID->SetScalarParameterValue(TEXT("GlowIntensity"),      (bTxOn && Tx.bGlow)      ? Tx.GlowIntensity      : 0.0f);
	MID->SetScalarParameterValue(TEXT("GlowSize"),           Tx.GlowSize);
	MID->SetScalarParameterValue(TEXT("TexStreakIntensity"), (bTxOn && Tx.bStreak)    ? Tx.StreakIntensity    : 0.0f);
	MID->SetScalarParameterValue(TEXT("TexStreakLength"),    Tx.StreakLength);
	MID->SetScalarParameterValue(TEXT("StreakThick"),        Tx.StreakThick);
	MID->SetScalarParameterValue(TEXT("RingIntensity"),      (bTxOn && Tx.bRing)      ? Tx.RingIntensity      : 0.0f);
	MID->SetScalarParameterValue(TEXT("RingSize"),           Tx.RingSize);
	MID->SetScalarParameterValue(TEXT("TexGhostIntensity"),  (bTxOn && Tx.bGhost)     ? Tx.GhostIntensity     : 0.0f);
	MID->SetScalarParameterValue(TEXT("GhostSizeMul"),       Tx.GhostSizeMul);
	MID->SetScalarParameterValue(TEXT("ApertureIntensity"),  (bTxOn && Tx.bAperture)  ? Tx.ApertureIntensity  : 0.0f);
	MID->SetScalarParameterValue(TEXT("ApertureSizeMul"),    Tx.ApertureSizeMul);
	if (Tx.TexGlow)     { MID->SetTextureParameterValue(TEXT("TexGlow"),     Tx.TexGlow); }
	if (Tx.TexStreak)   { MID->SetTextureParameterValue(TEXT("TexStreak"),   Tx.TexStreak); }
	if (Tx.TexRing)     { MID->SetTextureParameterValue(TEXT("TexRing"),     Tx.TexRing); }
	if (Tx.TexGhost)    { MID->SetTextureParameterValue(TEXT("TexGhost"),    Tx.TexGhost); }
	if (Tx.TexAperture) { MID->SetTextureParameterValue(TEXT("TexAperture"), Tx.TexAperture); }
}
