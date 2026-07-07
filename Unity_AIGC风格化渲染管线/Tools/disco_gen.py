# -*- coding: utf-8 -*-
"""极乐迪斯科管线·生成步骤: lineart.png -> Seedream 4.5 图生图 -> basecolor.png

用法: 把 Tools/ 放在 Unity 工程根目录, 在 Tools/ 下运行:
    uv run python disco_gen.py
风格描述读同目录 style.txt(UTF-8, 只写内容与固有色, 别写光影词)。

API Key(二选一, 本仓库不含任何 Key):
  1. 环境变量 ARK_API_KEY
  2. Windows 下曾在 Unity 插件窗口里保存过 Key(EditorPrefs), 脚本会自动读取
"""
import base64, json, os, sys, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = os.path.normpath(os.path.join(HERE, "..", "Assets", "AIGC_Output", "Disco"))


def get_key():
    k = os.environ.get("ARK_API_KEY")
    if k:
        return k
    try:
        import winreg
        reg = winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"Software\Unity Technologies\Unity Editor 5.x")
        i = 0
        while True:
            try:
                name, val, _ = winreg.EnumValue(reg, i)
            except OSError:
                break
            if name.startswith("AIGC_Key_Seedream"):
                return val.decode("utf-8").rstrip("\x00") if isinstance(val, bytes) else str(val)
            i += 1
    except Exception:
        pass
    return None


key = get_key()
if not key:
    print("未找到 API Key: 请设置环境变量 ARK_API_KEY, 或先在 Unity 插件窗口里保存火山方舟 Key")
    sys.exit(1)

style = u"油画厚涂风格, 暖色调复古怀旧氛围"
style_file = os.path.join(HERE, "style.txt")
if os.path.exists(style_file):
    with open(style_file, "r", encoding="utf-8-sig") as f:
        style = f.read().strip() or style

with open(os.path.join(OUT_DIR, "lineart.png"), "rb") as f:
    lineart_b64 = base64.b64encode(f.read()).decode()

FLAT_LIGHT = (u"重要: 画面必须是均匀漫射的平光照明(如阴天), 绝对不要绘制任何投影、阴影、地面光斑或强高光"
              u"——光影将由游戏引擎实时计算, 只画物体的固有色和材质细节")

# Tools 目录里放 style_ref.png 即启用双图模式(图1线稿定结构, 图2定画风)
ref_path = os.path.join(OUT_DIR, "style_ref.png")
images = ["data:image/png;base64," + lineart_b64]
if os.path.exists(ref_path):
    with open(ref_path, "rb") as f:
        images.append("data:image/png;base64," + base64.b64encode(f.read()).decode())
    prompt = (u"第一张图是游戏场景的线稿(结构约束), 第二张图是画风参考。" + FLAT_LIGHT +
              u"。严格按照第一张线稿的结构为场景上色: 所有物体轮廓位置必须与线稿完全一致, "
              u"不要增加、移除或移动任何物体。只模仿第二张参考图的色调、笔触和材质质感; "
              u"参考图里的光影、投影、发光光斑、内容物一律不要模仿——尤其不要画任何阴影。" +
              ((u"场景内容: " + style + u"。") if style else u""))
    print("mode: lineart + style reference")
else:
    prompt = (u"这是一张游戏场景的线稿图。严格按照线稿为画面上色, 生成" + style +
              u"的游戏场景美术图。所有物体轮廓位置必须与线稿完全一致, 不要增加、移除或移动任何物体, "
              u"线稿的黑线区域是物体轮廓, 白色区域按物体语义填充色彩与质感。" + FLAT_LIGHT)
    print("mode: lineart + text style")

body = json.dumps({
    "model": "doubao-seedream-4-5-251128",
    "prompt": prompt,
    "image": images if len(images) > 1 else images[0],
    "size": "2K",
    "response_format": "url",
    "watermark": False,
}).encode("utf-8")

req = urllib.request.Request(
    "https://ark.cn-beijing.volces.com/api/v3/images/generations",
    data=body,
    headers={"Content-Type": "application/json", "Authorization": "Bearer " + key})

print("generating...")
with urllib.request.urlopen(req, timeout=300) as r:
    d = json.loads(r.read().decode("utf-8"))

url = d["data"][0]["url"]
out = os.path.join(OUT_DIR, "basecolor.png")
for attempt in range(3):
    try:
        urllib.request.urlretrieve(url, out)
        break
    except Exception as e:
        print("download retry %d: %s" % (attempt + 1, repr(e)[:60]))
print("saved %s (%d bytes)" % (out, os.path.getsize(out)))
