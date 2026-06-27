# Real-Time Rendering Shader Showcase (Unity URP)

手写 HLSL Shader 复刻游戏中高频出现的实时渲染效果，覆盖**水体、毛发、植被、半透明、湿地面、体积雾与屏幕后处理**等主流方向，体现对渲染管线与美术表现的理解与落地能力。

- **引擎 / 管线**：Unity **2022.3.62f3** + **URP 14.0.12**
- **打开方式**：用 Unity Hub 以上述版本打开本文件夹根目录（包含 `Assets / Packages / ProjectSettings` 的完整工程），首次打开 Unity 会自动还原 URP 包并编译。
- **导入到空白工程**：因为 Shader 使用了绝对路径 `#include "Assets/Resource/Shader/Shaderlibrary/..."`，若要导入到别的工程，请**整体复制 `Assets/Resource` 文件夹**（保持该路径不变），HLSL 库引用才不会断。

---

## 效果一览（对应简历）

| # | 效果 | 关键文件 | 技术点 |
|---|------|----------|--------|
| 1 | **水面渲染** | `Assets/Resource/Shader/Shader/WATER/Water1.shader`、`Water2.shader`、`Water1_GentleShoreWake.shader`、`PlanarReflectionManager.cs`、`Shaderlibrary/CustomBRDF_Water.hlsl` | FlowMap + 自定义 BRDF，反射 / 折射 / Depth Fade / 散射 / 近岸泡沫 |
| 2 | **程序化鱼群 (Boids)** | `Assets/Resource/Shader/Shader/WATER/FishFlock/` (`FishFlockManager.cs`、`FishFlockAgent.cs`、`FishFlockBounds.cs`、`ProceduralSimpleFishMesh.cs`) | Boids 算法实现可避障的鱼群 FishFlock |
| 3 | **角色毛发 (Shell Fur)** | `Assets/Resource/Script/Fur/` (`Fur.shader`、`Fur_My.shader`、`FurGenerator.cs`、`MultiFur.cs`、`FurInstanced.cs`、`PhysicalSim/`) | Shell Fur 多 Pass，可调卷曲度的毛绒，《王者荣耀》风格发丝 |
| 4 | **透明冰块 / 冰川** | `Assets/Resource/Shader/Shader/Ice/` (`Ice_Transparent.shader`、`A_Ice_My.shader`、`Ice2.shader` 等) | Parallax + Subsurface Scattering + 反射，模拟厚度内散射 |
| 5 | **植被渲染** | `Assets/Resource/Shader/Shader/Tree/Tree.shader`、`M_Foliage_Lit.mat` | Alpha 透贴 + 双面渲染 + 植被 BRDF + 间接光 |
| 6 | **屏幕空间体积雾** | `Assets/Resource/Shader/Shader/VolumeFog/RaymarchingFog.shader` + `Assets/Resource/Script/Fog/` (`FogFeature.cs`、`FogPass.cs`、`ExponentialHeightFog.shader`、`HeightFog.shader`) | Ray-marching 体积雾 + 指数高度雾，URP ScriptableRendererFeature |
| 7 | **传送门可见性测试** | `Assets/Resource/Shader/Shader/Chuansongmen/` (`PortalMask.shader`、`PortalRimGlow.shader`、`PortalSurfaceGlitch.shader`、`PortalTunnelGlitch.shader`) | 传送门遮罩 / 可见性测试与边缘辉光、面 glitch |
| 8 | **湿地面 / 雨夜街道** ⚠️ | `Assets/RainWetGround_BuiltInRP/` (`RainDrop.shader`、`RainDrop.mat`) | FlipBook 雨滴涟漪法线叠加 + 积水法线混合，模拟雨夜地面反射 |

### 附带（练习与基础）
- **HLSL 库** `Assets/Resource/Shader/Shaderlibrary/`：`CustomBRDF.hlsl`、`CustomBRDF_Water.hlsl`、`ShadingModels*.hlsl`、`LightingModel.hlsl`、`SurfaceData.hlsl`、`Fog.hlsl` —— 各效果共用的光照 / BRDF / 表面数据封装。
- **熔岩 Lava**、**大气散射天空盒 Skybox**（`Atmosphere.cginc`）、若干 Lit / Unlit 练习 Shader。

---

## ⚠️ 关于「湿地面 / 雨夜」(效果 8) 的说明
`RainDrop.shader` 是早期用 **Amplify Shader Editor** 生成的 **Built-in 管线表面着色器**（依赖 `UnityPBSLighting.cginc` 的 surface 结构）。在当前 URP 工程里它**能被识别但材质会显示为粉色**，因为 URP 不执行 surface shader 的光照路径。

要看到正确效果，二选一：
1. 新建一个 **Built-in 渲染管线** 工程，把 `RainWetGround_BuiltInRP` 文件夹拖进去；或
2. 将其移植为 URP 的 `vertex/fragment` 着色器（涟漪 FlipBook + 积水法线混合的核心逻辑可直接复用）。

> 其余 7 个效果均为标准 URP，在本工程内可直接编译渲染。

---

## 目录结构
```
ShaderPortfolio/
├─ Assets/
│  ├─ Resource/
│  │  ├─ Shader/
│  │  │  ├─ Shader/          # 各效果 Shader：WATER / Ice / Tree / VolumeFog / Chuansongmen / Lava / Skybox ...
│  │  │  └─ Shaderlibrary/   # 共用 HLSL 库（BRDF / 光照 / 表面数据）
│  │  ├─ Script/
│  │  │  ├─ Fur/             # Shell Fur 毛发（含 PhysicalSim 物理）
│  │  │  └─ Fog/             # 体积雾 / 高度雾 RendererFeature
│  │  ├─ Skybox/  CommonTexture/  Model/
│  ├─ RainWetGround_BuiltInRP/   # 雨夜湿地面（Built-in，见上方说明）
│  ├─ Settings/                  # URP Pipeline / Renderer 资产
│  └─ Scenes/
├─ Packages/         # 锁定 URP 14.0.12 等包版本
└─ ProjectSettings/  # 图形 / 质量 / 标签等工程设置
```
 
