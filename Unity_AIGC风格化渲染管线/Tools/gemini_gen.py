# -*- coding: utf-8 -*-
"""NanoBanana 白模渲染: whitemodel.png -> Google Gemini 图像模型 -> basecolor.png

用法: 把 Tools/ 放在 Unity 工程根目录, 在 Tools/ 下运行:
    uv run python gemini_gen.py [模型名]
默认模型 gemini-2.5-flash-image; NanoBanana Pro 用 gemini-3-pro-image-preview(需开通计费)。
提示词读同目录 banana_prompt.txt。需要能访问 Google 的网络环境。

API Key(本仓库不含任何 Key): 设置环境变量 GEMINI_API_KEY
  (去 aistudio.google.com/api-keys 免费创建; 图像模型需在结算页开通计费)
"""
import base64, json, os, sys, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = os.path.normpath(os.path.join(HERE, "..", "Assets", "AIGC_Output", "Disco"))
KEY = os.environ.get("GEMINI_API_KEY")
if not KEY:
    print("未找到 API Key: 请设置环境变量 GEMINI_API_KEY (aistudio.google.com/api-keys 创建)")
    sys.exit(1)

MODEL = sys.argv[1] if len(sys.argv) > 1 else "gemini-2.5-flash-image"

with open(os.path.join(HERE, "banana_prompt.txt"), "r", encoding="utf-8-sig") as f:
    prompt = f.read().strip()
with open(os.path.join(OUT_DIR, "whitemodel.png"), "rb") as f:
    src_b64 = base64.b64encode(f.read()).decode()

body = {
    "contents": [{"parts": [
        {"text": prompt},
        {"inline_data": {"mime_type": "image/png", "data": src_b64}},
    ]}],
    "generationConfig": {
        "responseModalities": ["TEXT", "IMAGE"],
        "imageConfig": {"aspectRatio": "16:9"},  # 必须和白模捕获宽高比一致, 否则投影错位
    },
}

url = "https://generativelanguage.googleapis.com/v1beta/models/" + MODEL + ":generateContent"
req = urllib.request.Request(url, data=json.dumps(body).encode("utf-8"),
    headers={"Content-Type": "application/json", "x-goog-api-key": KEY})

print("generating with %s ..." % MODEL)
with urllib.request.urlopen(req, timeout=300) as r:
    d = json.loads(r.read().decode("utf-8"))

img_b64 = None
for part in d.get("candidates", [{}])[0].get("content", {}).get("parts", []):
    inline = part.get("inlineData") or part.get("inline_data")
    if inline and inline.get("data"):
        img_b64 = inline["data"]
        break

if not img_b64:
    print("no image in response:", json.dumps(d)[:300])
    sys.exit(1)

out = os.path.join(OUT_DIR, "basecolor.png")
with open(out, "wb") as f:
    f.write(base64.b64decode(img_b64))
print("saved %s (%d bytes)" % (out, os.path.getsize(out)))
