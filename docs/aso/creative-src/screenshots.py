"""App Store screenshots for BibleAI 2.0: white page, serif headline, real capture in a phone frame.
   python3 shots.py iphone  -> out/screenshots-6.9  (1320x2868)
   python3 shots.py ipad    -> out/screenshots-ipad-13 (2064x2752)"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont
HERE = Path(__file__).resolve().parent
def font(name, size, axes):
    f = ImageFont.truetype(str(HERE / 'fonts' / name), size)
    f.set_variation_by_axes(axes); return f
serif = lambda s: font('Newsreader.ttf', s, [72, 420])
sans = lambda s: font('Inter.ttf', s, [28, 450])
def rounded(im, r):
    m = Image.new('L', im.size, 0); ImageDraw.Draw(m).rounded_rectangle([0, 0, im.size[0]-1, im.size[1]-1], r, fill=255)
    out = Image.new('RGBA', im.size); out.paste(im, (0, 0), m); return out
def compose(src, head, sub, out, W, H, hsize, ssize, devw, frame_r, screen_r, pad, top0):
    c = Image.new('RGBA', (W, H), '#FFFFFF'); d = ImageDraw.Draw(c)
    hf, y = serif(hsize), top0
    for line in head.split('\n'):
        w = d.textlength(line, font=hf); d.text(((W-w)/2, y), line, font=hf, fill='#111111'); y += int(hsize*1.17)
    sf = sans(ssize); w = d.textlength(sub, font=sf); d.text(((W-w)/2, y+int(ssize*0.6)), sub, font=sf, fill='#6B6B6B')
    top = y + int(ssize*3.4)
    shot = Image.open(src).convert('RGB'); shot = shot.resize((devw, int(shot.height*devw/shot.width)), Image.LANCZOS)
    fw, fh = devw+2*pad, shot.height+2*pad
    frame = Image.new('RGBA', (fw, fh), (0, 0, 0, 0)); ImageDraw.Draw(frame).rounded_rectangle([0, 0, fw-1, fh-1], frame_r, fill='#0B0B0B')
    frame.alpha_composite(rounded(shot.convert('RGBA'), screen_r), (pad, pad))
    sh = Image.new('RGBA', (W, H), (0, 0, 0, 0)); ImageDraw.Draw(sh).rounded_rectangle([(W-fw)//2+10, top+30, (W+fw)//2-10, top+fh], frame_r, fill=(0, 0, 0, 40))
    c = Image.alpha_composite(c, sh.filter(ImageFilter.GaussianBlur(40))); c.alpha_composite(frame, ((W-fw)//2, top))
    c.convert('RGB').save(out)
IPHONE = [('10', 'What if scrolling\nfed your soul?', 'Swipe through the Bible, one verse at a time.'),
          ('11', 'Every verse has\na story', 'Tap any verse for a deep study, right on your iPhone.'),
          ('13', 'Read the whole Bible,\none day at a time', 'Guided plans that remember your progress.'),
          ('09', 'Keep the verses\nthat speak to you', 'Save, add a note and share in a tap.'),
          ('18', 'Watch your progress\ngrow', 'Check off each day of your reading plan.'),
          ('08', 'Pick up right\nwhere you left off', 'From Genesis to Revelation, all 66 books.')]
if sys.argv[1] == 'iphone':
    o = HERE / 'out/screenshots-6.9'; o.mkdir(parents=True, exist_ok=True)
    for n, (src, h, s) in enumerate(IPHONE, 1):
        compose(HERE/'raw'/f'{src}.png', h, s, o/f'BibleAI-6.9-{n}.png', 1320, 2868, 112, 42, 1000, 150, 122, 30, 190)
else:
    o = HERE / 'out/screenshots-ipad-13'; o.mkdir(parents=True, exist_ok=True)
    IPAD = [(f, h.replace('your iPhone', 'your iPad'), s.replace('your iPhone', 'your iPad')) for f, h, s in eval(sys.argv[2])]
    for n, (src, h, s) in enumerate(IPAD, 1):
        compose(HERE/'raw-ipad'/f'{src}.png', h, s, o/f'BibleAI-ipad13-{n}.png', 2064, 2752, 150, 54, 1480, 64, 40, 26, 170)
print('ok')
