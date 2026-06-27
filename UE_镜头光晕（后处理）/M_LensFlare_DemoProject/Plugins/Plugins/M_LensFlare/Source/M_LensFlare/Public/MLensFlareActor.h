#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "MLensFlareTypes.h"
#include "MLensFlareActor.generated.h"

class UPostProcessComponent;
class UMaterialInterface;
class UMaterialInstanceDynamic;
class UMLensFlarePreset;

/**
 * Lens Flare 控制 Actor。
 * 拖入场景即可生效（全局无界后处理）。指定 Preset 资产后，
 * 每帧将参数推送给后处理材质管线（Threshold → Blur → FlareGen → Composite）。
 */
UCLASS(HideCategories = (Collision, Input, Replication, Networking, Physics))
class M_LENSFLARE_API AMLensFlareActor : public AActor
{
	GENERATED_BODY()

public:
	AMLensFlareActor();

	/** 当前使用的预设。可在编辑器中实时调整其参数 */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Lens Flare")
	TObjectPtr<UMLensFlarePreset> Preset;

	/** 编辑器/运行时每帧自动同步预设参数（关闭后需手动调用 Apply Preset） */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Lens Flare")
	bool bUpdateEveryFrame = true;

	/** 运行时切换预设（演示视频用） */
	UFUNCTION(BlueprintCallable, Category = "Lens Flare")
	void SetPreset(UMLensFlarePreset* InPreset);

	/** 立即把当前预设的所有参数推送给材质 */
	UFUNCTION(BlueprintCallable, Category = "Lens Flare")
	void ApplyPreset();

	// ---- 管线材质（默认指向插件 Content，一般无需修改） ----
	UPROPERTY(EditAnywhere, Category = "Lens Flare|Advanced", AdvancedDisplay)
	TSoftObjectPtr<UMaterialInterface> ThresholdMaterial;

	UPROPERTY(EditAnywhere, Category = "Lens Flare|Advanced", AdvancedDisplay)
	TSoftObjectPtr<UMaterialInterface> BlurHMaterial;

	UPROPERTY(EditAnywhere, Category = "Lens Flare|Advanced", AdvancedDisplay)
	TSoftObjectPtr<UMaterialInterface> BlurVMaterial;

	UPROPERTY(EditAnywhere, Category = "Lens Flare|Advanced", AdvancedDisplay)
	TSoftObjectPtr<UMaterialInterface> FlareGenMaterial;

	UPROPERTY(EditAnywhere, Category = "Lens Flare|Advanced", AdvancedDisplay)
	TSoftObjectPtr<UMaterialInterface> CompositeMaterial;

	virtual void OnConstruction(const FTransform& Transform) override;
	virtual void Tick(float DeltaSeconds) override;
	virtual bool ShouldTickIfViewportsOnly() const override { return true; }

protected:
	UPROPERTY(VisibleAnywhere, Category = "Lens Flare")
	TObjectPtr<UPostProcessComponent> PostProcess;

	UPROPERTY(Transient)
	TArray<TObjectPtr<UMaterialInstanceDynamic>> PipelineMIDs;

	/** 加载管线材质、创建 MID 并注册为 Blendable（按顺序） */
	void BuildPipeline();

	/** 把预设参数推给单个 MID（材质用不到的参数会被忽略） */
	void PushParams(UMaterialInstanceDynamic* MID) const;
};
