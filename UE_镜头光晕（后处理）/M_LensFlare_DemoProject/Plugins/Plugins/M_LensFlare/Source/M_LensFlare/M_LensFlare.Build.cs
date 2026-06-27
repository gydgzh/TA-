using UnrealBuildTool;

public class M_LensFlare : ModuleRules
{
	public M_LensFlare(ReadOnlyTargetRules Target) : base(Target)
	{
		PCHUsage = ModuleRules.PCHUsageMode.UseExplicitOrSharedPCHs;

		PublicDependencyModuleNames.AddRange(new string[]
		{
			"Core",
			"CoreUObject",
			"Engine"
		});

		PrivateDependencyModuleNames.AddRange(new string[]
		{
			"Projects",     // IPluginManager
			"RenderCore"    // AddShaderSourceDirectoryMapping
		});
	}
}
