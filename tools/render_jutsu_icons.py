"""Convert exactly 28 actual-game jutsu SVG icons to transparent 512x512 PNGs.
This does not upload to Roblox or change the live game.
Run: python -m pip install cairosvg; python tools/render_jutsu_icons.py
"""
from pathlib import Path
import sys
root=Path(__file__).resolve().parent.parent
src=root/'assets/icons/jutsu-concepts-svg'
out=root/'assets/icons/jutsu-concepts-png'
try:
 import cairosvg
except ImportError:
 sys.exit('Install CairoSVG: python -m pip install cairosvg')
files=sorted(src.glob('*.svg'))
if len(files)!=28:
 sys.exit(f'Expected 28 SVG icons, found {len(files)}; no files converted')
out.mkdir(parents=True,exist_ok=True)
for f in files:
 dest=out/(f.stem+'.png')
 cairosvg.svg2png(bytestring=f.read_bytes(),write_to=str(dest),output_width=512,output_height=512)
 print(dest.relative_to(root))
print('Converted',len(files),'PNG icons. Visually QA before Roblox upload.')
