#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_plugin_icons.py — 为单个插件生成图标三件套（icon.png / icon@2x.png / icon@3x.png）

用法（5 个参数）：
  python gen_plugin_icons.py 输出目录 中文名 top色 bottom色 图标类型
  python gen_plugin_icons.py ./myicons "我的手势" "#B07CF0" "#7A3FE0" gesture

图标类型（内置 12 种 glyph）：
  super / keyboard / notify / gesture / voice / privacy / game / cpu / temp / power / loc / bolt

想加新图标：在脚本底部 g_glyph() 里照着现有 glyph 画即可（ImageDraw.Draw mask）。
"""
import os, sys, math, argparse
from PIL import Image, ImageDraw, ImageFont

SS = 360            # 源图尺寸（3x 基础）
RR = int(0.2236 * SS)  # iOS squircle 圆角

GLYPH_FNS = {
    "super":   lambda d: (d.rounded_rectangle([100,115,260,250], radius=26, fill=255),
                          d.rounded_rectangle([118,133,242,232], radius=18, fill=0),
                          d.ellipse([198,150,228,180], fill=255),
                          d.polygon([(118,226),(162,182),(190,206),(220,172),(242,200),(242,232),(118,232)], fill=255)),
    "keyboard": lambda d: (d.rounded_rectangle([70,150,290,228], radius=16, fill=255),
                          [d.rounded_rectangle([x,ry,x+13,ry+13], radius=3, fill=0) for ry in (159,181) for x in range(84,277,20)],
                          d.rounded_rectangle([96,202,264,214], radius=6, fill=0),
                          d.rounded_rectangle([70,236,290,248], radius=6, fill=255),
                          d.ellipse([250,239,266,245], fill=0)),
    "notify":  lambda d: (d.rounded_rectangle([168,68,192,98], radius=8, fill=255),
                          d.pieslice([115,95,245,255], 180, 360, fill=255),
                          d.polygon([(115,170),(245,170),(222,232),(138,232)], fill=255),
                          d.ellipse([158,228,202,272], fill=255)),
    "gesture": lambda d: (d.ellipse([122,150,212,240], fill=255),
                          d.arc([86,100,256,270], 200, 340, width=14, fill=255),
                          d.arc([62,76,232,246], 200, 340, width=12, fill=255),
                          d.line([(250,118),(292,118)], width=10, fill=255),
                          d.line([(250,142),(286,142)], width=10, fill=255)),
    "voice":   lambda d: (d.rounded_rectangle([150,105,210,200], radius=30, fill=255),
                          d.arc([122,175,238,300], 200, 340, width=18, fill=255),
                          d.line([(180,255),(180,295)], width=16, fill=255),
                          d.line([(135,295),(225,295)], width=16, fill=255)),
    "privacy": lambda d: (d.polygon([(180,95),(268,135),(268,210),(180,292),(92,210),(92,135)], fill=255),
                          d.ellipse([160,162,200,202], fill=0),
                          d.rounded_rectangle([173,198,187,228], radius=3, fill=0)),
    "game":    lambda d: (d.rounded_rectangle([78,150,282,238], radius=44, fill=255),
                          d.rounded_rectangle([120,178,150,208], radius=4, fill=0),
                          d.rounded_rectangle([128,185,142,201], radius=4, fill=0),
                          d.ellipse([220,172,248,200], fill=0),
                          d.ellipse([248,196,276,224], fill=0)),
    "cpu":     lambda d: (d.rounded_rectangle([110,110,250,250], radius=18, fill=255),
                          [d.rounded_rectangle([x,98,x+16,112], radius=3, fill=255) for x in (135,160,185,210,235)],
                          [d.rounded_rectangle([x,248,x+16,262], radius=3, fill=255) for x in (135,160,185,210,235)],
                          [d.rounded_rectangle([98,y,112,y+16], radius=3, fill=255) for y in (135,160,185,210,235)],
                          [d.rounded_rectangle([248,y,262,y+16], radius=3, fill=255) for y in (135,160,185,210,235)],
                          d.rounded_rectangle([142,142,218,218], radius=10, fill=0)),
    "temp":    lambda d: (d.rounded_rectangle([162,100,198,235], radius=18, fill=255),
                          d.ellipse([148,210,212,274], fill=255),
                          d.rounded_rectangle([172,112,188,228], radius=8, fill=0),
                          d.ellipse([162,222,198,258], fill=0),
                          d.rounded_rectangle([172,165,188,228], radius=8, fill=255),
                          d.ellipse([162,222,198,258], fill=255)),
    "power":   lambda d: (d.rounded_rectangle([118,120,245,245], radius=22, fill=255),
                          d.rounded_rectangle([245,160,262,205], radius=6, fill=255),
                          d.rounded_rectangle([134,136,232,229], radius=12, fill=0),
                          d.polygon([(196,142),(160,200),(184,200),(172,242),(206,178),(182,178)], fill=255)),
    "loc":     lambda d: (d.ellipse([110,110,250,250], fill=255),
                          d.polygon([(110,140),(250,140),(180,300)], fill=255),
                          d.ellipse([150,150,210,210], fill=0),
                          d.ellipse([166,166,194,194], fill=255)),
    "bolt":    lambda d: (d.polygon([(200,80),(130,210),(185,210),(160,280),(230,150),(175,150)], fill=255)),
}

def lerp(a, b, t):
    return tuple(int(a[i] + (b[i]-a[i])*t) for i in range(3))

def hex2rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def make_icon(glyph_fn, top_rgb, bot_rgb):
    g = Image.new("RGB", (SS, SS))
    gd = ImageDraw.Draw(g)
    for y in range(SS):
        gd.line([(0,y),(SS,y)], fill=lerp(top_rgb, bot_rgb, y/SS))
    bg = g.convert("RGBA")
    cm = Image.new("L", (SS, SS), 0)
    ImageDraw.Draw(cm).rounded_rectangle([0, 0, SS, SS], radius=RR, fill=255)
    bg.putalpha(cm)
    m = Image.new("L", (SS, SS), 0)
    glyph_fn(ImageDraw.Draw(m))
    white = Image.new("RGBA", (SS, SS), (255,255,255,255))
    white.putalpha(m)
    bg.alpha_composite(white)
    return bg

def main():
    ap = argparse.ArgumentParser(description="生成插件图标三件套")
    ap.add_argument("outdir", help="输出目录（不存在会自动创建）")
    ap.add_argument("cnname", help="中文名（仅用于文件注释）")
    ap.add_argument("top", help="渐变顶色（#RRGGBB）")
    ap.add_argument("bot", help="渐变底色（#RRGGBB）")
    ap.add_argument("glyph", choices=sorted(GLYPH_FNS.keys()), help="glyph 类型")
    ap.add_argument("--beprefix", help="同时复制一份到 bundle 目录（layout/Library/PreferenceBundles/XXX.bundle/）")
    args = ap.parse_args()

    os.makedirs(args.outdir, exist_ok=True)
    img = make_icon(GLYPH_FNS[args.glyph], hex2rgb(args.top), hex2rgb(args.bot))
    sizes = [("icon.png", 60), ("icon@2x.png", 120), ("icon@3x.png", 180)]
    for fname, t in sizes:
        im = img.resize((t, t), Image.LANCZOS)
        im.save(os.path.join(args.outdir, fname))
    print(f"✅ {args.cnname} ({args.glyph}) 生成完毕 → {args.outdir}")

    if args.beprefix:
        bdir = args.beprefix
        os.makedirs(bdir, exist_ok=True)
        for fname, t in sizes:
            im = img.resize((t, t), Image.LANCZOS)
            im.save(os.path.join(bdir, fname))
        print(f"✅ 已同时放入 bundle 目录: {bdir}")

if __name__ == "__main__":
    main()
