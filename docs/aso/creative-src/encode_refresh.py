#!/usr/bin/env python3
"""Encode a captioned real-UI preview and two quiet, seamless store loops, serially."""
from pathlib import Path
import json, shutil, subprocess
HERE=Path(__file__).resolve().parent
ASO=HERE.parent
WORK=HERE.parents[2]/'build/aso-refresh'
FFMPEG=shutil.which('ffmpeg')
assert FFMPEG, 'Install the established ffmpeg binary first'
assert shutil.disk_usage(HERE).free>=15*1024**3, 'Need 15 GiB free'
inputs=json.loads((WORK/'render-inputs.json').read_text())

def run(args):
 subprocess.run([FFMPEG,'-nostdin','-y','-v','error','-filter_complex_threads','1',*args],check=True,timeout=240)
def output(path,seconds):
 return ['-t',str(seconds),'-r','30','-c:v','libx264','-threads','2','-preset','veryfast','-crf','18',
         '-profile:v','high','-pix_fmt','yuv420p','-c:a','aac','-b:a','96k','-movflags','+faststart',str(path)]

# Preserve the app interaction recording, skipping its introductory marketing screen.
args=['-ss','8','-t','21.5','-i',inputs['previewSource']]
for c in inputs['previewCaptions']: args += ['-loop','1','-framerate','30','-i',c['file']]
filters=['[0:v]scale=732:1586,pad=886:1920:77:260:white,setsar=1[base]']
last='base'
for i,c in enumerate(inputs['previewCaptions'],1):
 label=f'p{i}'
 filters.append(f"[{last}][{i}:v]overlay=0:0:enable='gte(t,{c['start']})*lt(t,{c['end']})'[{label}]")
 last=label
preview=ASO/'preview/BibleAI-preview-6.9.mp4'
run(args+['-filter_complex',';'.join(filters),'-map',f'[{last}]','-map','0:a?']+output(preview,21.5))
print('Encoded real-UI app preview',flush=True)

for key,name in [('header','product-page-header'),('search','search-results')]:
 scenes=inputs['scenes'][key]
 args=[]
 for p in [*scenes,scenes[0]]: args += ['-loop','1','-framerate','30','-t','3.5','-i',p]
 args += ['-f','lavfi','-i','anullsrc=channel_layout=stereo:sample_rate=48000']
 filters=['[0:v]format=yuv420p,setsar=1[v0]','[1:v]format=yuv420p,setsar=1[v1]',
          '[2:v]format=yuv420p,setsar=1[v2]','[3:v]format=yuv420p,setsar=1[v3]',
          '[v0][v1]xfade=transition=fade:duration=0.5:offset=3[x1]',
          '[x1][v2]xfade=transition=fade:duration=0.5:offset=6[x2]',
          '[x2][v3]xfade=transition=fade:duration=0.5:offset=9[out]']
 path=ASO/'header-video'/(name+'.mp4')
 run(args+['-filter_complex',';'.join(filters),'-map','[out]','-map','4:a']+output(path,10.5))
 # Poster comes from the encoded video, rather than an unencoded source frame.
 run(['-ss','5','-i',str(path),'-frames:v','1',str(path.with_name(name+'-poster.png'))])
 (ASO/'header-video'/(name+'-manifest.json')).write_text(json.dumps({
  'size':[3840,1646] if key=='header' else [3840,2560], 'fps':30,'seconds':10.5,
  'loop':True,'audio':'silent stereo AAC 48 kHz','posterSecond':5,
  'source':'Retained real October 30 BibleAI Simulator captures; see creative-src/captures/README.md',
  'scenes':['Genesis reader','John 3:16 reader','Reading plans','Genesis reader'],
  'encoder':'creative-src/encode_refresh.py'
 },indent=2)+'\n')
 print('Encoded',name,flush=True)
print('All three videos encoded serially with two encoder threads.',flush=True)

subprocess.run(['node','scripts/aso-refresh.mjs','check'],check=True,timeout=60)
