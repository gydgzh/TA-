# M_LensFlare — 基于亮度阈值的多层 Lens Flare 插件

## 1. 引擎版本

- 开发与测试环境:Unreal Engine 5.8(项目 `EngineAssociation: 5.8`)
- 题目目标版本:UE 5.7 —— 插件未使用 5.8 独有 API,理论上兼容 5.7 

## 2. 使用与集成方式

1. 将 `M_LensFlare` 整个文件夹拷贝到目标工程的 `Plugins/` 目录
2. 启动编辑器,在 Edit → Plugins 中确认 **M_LensFlare** 已启用(项目内插件默认启用)
3. 在场景中放置 **MLensFlareActor**(Place Actors 面板搜索),它自带全局无界 PostProcess
4. 在 Actor 的 Details → Lens Flare → **Preset** 指定一个 `MLensFlarePreset` 数据资产
   (插件自带 `Content/Data/PS_Cinematic`,可右键 → Miscellaneous → Data Asset → MLensFlarePreset 新建)
5. 打开 Preset 资产即可实时调参(默认每帧自动同步,无需手动应用)

**资产说明**:自研后处理管线(下方第 4 节)零第三方依赖,插件文件夹内不含任何第三方资产文件。
另提供一个**可选的「贴图驱动合成层」**(第 4 节末),它引用工程 `Content/LensFlareVFX` 贴图素材包的
若干贴图(按路径引用,**不打包进插件**);如目标工程没有该素材包,程序化管线仍完整工作,贴图层
只需在材质实例里换上任意 flare 贴图即可。详见第 6 节资产声明。

## 3. 参数说明(MLensFlarePreset)

| 分组 | 参数 | 说明 |
|---|---|---|
| 1. Global | GlobalIntensity | 整套效果总强度倍率 |
| | Threshold / SoftKnee | 亮度阈值下限 / 软过渡宽度(屏幕空间高亮提取) |
| | BlurRadius | 高亮提取后的模糊半径 |
| | GlobalTint / EdgeFadeStart / EdgeFadePower | 整体色调 / 屏幕边缘衰减 |
| 2. Ghost | Count / Spacing / FadePower / CA / SpectrumColor | 沿光源→屏幕中心连线分布的镜片反射光斑 |
| 3. Halo | Radius / FalloffPower / CA / Tint | 环状光晕(带色散彩边) |
| 4. Anamorphic Streak | Length / FalloffPower / VerticalSquash / Tint | 变形宽银幕水平拉丝 |
| 5. Iris | BladeCount / Scale / Offset / Rotation / EdgeSoftness | 光圈叶片多边形光斑 |
| 6. Starburst | RayCount / RayLength / Rotation / RotateWithCamera | 放射状星芒 |
| 7. Lens Dirt | DirtTexture / Intensity | 镜头污渍(可选) |

每层均有独立 `bEnabled` 开关与 `Intensity` / `Tint`。
色散(Chromatic Aberration)作为 Ghost / Halo 层的子参数实现。

## 4. 实现方式说明

### 框架部分(自研,C++ / 后处理材质管线)
- 屏幕空间亮度阈值检测(Threshold + SoftKnee,曝光无关:用 EyeAdaptation 换算到
  显示线性空间再判定,天然支持**任意数量高亮源**,非仅太阳)
- 管线编排:Threshold → BlurH/BlurV(密集可分离高斯)→ FlareGen → Composite
- 参数系统:`UMLensFlarePreset` DataAsset + `AMLensFlareActor` 每帧参数推送

### 各 Flare 层算法来源(声明:复刻自 Cinematic Lens Flares V4)
本插件定位为"**在 Cinematic Lens Flares(商城资产包)基础上的改动版**"。
其材质 Custom 节点 HLSL 已被提取分析,以下层的核心算法逐条复刻自该实现
(采样规模按全分辨率后处理等比缩减,参数槽映射到本插件的 Preset 结构):

| 层 | 复刻的 CLF 机制 |
|---|---|
| Ghost | 反转 UV 镜像布点 / 双链分布 / 环形散景(随序号增大)/ 余弦调色板色散 / 径向缩放 CA / 逐鬼影随机明暗 |
| Halo | 鱼眼镜像底图 / frac 环形遮罩 / 环形散景 / 单纯形噪声衍射散纹 |
| Iris(Glint Ring) | 光圈叶片整形环(rot2D 曲率隆起)/ frac 环形 warp / 逐角度调色板 |
| Starburst(Glints) | 放射拖尾采样 + 逐采样衍射调色 |
| Anamorphic Streak | 水平定向模糊 + 沿长度衍射渐变 |
| 公共函数 | 2D 单纯形噪声(源头 Ashima Arts webgl-noise,MIT)/ 鱼眼 UV 变换 |

另参考公开技术文章:John Chapman《Pseudo Lens Flare》、Froyok《Custom Lens Flare in UE》。

### 外部资产部分(声明)
  开发过程中曾参考商城资产包
  **Cinematic Lens Flares** 的材质 Custom 节点 HLSL 实现(算法逻辑层面),
  上表各层即据其公开实现思路自行编写;**该资产包的 Niagara / 蓝图 / 贴图等
  资产文件均未包含在最终插件中**。
 

### 卷积 Bloom 使用情况
- **整体光学辉光**使用引擎 Convolution Bloom(FFT):演示场景的 PostProcessVolume
  将 Bloom Method 设为 Convolution,核图像为引擎默认 `DefaultBloomKernel`,
  作用是给所有亮源叠加物理正确的衍射辉光打底(题目 Part 3 允许的用法)
- **六层 Flare 本体(Ghost / Halo / Streak / Iris / Starburst / CA)均不依赖卷积 Bloom**,
  全部由本插件的后处理材质管线生成;关闭 PPV 的卷积 Bloom 后六层效果完整保留

### 贴图驱动合成层(自研合成逻辑 + 外部贴图素材,可选)

程序化六层难以逼近「成品 stock flare」那种干净的多边形鬼影串 / 环形鬼影 / 彩虹散色,
因此在自研管线的 `M_LF_FlareGen` 材质里**额外**叠加了一个**贴图驱动合成层**
(独立 Custom 节点 + `Shaders/MLF_TexFlare.ush`,与程序化层 `Add` 相加,互不影响):

- **合成逻辑自研**:以「光源屏幕坐标 `SourceUV`」为锚,沿 `SourceUV→屏幕中心` 轴线
  叠加多枚「贴图精灵」——辉光 / 横向拉丝 / 环形鬼影 / 一串近端小光斑 + 远端大多边形;
  每枚精灵做 RGB 三通道径向错位采样产生**色散彩虹边**;按光源处亮度做门控(只有屏幕
  上确有高亮源时才显现)。
- **样式可替换**:5 个 `TextureObject` 参数(组 *LensFlare TexStyle*)——
  `TexGlow / TexStreak / TexRing / TexGhost / TexAperture`,美术在材质实例里换贴图即可
  改变每一层的样式;另有 `Intensity / GhostCount / GhostSpacing / ChromaShift / GlobalScale / SourceUV`
  标量/向量参数微调。
- **默认贴图**取自工程 `Content/LensFlareVFX` 素材包(见第 6 节):
  辉光 `T_LightLeak_07`、横拉丝 `T_Streak_14`、环形鬼影 `T_MultiGhostCentre_01`、
  鬼影串 `T_MultiGhost_09`、多边形光圈 `T_ApertureShape_09`。
- **与程序化层的关系**:两层在 `M_LF_FlareGen` 内相加。预设 `PS_Cinematic` 为程序化多层
  暖调;预设 `PS_TexDemo` 关闭程序化 Ghost/Halo/Streak/Iris、仅留 Starburst,以突出贴图层。
- **开发备注(避坑)**:UE 编辑器对 `.ush` include 改动存在「缓存不重读」老问题——
  贴图层的**合成数值(精灵大小/强度/间距)直接内联在 Custom 节点的 Code 里**(改 Code 必触发
  重编),只把稳定不变的采样辅助函数 `MLF_TexSprite` 留在 `MLF_TexFlare.ush`。改 `.ush` 后
  若效果未更新,在 Custom 节点 Code 里改一个字符再编译即可强制重读。

### 演示场景(小彩色光源 / 暗背景)

本机为 128MB 集显,重场景(Beach/HongKong)显存超支会压暗后处理,故演示改用**轻量暗场景**:
基于 `L_Example_Map`,关闭定向光 / 天空大气 / 高度雾得到黑背景,放置一个小的 **Unlit 自发光球**
(材质 `M_LF_DemoSource`,可调颜色与亮度)作为彩色点光源,`PostProcessVolume` 设**手动曝光**
保证阈值稳定;`MLensFlareActor` + `PS_TexDemo` 即出图。`SourceUV` 设为光球的屏幕 UV
即可让贴图 flare 锚定到它(后续可由 C++ 把关键光源投影到屏幕自动驱动)。

## 5. AI 使用声明

本插件开发过程中使用了 AI 编程助手(Claude)辅助:代码/着色器编写、参数调试、
场景测试自动化与文档撰写。各层算法参考 Cinematic Lens Flares 的公开 HLSL 实现思路后自行编写,
另参考上述公开技术文章;最终插件不含任何第三方商业资产文件。

## 6. 外部资产 / 参考来源

- Cinematic Lens Flares(UE Marketplace 资产包)— 仅作算法参考,资产文件未包含在插件中
- **LensFlareVFX 贴图素材包**(工程 `Content/LensFlareVFX`)— 贴图驱动合成层使用其中
  `T_LightLeak_07 / T_Streak_14 / T_MultiGhostCentre_01 / T_MultiGhost_09 / T_ApertureShape_09`
  等贴图(按路径引用,**未复制进插件文件夹**)。该层为可选增强;若目标工程无此素材包,
  程序化管线照常工作,贴图层换上任意 flare 贴图即可。版权归原素材包作者,随工程一并提供。
- John Chapman — *Pseudo Lens Flare*(john-chapman-graphics.blogspot.com)
- Froyok — *Custom Lens Flare in UE*(froyok.fr/blog)
- 2D 单纯形噪声 — Ashima Arts / Stefan Gustavson webgl-noise(MIT)
- 演示场景使用项目内既有美术资产(HongKong 街道 / GameArcade 街机厅)

 
