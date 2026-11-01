#!/usr/bin/env python3
"""Render BibleAI store art from retained real app captures. No Simulator or UI synthesis."""
from pathlib import Path
import json, sys
from PIL import Image, ImageDraw, ImageFont

HERE=Path(__file__).resolve().parent
ASO=HERE.parent
CAP=HERE/'captures'
SCRATCH=HERE.parents[2]/'build/aso-refresh'
SERIF=Path('/System/Library/Fonts/Supplemental/Georgia.ttf')
SANS=Path('/System/Library/Fonts/Supplemental/Arial.ttf')
INK='#171717'; MUTED='#666666'; BLUE='#007AFF'
STORY=[
 ('reader','Make room for\nScripture.','Read the Bible, one verse at a time.'),
 ('resume','Pick up where\nyou left off.','Your reading place is saved as you go.'),
 ('plans','A little reading.\nEvery day.','Four guided plans. One clear next step.'),
 ('saved','Keep what speaks\nto you.','Save a verse. Add your own reflection.'),
 ('progress','See how far\nyou\u2019ve come.','Mark a reading complete and keep going.'),
 ('study','Explore\nthe passage.','Study tools for supported Apple Intelligence devices.')
]

def font(size,serif=False): return ImageFont.truetype(str(SERIF if serif else SANS),size)
def text_lines(canvas,text,xy,size,serif=False,color=INK,center=False,gap=1.18):
 d=ImageDraw.Draw(canvas); x,y=xy; f=font(size,serif)
 for line in text.split('\n'):
  w=d.textlength(line,font=f)
  assert w <= canvas.width-100, (text,w,canvas.width)
  d.text(((canvas.width-w)/2 if center else x,y),line,font=f,fill=color,stroke_width=0)
  y += round(size*gap)
 return y

def device(canvas,source,width,x,y,pad,radius):
 raw=Image.open(source).convert('RGB')
 height=round(raw.height*width/raw.width)
 shot=raw.resize((width,height),Image.Resampling.LANCZOS)
 d=ImageDraw.Draw(canvas)
 d.rounded_rectangle((x,y,x+width+2*pad-1,y+height+2*pad-1),radius,fill='#151515')
 mask=Image.new('L',shot.size,0); ImageDraw.Draw(mask).rounded_rectangle((0,0,width-1,height-1),max(1,radius-pad),fill=255)
 canvas.paste(shot,(x+pad,y+pad),mask)
 assert y+height+2*pad<=canvas.height,('Device extends beyond artwork',y,height,canvas.height)

def screenshot(kind,index,row):
 name,head,sub=row
 if kind=='iphone': W,H,hs,ss,width,pad,radius,top=(1320,2868,108,42,1000,24,126,110)
 elif kind=='medium': W,H,hs,ss,width,pad,radius,top=(1206,2622,99,38,914,22,115,100)
 else: W,H,hs,ss,width,pad,radius,top=(2064,2752,144,50,1480,26,64,85)
 c=Image.new('RGB',(W,H),'white')
 y=text_lines(c,head,(0,top),hs,True,center=True)
 if name=='study': sub='Requires supported Apple Intelligence hardware.'
 text_lines(c,sub,(0,y+30),ss,color=MUTED,center=True)
 screen_top={'iphone':550,'medium':503,'ipad':675}[kind]
 device(c,CAP/('ipad' if kind=='ipad' else 'iphone')/(name+'.png'),width,(W-width-2*pad)//2,screen_top,pad,radius)
 folder=ASO/{'iphone':'screenshots-6.9','medium':'screenshots-6.3','ipad':'screenshots-ipad-13'}[kind]; folder.mkdir(exist_ok=True)
 prefix={'iphone':'BibleAI-6.9','medium':'BibleAI-6.3','ipad':'BibleAI-ipad13'}[kind]
 p=folder/f'{prefix}-{index}.png'
 c.save(p)
 return p

def header(search=False):
 W,H=(3840,2560) if search else (3840,1646)
 name='search-results' if search else 'product-page-header'
 # The center stays readable when App Store placements crop at the edges.
 x,y,hs,ss,pw,px,py=(430,770,158,60,990,2350,175) if search else (560,470,126,54,660,2350,105)
 captions=[('resume','A quiet moment.\nOne verse at a time.','Read Scripture at your own pace.'),
           ('reader','Make room\nfor Scripture.','The King James Version, one swipe at a time.'),
           ('plans','A little reading.\nEvery day.','Choose a plan and keep your place.')]
 files=[]
 for i,(src,head,sub) in enumerate(captions):
  c=Image.new('RGB',(W,H),'white')
  end=text_lines(c,head,(x,y),hs,True)
  text_lines(c,sub,(x+4,end+85),ss,color=MUTED)
  text_lines(c,'BIBLEAI',(x+4,end+240),round(ss*.65),color=MUTED)
  device(c,CAP/'iphone'/(src+'.png'),pw,px,py,24 if search else 18,136 if search else 90)
  p=SCRATCH/f'{name}-scene-{i}.png'; c.save(p); files.append(str(p))
 out=ASO/'header-video'; out.mkdir(exist_ok=True)
 # At 5s the video holds scene1, which is the reader hero.
 Image.open(files[1]).save(out/(name+'-poster.png'))
 return files

def preview_captions():
 rows=[('Read one verse\nat a time.',0,7),('Explore the\npassage.',7,10),('Find a familiar\npassage.',10,14),('Follow a\nreading plan.',14,18),('Keep meaningful\nverses.',18,21.5)]
 for i,(caption,start,end) in enumerate(rows):
  c=Image.new('RGB',(886,235),'white'); text_lines(c,caption,(0,30),66,True,center=True,gap=1.12)
  c.save(SCRATCH/f'preview-caption-{i}.png')
 return [{'file':str(SCRATCH/f'preview-caption-{i}.png'),'start':r[1],'end':r[2]} for i,r in enumerate(rows)]

def main():
 SCRATCH.mkdir(parents=True,exist_ok=True)
 shots=[]
 if '--medium-only' in sys.argv:
  for i,row in enumerate(STORY,1): screenshot('medium',i,row)
  print('Rendered six required 1206x2622 iPhone screenshots.'); return
 for kind in ['iphone','medium','ipad']:
  rows=STORY if kind!='ipad' else [STORY[0],STORY[2],STORY[3],
   ('completion','Build a habit.\nOne day at a time.','Celebrate a completed reading.'),
   ('onboarding','Your plan.\nYour pace.','Choose a goal and a daily reading time.'),STORY[5]]
  for i,row in enumerate(rows,1): shots.append(screenshot(kind,i,row))
 scenes={'header':header(False),'search':header(True)}
 manifest={'screenshots':[str(p.relative_to(ASO)) for p in shots],'scenes':scenes,'previewCaptions':preview_captions(),'realUI':str(CAP),'previewSource':str(HERE/'source-preview.mp4')}
 (SCRATCH/'render-inputs.json').write_text(json.dumps(manifest,indent=2)+'\n')
 board=Image.new('RGB',(1320,1545),'#F5F5F7')
 for i,p in enumerate(shots):
  im=Image.open(p); im.thumbnail((206,490)); board.paste(im,((i%6)*220+7,(i//6)*515+12))
 board.save(ASO/'preview-board.png')
 print('Rendered 18 screenshots, header/search scene art, and preview captions.')
if __name__=='__main__': main()
