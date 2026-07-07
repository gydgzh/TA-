# -*- coding: utf-8 -*-
"""BaseColor 边缘外扩(投影去毛边): 物体颜色向背景膨胀+背景强模糊。

生成 basecolor 后跑一次(Tools/ 放在 Unity 工程根目录):
    uv run --with scipy --with pillow --with numpy python pad_basecolor.py
原理: 轮廓边缘双线性采样会混入天空色 → 用 depth.png 当物体掩码,
背景区域填充最近物体色再高斯模糊, 消除白边且无条纹。
"""
import os, shutil
import numpy as np
from PIL import Image
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
D = os.path.normpath(os.path.join(HERE, "..", "Assets", "AIGC_Output", "Disco"))
src = os.path.join(D, "basecolor.png")

shutil.copy(src, os.path.join(D, "basecolor_raw.png"))  # 备份未处理版
base = np.array(Image.open(src).convert("RGB")).astype(np.float32)
depth = np.array(Image.open(os.path.join(D, "depth.png")).convert("L")
                 .resize((base.shape[1], base.shape[0]), Image.NEAREST))
obj = depth > 8
_, (iy, ix) = ndimage.distance_transform_edt(~obj, return_indices=True)
padded = base[iy, ix]
blurred = np.stack([ndimage.gaussian_filter(padded[:, :, c], sigma=10) for c in range(3)], axis=2)
out = np.where(obj[:, :, None], base, blurred)
Image.fromarray(out.clip(0, 255).astype(np.uint8)).save(src)
print("edge padding done (raw backup: basecolor_raw.png)")
