#!/usr/bin/env python3
"""App Store screenshots for BibleAI: Scroll Scripture.
Real app captures inside a drawn iPhone 16 Pro Max / iPad Pro frame (no UI is redrawn),
warm paper background, serif headline. Usage: render_pro.py <captures dir> <out dir> [fonts dir]"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

CAP = Path(sys.argv[1]); OUT = Path(sys.argv[2])
FONTS = Path(sys.argv[3]) if len(sys.argv) > 3 else Path(__file__).resolve().parent / 'fonts'
INK, MUTED = (28, 26, 23), (110, 104, 96)
TOP, BOTTOM = (251, 248, 243), (236, 229, 216)

STORY = [
    ('reader', 'Scroll\nScripture.', 'The Bible, one verse at a time.'),
    ('study', 'Explore\nthe passage.', 'Study tools on Apple Intelligence devices.'),
    ('habit', 'Build a habit\nthat lasts.', 'Finish a reading. Watch your streak grow.'),
    ('plans', 'A little reading.\nEvery day.', 'Four guided plans. One clear next step.'),
    ('share', 'Share a verse\nyou love.', 'Send Scripture as a beautiful card.'),
    ('account', 'Your account.\nYour choice.', 'Optional Sign in with Apple. Delete anytime.'),
]
IPAD = STORY[:5] + [('invite', 'Read with\nsomeone.', 'Invite a friend to follow a plan with you.')]


def font(name, size, wght):
    f = ImageFont.truetype(str(FONTS / name), size)
    try:
        axes = f.get_variation_axes()
        f.set_variation_by_axes([wght if a['name'] in (b'Weight', 'Weight') else a['default'] for a in axes][:1] +
                                [a['default'] for a in axes][1:])
    except Exception:
        pass
    return f


def background(W, H):
    bg = Image.new('RGB', (W, H))
    d = ImageDraw.Draw(bg)
    for y in range(H):
        t = y / (H - 1)
        d.line([(0, y), (W, y)], fill=tuple(round(a + (b - a) * t) for a, b in zip(TOP, BOTTOM)))
    glow = Image.new('L', (W, H), 0)
    ImageDraw.Draw(glow).ellipse((W * .05, H * .30, W * .95, H * 1.05), fill=60)
    glow = glow.filter(ImageFilter.GaussianBlur(W * .12))
    return Image.composite(Image.new('RGB', (W, H), (255, 253, 249)), bg, glow)


def headline(c, head, sub, top, hsize, ssize):
    d = ImageDraw.Draw(c); W = c.width
    hf, sf = font('Newsreader.ttf', hsize, 460), font('Inter.ttf', ssize, 420)
    y = top
    for line in head.split('\n'):
        w = d.textlength(line, font=hf)
        assert w < W - 120, (line, w)
        d.text(((W - w) / 2, y), line, font=hf, fill=INK)
        y += round(hsize * 1.06)
    w = d.textlength(sub, font=sf)
    assert w < W - 120, (sub, w)
    d.text(((W - w) / 2, y + round(ssize * .55)), sub, font=sf, fill=MUTED)
    return y + round(ssize * 2.2)


def rounded_mask(size, r):
    m = Image.new('L', size, 0); ImageDraw.Draw(m).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), r, fill=255); return m


def shadow(c, box, r, blur, alpha, dy):
    s = Image.new('L', c.size, 0)
    x0, y0, x1, y1 = box
    ImageDraw.Draw(s).rounded_rectangle((x0 + blur * .2, y0 + dy, x1 - blur * .2, y1 + dy), r, fill=alpha)
    s = s.filter(ImageFilter.GaussianBlur(blur))
    c.paste(Image.new('RGB', c.size, (60, 48, 30)), (0, 0), s)


def iphone(c, shot, sw, x, y):
    """iPhone 16 Pro Max proportions: titanium band, black bezel, Dynamic Island, side buttons."""
    raw = Image.open(shot).convert('RGB')
    sh = round(raw.height * sw / raw.width)
    screen = raw.resize((sw, sh), Image.Resampling.LANCZOS)
    bez, band = round(sw * .030), round(sw * .013)
    sr = round(sw * .145); br = sr + bez; fr = br + band
    fw, fh = sw + 2 * (bez + band), sh + 2 * (bez + band)
    d = ImageDraw.Draw(c)
    shadow(c, (x, y, x + fw, y + fh), fr, sw * .06, 120, sw * .045)
    shadow(c, (x, y, x + fw, y + fh), fr, sw * .015, 70, sw * .01)
    # side buttons (behind the band so only their edge shows)
    btn = (70, 70, 74); bw = round(band * 1.1)
    for (yy, hh) in [(.165, .045), (.235, .075), (.33, .075)]:
        d.rounded_rectangle((x - bw, y + fh * yy, x + band, y + fh * (yy + hh)), bw, fill=btn)
    for (yy, hh) in [(.25, .115), (.62, .06)]:
        d.rounded_rectangle((x + fw - band, y + fh * yy, x + fw + bw, y + fh * (yy + hh)), bw, fill=btn)
    # titanium band with a soft vertical sheen
    bandimg = Image.new('RGB', (fw, fh))
    bd = ImageDraw.Draw(bandimg)
    for i in range(fw):
        t = abs(i / (fw - 1) - .5) * 2
        v = round(92 - 40 * t ** 3)
        bd.line([(i, 0), (i, fh)], fill=(v, v - 1, v + 2))
    c.paste(bandimg, (x, y), rounded_mask((fw, fh), fr))
    d.rounded_rectangle((x + 1, y + 1, x + fw - 2, y + fh - 2), fr, outline=(150, 150, 155), width=max(1, band // 5))
    d.rounded_rectangle((x + band, y + band, x + fw - band - 1, y + fh - band - 1), br, fill=(6, 6, 7))
    c.paste(screen, (x + band + bez, y + band + bez), rounded_mask((sw, sh), sr))
    # Dynamic Island
    iw, ih = round(sw * .286), round(sw * .084)
    ix, iy = x + (fw - iw) // 2, y + band + bez + round(sw * .026)
    d.rounded_rectangle((ix, iy, ix + iw, iy + ih), ih // 2, fill=(0, 0, 0))
    return fw, fh


def ipad(c, shot, sw, x, y):
    """iPad Pro 13-inch proportions: thin even bezel, aluminum edge, front camera dot."""
    raw = Image.open(shot).convert('RGB')
    sh = round(raw.height * sw / raw.width)
    screen = raw.resize((sw, sh), Image.Resampling.LANCZOS)
    bez, band = round(sw * .032), round(sw * .007)
    sr = round(sw * .035); br = sr + bez; fr = br + band
    fw, fh = sw + 2 * (bez + band), sh + 2 * (bez + band)
    d = ImageDraw.Draw(c)
    shadow(c, (x, y, x + fw, y + fh), fr, sw * .05, 110, sw * .035)
    d.rounded_rectangle((x, y, x + fw, y + fh), fr, fill=(150, 150, 154))
    d.rounded_rectangle((x + band, y + band, x + fw - band - 1, y + fh - band - 1), br, fill=(8, 8, 9))
    c.paste(screen, (x + band + bez, y + band + bez), rounded_mask((sw, sh), sr))
    cr = max(4, round(bez * .14))
    cx, cy = x + fw // 2, y + band + bez // 2
    d.ellipse((cx - cr, cy - cr, cx + cr, cy + cr), fill=(28, 30, 36))
    return fw, fh


SPECS = {  # canvas, headline size, sub size, text top, screen width, device kind, folder, prefix
    'iphone': ((1320, 2868), 128, 46, 150, 960, iphone, 'screenshots-6.9', 'BibleAI-6.9'),
    'medium': ((1206, 2622), 117, 42, 137, 877, iphone, 'screenshots-6.3', 'BibleAI-6.3'),
    'ipad': ((2064, 2752), 132, 50, 110, 1460, ipad, 'screenshots-ipad-13', 'BibleAI-ipad13'),
}


def render(kind, only=None):
    (W, H), hs, ss, top, sw, dev, folder, prefix = SPECS[kind]
    rows = IPAD if kind == 'ipad' else STORY
    out = OUT / folder; out.mkdir(parents=True, exist_ok=True)
    paths = []
    for i, (name, head, sub) in enumerate(rows, 1):
        if only and i not in only: continue
        c = background(W, H)
        y = headline(c, head, sub, top, hs, ss)
        src = CAP / ('ipad' if kind == 'ipad' else 'iphone') / f'{name}.png'
        probe = Image.open(src)
        bez = .043 if dev is iphone else .039
        fw = round(sw * (1 + 2 * bez)); fh = round(probe.height * sw / probe.width + sw * 2 * bez)
        dy = H - fh - round(H * .035)
        dy = max(y + round(H * .015), min(dy, y + round(H * .03)))
        assert dy + fh <= H - 20, (kind, i, dy + fh, H)
        dev(c, src, sw, (W - fw) // 2, dy)
        p = out / f'{prefix}-{i}.png'; c.save(p); paths.append(p)
    return paths


if __name__ == '__main__':
    kinds = sys.argv[4].split(',') if len(sys.argv) > 4 else ['iphone', 'medium', 'ipad']
    allp = []
    for k in kinds: allp += render(k)
    print('\n'.join(map(str, allp)))
