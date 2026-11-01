#!/usr/bin/env python3
"""Looping App Store product-page header (21:9) and search-results (3:2) videos for BibleAI 2.0
(iOS 27 Creative Assets). Same method as StockAlarm's header-video/build.py: a paused timeline is
stepped frame by frame in Chromium and encoded with ffmpeg. The phone cycles through real 2.0
simulator captures with crossfades; no UI is redrawn.

  python3 build.py            -> product-page-header.mp4  (3840x1646)
  python3 build.py --search   -> search-results.mp4       (3840x2560)
"""
from pathlib import Path
import json, shutil, subprocess, sys
from playwright.sync_api import sync_playwright

HERE = Path(__file__).resolve().parent
RAW = HERE / 'raw'
FONTS = HERE / 'fonts'
SEARCH = '--search' in sys.argv
W, H, FPS, DUR = (3840, 2560, 30, 10.0) if SEARCH else (3840, 1646, 30, 10.0)
FRAMES = HERE / ('frames-search' if SEARCH else 'frames-header')

# Apple uses the 5 s frame as the poster, so the hero verse (John 3:16) sits at 5.0-7.5 s.
SCENES = [
    ('08', 'Swipe through the Bible, one verse at a time.'),
    ('13', 'Guided plans for every day.'),
    ('10', 'Every verse gets the whole screen.'),
    ('11', 'Tap any verse for a deep study.'),
]
HOLD, XF = 2.0, 0.5   # 4 x 2.5 s = 10 s loop

if SEARCH:
    L = dict(h1_left=360, h1_top=760, h1_w=1650, h1_size=168, sub_top=1240, sub_size=64, line2_h=90,
             foot_top=1560, phone_left=2240, phone_top=180, phone_w=1060, pad=34, radius=170, screen_r=136)
else:
    L = dict(h1_left=560, h1_top=470, h1_w=1500, h1_size=132, sub_top=880, sub_size=54, line2_h=76,
             foot_top=1130, phone_left=2280, phone_top=120, phone_w=680, pad=22, radius=110, screen_r=88)

CSS = f'''
@font-face{{font-family:Newsreader;src:url("{FONTS}/Newsreader.ttf")}}
@font-face{{font-family:Inter;src:url("{FONTS}/Inter.ttf")}}
*{{margin:0;padding:0;box-sizing:border-box}}
body{{position:relative;overflow:hidden;width:{W}px;height:{H}px;background:#FFFFFF;color:#111;
  font-family:Inter,"Helvetica Neue",Arial,sans-serif;-webkit-font-smoothing:antialiased}}
h1{{position:absolute;left:{L["h1_left"]}px;top:{L["h1_top"]}px;width:{L["h1_w"]}px;font-family:Newsreader,Georgia,serif;
  font-weight:400;font-size:{L["h1_size"]}px;letter-spacing:-.015em;line-height:1.04}}
.sub{{position:absolute;left:{L["h1_left"]+6}px;top:{L["sub_top"]}px;width:{L["h1_w"]}px;font-size:{L["sub_size"]}px;
  font-weight:450;color:#6B6B6B;line-height:1.3}}
.line2{{position:relative;height:{L["line2_h"]}px}}
.line2 span{{position:absolute;left:0;top:0;white-space:nowrap;opacity:0}}
.foot{{position:absolute;left:{L["h1_left"]+6}px;top:{L["foot_top"]}px;font-size:{int(L["sub_size"]*0.62)}px;color:#8A8A8A}}
.phone{{position:absolute;left:{L["phone_left"]}px;top:{L["phone_top"]}px;width:{L["phone_w"]}px;padding:{L["pad"]}px;
  border-radius:{L["radius"]}px;background:#0B0B0B;box-shadow:0 40px 90px -30px rgba(0,0,0,.35)}}
.screen{{position:relative;width:100%;aspect-ratio:1178/2556;border-radius:{L["screen_r"]}px;overflow:hidden;background:#fff}}
.screen img{{position:absolute;left:0;top:0;width:100%;height:auto;display:block;opacity:0}}
'''


def build_html():
    imgs = ''.join(f'<img id="s{i}" src="{RAW}/{name}.png">' for i, (name, _) in enumerate(SCENES))
    subs = ''.join(f'<span id="t{i}">{text}</span>' for i, (_, text) in enumerate(SCENES))
    js = '''
const N=%d,HOLD=%f,XF=%f,DUR=%f;
function ease(x){return x<0?0:x>1?1:x*x*(3-2*x)}
window.seek=function(t){
  for(let i=0;i<N;i++){
    const start=i*(HOLD+XF);
    const rel=((t-start)%%DUR+DUR)%%DUR;
    let a; if(rel<HOLD) a=1; else if(rel<HOLD+XF) a=1-ease((rel-HOLD)/XF); else a=0;
    const prev=((t-(start-XF))%%DUR+DUR)%%DUR;
    if(prev<XF) a=Math.max(a,ease(prev/XF));
    document.getElementById('s'+i).style.opacity=a;
    let c; if(rel<HOLD) c=1; else if(rel<HOLD+XF/2) c=1-ease((rel-HOLD)/(XF/2)); else c=0;
    if(prev>=XF/2 && prev<XF) c=Math.max(c,ease((prev-XF/2)/(XF/2)));
    const tx=document.getElementById('t'+i); tx.style.opacity=c; tx.style.transform='translateY('+((1-c)*10)+'px)';
  }
};
''' % (len(SCENES), HOLD, XF, DUR)
    return (f'<!doctype html><html><head><meta charset="utf-8"><style>{CSS}</style></head><body>'
            f'<h1>What if scrolling<br>fed your soul?</h1>'
            f'<div class="sub"><div class="line2">{subs}</div></div>'
            f'<div class="foot">BibleAI · King James Version</div>'
            f'<div class="phone"><div class="screen">{imgs}</div></div>'
            f'<script>{js}</script></body></html>')


def main():
    name = 'search-results' if SEARCH else 'product-page-header'
    page = HERE / (name + '.html')
    page.write_text(build_html())
    if FRAMES.exists():
        shutil.rmtree(FRAMES)
    FRAMES.mkdir()
    n = int(DUR * FPS)
    with sync_playwright() as p:
        b = p.chromium.launch()
        pg = b.new_page(viewport={'width': W, 'height': H}, device_scale_factor=1)
        pg.goto(page.as_uri())
        pg.wait_for_load_state('networkidle')
        pg.evaluate('document.fonts.ready')
        for f in range(n):
            pg.evaluate(f'seek({f / FPS})')
            pg.screenshot(path=str(FRAMES / f'{f:04d}.png'), clip={'x': 0, 'y': 0, 'width': W, 'height': H})
        b.close()
    out = HERE / (name + '.mp4')
    subprocess.run(['ffmpeg', '-y', '-v', 'error', '-framerate', str(FPS), '-i', str(FRAMES / '%04d.png'),
                    '-f', 'lavfi', '-i', 'anullsrc=channel_layout=stereo:sample_rate=48000',
                    '-c:v', 'libx264', '-profile:v', 'high', '-pix_fmt', 'yuv420p', '-crf', '17', '-preset', 'veryfast',
                    '-c:a', 'aac', '-b:a', '64k', '-shortest', '-movflags', '+faststart', str(out)], check=True)
    shutil.copy(FRAMES / f'{5 * FPS:04d}.png', HERE / (name + '-poster.png'))
    (HERE / (name + '-manifest.json')).write_text(json.dumps({
        'size': [W, H], 'fps': FPS, 'seconds': DUR, 'loop': True, 'audio': 'silent stereo AAC 48 kHz',
        'scenes': SCENES, 'hold_s': HOLD, 'crossfade_s': XF,
        'captures': 'BibleAI 2.0 simulator captures 2026-10-30 (release suite run 20261030T140422Z)',
        'poster': 'Apple selects the 5 s frame; scene at 5 s is John 3:16'}, indent=2) + '\n')
    shutil.rmtree(FRAMES)
    print('wrote', out)


if __name__ == '__main__':
    main()
