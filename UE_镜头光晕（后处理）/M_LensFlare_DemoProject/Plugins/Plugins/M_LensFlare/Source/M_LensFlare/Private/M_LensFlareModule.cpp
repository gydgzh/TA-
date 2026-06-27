#include "Modules/ModuleManager.h"
#include "Interfaces/IPluginManager.h"
#include "Misc/Paths.h"
#include "ShaderCore.h"

class FM_LensFlareModule : public IModuleInterface
{
public:
	virtual void StartupModule() override
	{
		// 把插件的 Shaders 目录映射为虚拟路径，
		// 材质 Custom 节点即可 #include "/Plugin/M_LensFlare/MLensFlare.ush"
		const TSharedPtr<IPlugin> Plugin = IPluginManager::Get().FindPlugin(TEXT("M_LensFlare"));
		if (Plugin.IsValid())
		{
			const FString ShaderDir = FPaths::Combine(Plugin->GetBaseDir(), TEXT("Shaders"));
			AddShaderSourceDirectoryMapping(TEXT("/Plugin/M_LensFlare"), ShaderDir);
		}
	}
};

IMPLEMENT_MODULE(FM_LensFlareModule, M_LensFlare)
