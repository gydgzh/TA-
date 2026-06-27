#pragma once

#include "CoreMinimal.h"
#include "MLensFlareTypes.generated.h"

/** 全局控制：总强度 / 亮度阈值 / 屏幕边缘衰减 */
USTRUCT(BlueprintType)
struct FMLFGlobalSettings
{
	GENERATED_BODY()

	/** 整套 Lens Flare 的总强度倍率 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Global", meta = (ClampMin = "0.0", UIMax = "4.0"))
	float GlobalIntensity = 1.0f;

	/** 亮度阈值下限：场景 HDR 亮度超过该值的像素才会产生 Flare */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Global", meta = (ClampMin = "0.0", UIMax = "20.0"))
	float Threshold = 2.0f;

	/** 软阈值过渡宽度：0 = 硬切, 越大过渡越柔和 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Global", meta = (ClampMin = "0.01", UIMax = "5.0"))
	float SoftKnee = 1.0f;

	/** 高亮提取后的模糊半径（像素），决定光斑柔和程度 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Global", meta = (ClampMin = "0.0", UIMax = "8.0"))
	float BlurRadius = 2.0f;

	/** 整体色调（乘在最终 Flare 结果上） */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Global")
	FLinearColor GlobalTint = FLinearColor::White;

	/** 屏幕边缘衰减起始位置（0=中心, 1=边缘） */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Global", meta = (ClampMin = "0.0", ClampMax = "1.0"))
	float EdgeFadeStart = 0.65f;

	/** 屏幕边缘衰减曲线强度 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Global", meta = (ClampMin = "0.1", UIMax = "8.0"))
	float EdgeFadePower = 2.0f;
};

/** Ghost 鬼影：沿“光源→屏幕中心”连线分布的多个镜片内反射光斑 */
USTRUCT(BlueprintType)
struct FMLFGhostSettings
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Ghost")
	bool bEnabled = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Ghost", meta = (ClampMin = "0.0", UIMax = "4.0", EditCondition = "bEnabled"))
	float Intensity = 1.0f;

	/** 鬼影数量 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Ghost", meta = (ClampMin = "1", ClampMax = "8", EditCondition = "bEnabled"))
	int32 Count = 6;

	/** 鬼影间距（沿中心连线的步长，负值反向） */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Ghost", meta = (UIMin = "-1.0", UIMax = "1.0", EditCondition = "bEnabled"))
	float Spacing = 0.32f;

	/** 离屏幕中心越远衰减越快的指数 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Ghost", meta = (ClampMin = "0.1", UIMax = "16.0", EditCondition = "bEnabled"))
	float FadePower = 6.0f;

	/** 每个鬼影的色散强度（RGB 通道错位采样） */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Ghost", meta = (ClampMin = "0.0", UIMax = "0.05", EditCondition = "bEnabled"))
	float ChromaticAberration = 0.01f;

	/** 是否启用光谱渐变染色（每个鬼影按彩虹梯度变化颜色） */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Ghost", meta = (EditCondition = "bEnabled"))
	bool bSpectrumColor = true;

	/** 光谱染色饱和度 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Ghost", meta = (ClampMin = "0.0", ClampMax = "1.0", EditCondition = "bEnabled && bSpectrumColor"))
	float SpectrumSaturation = 0.6f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Ghost", meta = (EditCondition = "bEnabled"))
	FLinearColor Tint = FLinearColor::White;
};

/** Halo 光晕：围绕屏幕中心的环状彩色光环 */
USTRUCT(BlueprintType)
struct FMLFHaloSettings
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Halo")
	bool bEnabled = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Halo", meta = (ClampMin = "0.0", UIMax = "4.0", EditCondition = "bEnabled"))
	float Intensity = 1.0f;

	/** 光环半径（UV 空间） */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Halo", meta = (ClampMin = "0.05", UIMax = "0.8", EditCondition = "bEnabled"))
	float Radius = 0.45f;

	/** 光环厚度衰减 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Halo", meta = (ClampMin = "0.1", UIMax = "32.0", EditCondition = "bEnabled"))
	float FalloffPower = 8.0f;

	/** 光环色散强度 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Halo", meta = (ClampMin = "0.0", UIMax = "0.08", EditCondition = "bEnabled"))
	float ChromaticAberration = 0.02f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Halo", meta = (EditCondition = "bEnabled"))
	FLinearColor Tint = FLinearColor(0.7f, 0.8f, 1.0f);
};

/** Anamorphic Streak 横向条纹：变形宽银幕镜头的水平拉丝 */
USTRUCT(BlueprintType)
struct FMLFStreakSettings
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Streak")
	bool bEnabled = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Streak", meta = (ClampMin = "0.0", UIMax = "4.0", EditCondition = "bEnabled"))
	float Intensity = 1.0f;

	/** 拉丝长度（占屏幕宽度比例） */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Streak", meta = (ClampMin = "0.01", UIMax = "1.0", EditCondition = "bEnabled"))
	float Length = 0.35f;

	/** 拉丝中心向两端的衰减指数 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Streak", meta = (ClampMin = "0.1", UIMax = "8.0", EditCondition = "bEnabled"))
	float FalloffPower = 2.0f;

	/** 垂直压扁程度：越大条纹越细 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Streak", meta = (ClampMin = "1.0", UIMax = "16.0", EditCondition = "bEnabled"))
	float VerticalSquash = 4.0f;

	/** 经典蓝色变形镜头色调 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Streak", meta = (EditCondition = "bEnabled"))
	FLinearColor Tint = FLinearColor(0.25f, 0.45f, 1.0f);
};

/** Iris / Aperture 光圈光斑：光圈叶片形成的多边形光斑 */
USTRUCT(BlueprintType)
struct FMLFIrisSettings
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Iris")
	bool bEnabled = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Iris", meta = (ClampMin = "0.0", UIMax = "4.0", EditCondition = "bEnabled"))
	float Intensity = 0.8f;

	/** 光圈叶片数（决定多边形边数） */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Iris", meta = (ClampMin = "3", ClampMax = "12", EditCondition = "bEnabled"))
	int32 BladeCount = 6;

	/** 多边形光斑大小 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Iris", meta = (ClampMin = "0.01", UIMax = "0.5", EditCondition = "bEnabled"))
	float Scale = 0.12f;

	/** 光斑沿中心连线的位置偏移 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Iris", meta = (UIMin = "-1.5", UIMax = "1.5", EditCondition = "bEnabled"))
	float Offset = -0.6f;

	/** 多边形旋转角度（度） */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Iris", meta = (UIMin = "0.0", UIMax = "360.0", EditCondition = "bEnabled"))
	float Rotation = 15.0f;

	/** 多边形边缘软硬 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Iris", meta = (ClampMin = "0.001", UIMax = "0.2", EditCondition = "bEnabled"))
	float EdgeSoftness = 0.03f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Iris", meta = (EditCondition = "bEnabled"))
	FLinearColor Tint = FLinearColor(1.0f, 0.85f, 0.6f);
};

/** Starburst 星芒：强光源的放射状光线 */
USTRUCT(BlueprintType)
struct FMLFStarburstSettings
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Starburst")
	bool bEnabled = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Starburst", meta = (ClampMin = "0.0", UIMax = "4.0", EditCondition = "bEnabled"))
	float Intensity = 1.0f;

	/** 星芒光线条数 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Starburst", meta = (ClampMin = "2", ClampMax = "16", EditCondition = "bEnabled"))
	int32 RayCount = 6;

	/** 光线长度（UV 空间） */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Starburst", meta = (ClampMin = "0.01", UIMax = "0.6", EditCondition = "bEnabled"))
	float RayLength = 0.18f;

	/** 星芒整体旋转角度（度） */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Starburst", meta = (UIMin = "0.0", UIMax = "360.0", EditCondition = "bEnabled"))
	float Rotation = 0.0f;

	/** 随相机旋转：相机转动时星芒微转，增强真实感、避免“贴纸感” */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Starburst", meta = (EditCondition = "bEnabled"))
	bool bRotateWithCamera = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Starburst", meta = (EditCondition = "bEnabled"))
	FLinearColor Tint = FLinearColor(1.0f, 0.95f, 0.85f);
};

/** Lens Dirt 镜头污渍：高亮处浮现的镜片灰尘/划痕 */
USTRUCT(BlueprintType)
struct FMLFLensDirtSettings
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "LensDirt")
	bool bEnabled = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "LensDirt", meta = (ClampMin = "0.0", UIMax = "4.0", EditCondition = "bEnabled"))
	float Intensity = 1.0f;

	/** 污渍贴图（全屏 overlay，被 Flare 亮度调制） */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "LensDirt", meta = (EditCondition = "bEnabled"))
	TObjectPtr<UTexture2D> DirtTexture = nullptr;
};

/**
 * 贴图驱动层：用外部 LensFlareVFX 贴图素材合成 hero flare
 * （辉光 / 横向拉丝 / 环形鬼影 / 鬼影串 / 多边形光圈），样式可换贴图，每子层独立开关。
 * 与程序化六层在 M_LF_FlareGen 材质内相加；以 SourceUV(光源屏幕坐标) 为锚沿向屏幕中心布置。
 */
USTRUCT(BlueprintType)
struct FMLFTexStyleSettings
{
	GENERATED_BODY()

	/** 贴图层总开关 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "TexStyle")
	bool bEnabled = true;

	/** 贴图层总强度 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "TexStyle", meta = (ClampMin = "0.0", UIMax = "8.0", EditCondition = "bEnabled"))
	float Intensity = 5.0f;

	/** 光源屏幕坐标 UV(0..1)：贴图 flare 以此为锚，沿 光源→屏幕中心 轴线分布 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "TexStyle", meta = (EditCondition = "bEnabled"))
	FVector2D SourceUV = FVector2D(0.5f, 0.5f);

	/** 整体缩放 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "TexStyle", meta = (ClampMin = "0.1", UIMax = "3.0", EditCondition = "bEnabled"))
	float GlobalScale = 1.0f;

	/** 色散（彩虹边）强度 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "TexStyle", meta = (ClampMin = "0.0", UIMax = "0.3", EditCondition = "bEnabled"))
	float ChromaShift = 0.10f;

	/** 鬼影 / 多边形串数量 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "TexStyle", meta = (ClampMin = "1", ClampMax = "8", EditCondition = "bEnabled"))
	int32 GhostCount = 7;

	/** 鬼影串沿轴间距 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "TexStyle", meta = (UIMin = "-0.5", UIMax = "0.5", EditCondition = "bEnabled"))
	float GhostSpacing = 0.0f;

	// ---- 辉光 (LightLeak) ----
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "TexStyle|1 Glow", meta = (EditCondition = "bEnabled"))
	bool bGlow = true;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "TexStyle|1 Glow", meta = (ClampMin = "0.0", UIMax = "4.0", EditCondition = "bEnabled && bGlow"))
	float GlowIntensity = 1.1f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "TexStyle|1 Glow", meta = (ClampMin = "0.01", UIMax = "0.5", EditCondition = "bEnabled && bGlow"))
	float GlowSize = 0.09f;

	// ---- 横向拉丝 (Streak) ----
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "TexStyle|2 Streak", meta = (EditCondition = "bEnabled"))
	bool bStreak = true;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "TexStyle|2 Streak", meta = (ClampMin = "0.0", UIMax = "4.0", EditCondition = "bEnabled && bStreak"))
	float StreakIntensity = 0.75f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "TexStyle|2 Streak", meta = (ClampMin = "0.05", UIMax = "1.0", EditCondition = "bEnabled && bStreak"))
	float StreakLength = 0.55f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "TexStyle|2 Streak", meta = (ClampMin = "0.005", UIMax = "0.2", EditCondition = "bEnabled && bStreak"))
	float StreakThick = 0.02f;

	// ---- 环形鬼影 (MultiGhostCentre) ----
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "TexStyle|3 Ring", meta = (EditCondition = "bEnabled"))
	bool bRing = true;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "TexStyle|3 Ring", meta = (ClampMin = "0.0", UIMax = "4.0", EditCondition = "bEnabled && bRing"))
	float RingIntensity = 0.30f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "TexStyle|3 Ring", meta = (ClampMin = "0.02", UIMax = "0.6", EditCondition = "bEnabled && bRing"))
	float RingSize = 0.13f;

	// ---- 鬼影串小光斑 (MultiGhost) ----
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "TexStyle|4 Ghost", meta = (EditCondition = "bEnabled"))
	bool bGhost = true;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "TexStyle|4 Ghost", meta = (ClampMin = "0.0", UIMax = "4.0", EditCondition = "bEnabled && bGhost"))
	float GhostIntensity = 1.0f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "TexStyle|4 Ghost", meta = (ClampMin = "0.2", UIMax = "3.0", EditCondition = "bEnabled && bGhost"))
	float GhostSizeMul = 1.0f;

	// ---- 多边形光圈 (ApertureShape) ----
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "TexStyle|5 Aperture", meta = (EditCondition = "bEnabled"))
	bool bAperture = true;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "TexStyle|5 Aperture", meta = (ClampMin = "0.0", UIMax = "4.0", EditCondition = "bEnabled && bAperture"))
	float ApertureIntensity = 0.8f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "TexStyle|5 Aperture", meta = (ClampMin = "0.2", UIMax = "3.0", EditCondition = "bEnabled && bAperture"))
	float ApertureSizeMul = 1.0f;

	// ---- 5 个可替换贴图槽 ----
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "TexStyle|Textures", meta = (EditCondition = "bEnabled"))
	TObjectPtr<UTexture2D> TexGlow = nullptr;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "TexStyle|Textures", meta = (EditCondition = "bEnabled"))
	TObjectPtr<UTexture2D> TexStreak = nullptr;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "TexStyle|Textures", meta = (EditCondition = "bEnabled"))
	TObjectPtr<UTexture2D> TexRing = nullptr;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "TexStyle|Textures", meta = (EditCondition = "bEnabled"))
	TObjectPtr<UTexture2D> TexGhost = nullptr;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "TexStyle|Textures", meta = (EditCondition = "bEnabled"))
	TObjectPtr<UTexture2D> TexAperture = nullptr;
};
