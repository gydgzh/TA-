# AIGC 风格化渲染管线 — Unity 插件

AI 生图嵌入 Unity 实时渲染管线的独立插件。参考《极乐迪斯科》渲染架构：
**AI 只生成 BaseColor，深度 / 法线 / 光影 / 阴影全部由 URP 实时计算——画是画，光是光。**

## ⚠️ API Key 说明（重要）

**本仓库不包含任何 API Key。** 所有生图 / LLM 能力需要使用者配置自己的 Key：

| 用途 | 平台 | 获取方式 | 配置位置 |
|---|---|---|---|
| 生图(Seedream 4.5) | 火山方舟 | console.volcengine.com 开通, 按张计费约¥0.25 | Unity 组件 Inspector `apiKey` 字段; 命令行脚本用环境变量 `ARK_API_KEY` |
| 生图(NanoBanana) | Google AI Studio | aistudio.google.com/api-keys 免费创建, **图像模型需开通计费** | 同上 `apiKey`; 脚本用 `GEMINI_API_KEY`。需能访问 Google 的网络 |
| 免费文字画风(LLM) | Google AI Studio | 同上, 文本模型免费层即可 | 组件 `llmApiKey` 字段 |

Key 只存在本机（Inspector 序列化 / EditorPrefs / 环境变量），请勿将填了 Key 的场景文件提交到公开仓库。

## 功能一览

| 能力 | 说明 | 成本 |
|---|---|---|
| 画风面板(独立窗口) | Tools→AIGC→画风面板: 输入文字/参考图一键换画风 | — |
| 文字画风(免费NPR) | 任意画风描述 → 免费 LLM 解析成描边/色阶/雾/灯光参数 → 即时全屏变身 | 免费 |
| AI 重绘(原图/白模捕获) | 场景截图或白模 → AI 重新绘制 → 投影回 3D 模型 | 按张计费 |
| 极乐迪斯科管线 | 正交锁机位 → 导线稿/法线/深度 → AI 画 BaseColor → Lambert+实时阴影合成 | 按张计费 |
| 实时光支持 | 主方向光 + 附加点光/聚光在 AI 画面上实时染色、投影 | — |
| 动态物体 | `Dyn_` 前缀命名 = 不参与投影、被画面正确遮挡, 角色可自由行走 | — |
| 卡通水(可选) | 深浅双色/岸线泡沫/菲涅尔, 程序化噪声零贴图 | — |

## 安装

1. Unity 6 + URP 工程, 先装包 `com.unity.cloud.gltfast`
2. 导入 `AIGC_StylizeToolkit.unitypackage`
3. 场景物体挂 `RuntimeStyleSwitcher`(自动带 `AIGCProjection`), Inspector 填自己的 Key
4. 把 `Tools/` 文件夹放到工程根目录(命令行脚本, 供极乐迪斯科管线用)

## 快速使用

**运行时换画风**: Tools→AIGC→画风面板 → 输入画风 → `文字画风`(免费) 或 选捕获模式后 `生成并应用`(计费)。
组件上的 `showOverlayPanel` 勾选后, 打包的游戏内也会显示操作面板。

**极乐迪斯科管线**: Tools→AIGC→极乐迪斯科管线 → ①锁正交机位 → ②导出条件图 →
③保存画风设置后命令行跑 `Tools/disco_gen.py`(再跑 `pad_basecolor.py` 去毛边) → ④应用合成。

**白模渲染(NanoBanana)**: 面板选 `白模捕获` 直接生成; 或命令行 `Tools/gemini_gen.py`。

详细手册见包内 `Assets/AIGC/README_使用说明.md`(含排错速查表)。

## 技术点

- URP FullScreenPass RendererFeature 程序化装配(NPR 全屏风格化: 深度+法线 Sobel 描边/色阶/纸张色/颗粒)
- 相机投影映射: 捕获瞬间 VP 矩阵全局下发(SRP Batcher 兼容), 相机可动、投影锚定
- 自定义投影 Lit Shader: BaseColor 投影 × (Lambert + 主光实时阴影 + 附加光染色), 含 ShadowCaster/DepthOnly/DepthNormals pass
- 双后端 API 架构(Seedream / Gemini), 零依赖手拼 JSON, 支持中转平台地址
- 免费 LLM → NPR 参数字典(responseMimeType 强制纯 JSON, 含深色/纸面两类风格锚点示例)
- 原始材质序列化保护 + 预制体源兜底恢复; 生成期间保持上一渲染无缝切换
- 边缘外扩后处理(距离变换填充+高斯)消除投影轮廓毛边

## 参考

- 管线思路: [Unity中模拟《极乐迪斯科》渲染方式](https://zhuanlan.zhihu.com/p/642068361) (Danly)
- 演示角色: Quaternius Ultimate Animated Character Pack (CC0)
