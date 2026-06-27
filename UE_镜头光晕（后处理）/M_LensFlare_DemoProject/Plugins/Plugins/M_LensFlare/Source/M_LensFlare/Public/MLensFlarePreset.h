#pragma once

#include "CoreMinimal.h"
#include "Engine/DataAsset.h"
#include "MLensFlareTypes.h"
#include "MLensFlarePreset.generated.h"

/**
 * Lens Flare 预设资产。
 * 美术在 Content Browser 中创建（右键 → Miscellaneous → Data Asset → MLensFlarePreset），
 * 调整参数后赋给场景中的 AMLensFlareActor 即可生效。
 */
UCLASS(BlueprintType)
class M_LENSFLARE_API UMLensFlarePreset : public UPrimaryDataAsset
{
	GENERATED_BODY()

public:
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "1. Global")
	FMLFGlobalSettings Global;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "2. Ghost")
	FMLFGhostSettings Ghost;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "3. Halo")
	FMLFHaloSettings Halo;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "4. Anamorphic Streak")
	FMLFStreakSettings Streak;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "5. Iris")
	FMLFIrisSettings Iris;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "6. Starburst")
	FMLFStarburstSettings Starburst;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "7. Lens Dirt")
	FMLFLensDirtSettings LensDirt;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "8. Texture Style")
	FMLFTexStyleSettings TexStyle;
};
