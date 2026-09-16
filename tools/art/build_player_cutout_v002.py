"""Original layered SVG anatomy/rig study; technical and unapproved.

Four views are projected from newly authored geometry, not mirrored AG1 pixels.
One orthographic scale is calibrated on the down-right stand, then locked.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import subprocess
from datetime import datetime, timezone

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
VIEWS = {"down_right": 45, "down_left": 135, "up_right": -45, "up_left": -135}
PITCH = math.radians(35)
PIVOT = (256, 384)
POSES = [("stand", 0), ("idle", 0), ("idle", 1), ("walk", 0), ("walk", 1),
         ("pickup", 0), ("pickup", 1), ("soak", 0), ("soak", 1)]


def hull(points):
    pts = sorted(set(points))
    def cross(a, b, c):
        return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
    lower, upper = [], []
    for p in pts:
        while len(lower) > 1 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    for p in reversed(pts):
        while len(upper) > 1 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return lower[:-1] + upper[:-1]


def rounded(points):
    """Quadratic corner softening retains the broad muzzle's planar silhouette."""
    blend = lambda a,b: (.75*a[0]+.25*b[0], .75*a[1]+.25*b[1])
    start = blend(points[-1],points[0])
    text = f'M {start[0]:.3f} {start[1]:.3f}'
    for i,p in enumerate(points):
        before, after = blend(p,points[i-1]), blend(p,points[(i+1)%len(points)])
        text += f' L {before[0]:.3f} {before[1]:.3f} Q {p[0]:.3f} {p[1]:.3f} {after[0]:.3f} {after[1]:.3f}'
    return text + ' Z'


class Figure:
    def __init__(self, direction, pose="stand", frame=0):
        self.direction, self.pose, self.frame = direction, pose, frame
        self.yaw = math.radians(VIEWS[direction])
        self.front = math.sin(self.yaw) > 0
        self.right_visible = math.cos(self.yaw) > 0
        self.bob = 1.5 if pose == "idle" and frame else 0
        self.head_drop = (5 if frame == 0 else 10) if pose == "pickup" else 0
        self.squat = 7 if pose == "soak" else 0
        self.layers = []

    def p(self, x, y, z):
        # +X is the snout, +Y anatomical left; no image mirroring.
        return (x*math.cos(self.yaw)+y*math.sin(self.yaw),
                (x*math.sin(self.yaw)-y*math.cos(self.yaw))*math.sin(PITCH)-z*math.cos(PITCH))

    def shape(self, points, fill, opacity=1, stroke=None, width=.65):
        pts = [self.p(*p) for p in points]
        extra = f' stroke="{stroke}" stroke-width="{width}" stroke-linejoin="round"' if stroke else ''
        return f'<path d="{rounded(pts)}" fill="{fill}" opacity="{opacity}"{extra}/>'

    def ellipsoid(self, center, radii, fill, opacity=1):
        cx,cy = self.p(*center)
        basis = [self.p(radii[0],0,0), self.p(0,radii[1],0), self.p(0,0,radii[2])]
        a = sum(v[0]**2 for v in basis)
        b = sum(v[0]*v[1] for v in basis)
        d = sum(v[1]**2 for v in basis)
        disc = math.sqrt((a-d)**2+4*b*b)
        major, minor = math.sqrt((a+d+disc)/2), math.sqrt(max(.001,(a+d-disc)/2))
        angle = math.degrees(.5*math.atan2(2*b,a-d))
        return (f'<ellipse cx="{cx:.3f}" cy="{cy:.3f}" rx="{major:.3f}" ry="{minor:.3f}" '
                f'transform="rotate({angle:.3f} {cx:.3f} {cy:.3f})" fill="{fill}" opacity="{opacity}"/>')

    def line(self, points, stroke, width, opacity=1):
        pp = [self.p(*p) for p in points]
        d = f'M {pp[0][0]:.3f} {pp[0][1]:.3f}'
        for i,p in enumerate(pp[1:-1],1):
            q=pp[i+1]
            d += f' Q {p[0]:.3f} {p[1]:.3f} {(p[0]+q[0])/2:.3f} {(p[1]+q[1])/2:.3f}'
        d += f' L {pp[-1][0]:.3f} {pp[-1][1]:.3f}'
        return f'<path d="{d}" fill="none" stroke="{stroke}" stroke-width="{width}" opacity="{opacity}" stroke-linecap="round" stroke-linejoin="round"/>'

    def body(self):
        z = 82+self.bob-self.squat
        s = self.ellipsoid((-26,0,z), (126,67,62), 'url(#body)')
        s += self.ellipsoid((62,0,z-1),(49,55,51),'url(#body)')
        # Broad transparent washes, a few directional fur marks; no tiled noise.
        s += self.ellipsoid((-57,9,z+25), (83,40,22), '#ddc1a0', .12)
        s += self.ellipsoid((-58,-32,z-17), (84,24,30), '#765b49', .10)
        for x,y,zz in [(-96,-31,104),(-62,-47,108),(-28,-54,100),(-108,22,116),(-75,41,108)]:
            s += self.line([(x,y,zz-self.squat),(x+7,y+2,zz+1-self.squat)], '#d8bc97', 1.25, .28)
        return s

    def head(self):
        drop = self.head_drop+self.squat-self.bob
        points = [(57,-43,117),(58,43,117),(96,-47,132),(96,47,132),
                  (149,-43,122),(149,43,122),(182,-40,98),(182,40,98),
                  (179,-39,58),(179,39,58),(119,-48,33),(119,48,33),(64,-46,46),(64,46,46)]
        projected = hull([self.p(x,y,z-drop) for x,y,z in points])
        s = f'<path d="{rounded(projected)}" fill="url(#head)"/>'
        if self.front:
            # Broad, blunt nasal plate rather than a round pet muzzle.
            s += self.shape([(181,-32,101-drop),(183,-31,108-drop),(184,-20,112-drop),
                             (184,21,112-drop),(182,32,106-drop),(182,33,96-drop),
                             (181,28,94-drop),(182,-28,94-drop)], 'url(#nose)')
            for y in [-25,25]:
                s += self.ellipsoid((184,y,104-drop),(1.3,3.3,2.0),'#554436')
            s += self.line([(180,0,94-drop),(180,0,78-drop)], '#7a6048', .7,.45)
            s += self.line([(177,-21,72-drop),(180,0,69-drop),(177,23,72-drop)], '#745a43', .75,.35)
        # Near side eye; away-facing views show the quiet side profile only.
        side = -1 if self.right_visible else 1
        eye_x = 133 if self.front else 120
        if self.pose == 'soak' and self.frame:
            s += self.line([(eye_x-3,side*45,114-drop),(eye_x+3,side*45,114-drop)],'#554331',1.3)
        else:
            s += self.ellipsoid((eye_x,side*45,114-drop),(3.4,1.5,2.8),'#3f342c')
            s += self.ellipsoid((eye_x+.4,side*45.5,115-drop),(.55,.4,.5),'#e5ceb0',.72)
        s += self.line([(eye_x-6,side*45,119-drop),(eye_x+2,side*45,121-drop)], '#927358',1,.42)
        return s

    def ears(self):
        s = ''
        for side in [-1,1]:
            z = 137-self.head_drop-self.squat+self.bob
            s += self.ellipsoid((76,side*42,z),(9,6.5,9),'#97775c')
            s += self.ellipsoid((79,side*43,z+1),(5,3.5,5.5),'#b29173')
        return s

    def feet(self):
        s = ''
        feet = [(-91,-36),(-91,36),(91,-30),(91,30)]
        for i,(x,y) in enumerate(feet):
            walk = (1 if (i+self.frame)%2 else -1)*7 if self.pose == 'walk' else 0
            lift = 4 if self.pose == 'walk' and walk>0 else 0
            if self.pose == 'pickup' and i==2:
                walk, lift = 5, 5
            s += self.ellipsoid((x+walk,y,25+lift),(21,15,25),'url(#foot)')
            if y < 0 or not self.right_visible:
                for toe in [-5,3]:
                    s += self.line([(x+walk+13,y+toe,8+lift),(x+walk+18,y+toe,7+lift)], '#755c47',.8,.7)
        return s

    def scarf(self):
        d = self.squat-self.bob
        side = -1 if self.right_visible else 1
        # Only the near neck ribbon is above the head layer; the far half is
        # occluded. Drawing the whole ring here would paint across the face.
        s = self.shape([(50,side*49,111-d),(66,side*57,107-d),(84,side*56,76-d),
                        (86,side*40,49-d),(79,side*18,42-d),(67,side*19,50-d),
                        (72,side*39,58-d),(64,side*46,83-d)],'url(#scarf)')
        s += self.line([(58,side*51,103-d),(72,side*51,79-d),(79,side*39,56-d)],'#87b3ad',1.3,.55)
        return s

    def knot(self):
        # Always anatomical left; visible in left-side views, occluded in right views.
        d = self.squat-self.bob
        s = self.shape([(66,59,77-d),(77,64,75-d),(75,71,54-d),(61,70,57-d)],'#427b7c')
        s += self.shape([(71,63,59-d),(73,72,40-d),(59,77,43-d),(62,65,64-d)],'#508b88')
        s += self.ellipsoid((70,62,69-d),(8,6,7),'#619796')
        return s

    def bag(self):
        d = self.squat-self.bob
        s = self.shape([(-78,-75,86-d),(-51,-83,96-d),(-24,-81,81-d),(-21,-80,45-d),
                        (-37,-78,33-d),(-73,-73,40-d)], '#697049')
        s += self.shape([(-79,-82,83-d),(-54,-87,93-d),(-25,-86,80-d),(-21,-85,48-d),
                        (-45,-87,36-d),(-75,-84,47-d)], 'url(#bag)', stroke='#697748')
        # Leaf flap and small notch, visible thickness and strap attachment tabs.
        s += self.shape([(-81,-89,84-d),(-57,-91,96-d),(-49,-91,86-d),(-39,-91,94-d),
                        (-23,-90,81-d),(-28,-91,66-d),(-53,-92,63-d),(-74,-90,70-d)], '#99a269')
        s += self.line([(-76,-90,78-d),(-52,-92,69-d),(-29,-91,77-d)],'#b4bc86',1.1,.65)
        s += self.ellipsoid((-52,-93,63-d),(5.5,2.3,5),'#bd945c')
        s += self.line([(-55,-94,63-d),(-49,-94,63-d)],'#816641',.8)
        s += self.line([(-75,-84,81-d),(-75,-79,95-d)],'#75834c',4)
        return s

    def strap(self):
        d = self.squat-self.bob
        return self.line([(54,33,124-d),(7,3,137-d),(-40,-48,114-d),(-75,-78,93-d)],'#868651',3.7) + self.line([(54,33,126-d),(7,3,139-d),(-40,-48,116-d),(-75,-78,95-d)],'#c0bb7c',1,.45)

    def svg(self, scale, offset):
        # Fixed view-dependent base transform is reused by every animation key.
        parts = [('feet',self.feet())]
        if not self.right_visible:
            parts += [('bag',self.bag())]
        if not self.front:
            parts += [('head',self.head()),('ears',self.ears()),('scarf',self.scarf())]
        parts += [('body',self.body()),('bag-strap',self.strap())]
        if self.front:
            if self.right_visible:
                parts += [('scarf-knot-far',self.knot())]
            parts += [('head',self.head()),('ears',self.ears()),('scarf',self.scarf())]
        if self.right_visible:
            parts += [('bag',self.bag())]
        else:
            parts += [('scarf-knot',self.knot())]
        defs = ''.join(f'<linearGradient id="{name}" x1="0" y1="0" x2=".85" y2="1"><stop offset="0" stop-color="{a}"/><stop offset=".5" stop-color="{b}"/><stop offset="1" stop-color="{c}"/></linearGradient>' for name,a,b,c in [
            ('body','#bea486','#ac8b6b','#8c6e53'),('head','#c5aa88','#b69471','#947355'),
            ('foot','#8d7053','#806246','#71553f'),('nose','#9b8063','#876b50','#775d45'),
            ('scarf','#7da8a2','#548e8e','#427b7e'),('bag','#a0a775','#899657','#73834b')])
        groups = ''.join(f'<g id="{name}">{shape}</g>' for name,shape in parts)
        return ('<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">'
                '<metadata>Original procedural cutout v002; technical exploration; NOT APPROVED. '
                'Camera pitch 35 degrees; light upper left; fixed anatomical left scarf knot, right bag.</metadata>'
                f'<defs>{defs}</defs><g transform="translate({offset[0]:.6f} {offset[1]:.6f}) scale({scale:.8f})">{groups}</g></svg>\n')


def render(svg, png, log):
    command = ['pwsh','-NoProfile','-File',str(ROOT/'tools/render_svg_preview.ps1'),
               '-InputPath',str(svg),'-OutputPath',str(png)]
    proc = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, encoding='utf-8', errors='replace')
    log.write_text(proc.stdout+'\n'+proc.stderr, encoding='utf-8')
    if proc.returncode or any(line.lstrip().startswith(('ERROR:','WARNING:','SCRIPT ERROR:')) for line in (proc.stdout+proc.stderr).splitlines()):
        raise RuntimeError(f'Render failed: {log}')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--run', default=datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ'))
    args = parser.parse_args()
    if not args.run.replace('-','').replace('_','').isalnum():
        raise ValueError('Run must be a simple directory name')
    source_root = ROOT/'art/candidates/player_animation_ab_v001/cutout'/args.run
    output = ROOT/'build/art-pipeline/player_ab_v001/cutout'/args.run
    source_root.mkdir(parents=True,exist_ok=False)
    output.mkdir(parents=True,exist_ok=False)
    reference = Figure('down_right')
    # Calibration uses a roomy provisional scale once, never per-view/per-frame crops.
    source = source_root/'chr_player_calibration_v002.svg'
    source.write_text(reference.svg(1.1,(256,340)),encoding='utf-8',newline='\n')
    preview = output/'chr_player_calibration_v002.png'
    render(source,preview,output/'calibration.log')
    bounds = Image.open(preview).getchannel('A').getbbox()
    scale = 1.1*288/(bounds[3]-bounds[1])
    calibration=[]
    for iteration in range(4):
        calibrated_source=source_root/f'chr_player_scale_calibration_{iteration:02d}_v002.svg'
        calibrated_preview=output/f'chr_player_scale_calibration_{iteration:02d}_v002.png'
        calibrated_source.write_text(reference.svg(scale,PIVOT),encoding='utf-8',newline='\n')
        render(calibrated_source,calibrated_preview,output/f'scale_calibration_{iteration:02d}.log')
        box=Image.open(calibrated_preview).getchannel('A').getbbox()
        actual_height=box[3]-box[1]
        calibration.append(dict(scale=scale,actual_alpha_height=actual_height,
                                source_path=os.path.relpath(calibrated_source,output).replace('\\','/'),
                                source_sha256=sha(calibrated_source),path=calibrated_preview.name))
        if actual_height == 288:
            break
        scale *= 288/actual_height
    else:
        raise RuntimeError('Reference stand did not converge to 288px; preserve failed calibration.')
    frames=[]
    for direction in VIEWS:
        base = Figure(direction)
        offset=PIVOT  # Same rig ground origin, all directions and all poses.
        for pose,frame in (POSES if direction=='down_right' else [('stand',0)]):
            name=f'chr_player_{direction}_{pose}_{frame:02d}_v002'
            svg=source_root/(name+'.svg'); png=output/(name+'.png')
            svg.write_text(Figure(direction,pose,frame).svg(scale,offset),encoding='utf-8',newline='\n')
            render(svg,png,output/(name+'.log'))
            bounds=Image.open(png).getchannel('A').getbbox()
            frames.append(dict(direction=direction,pose=pose,frame=frame,path=png.name,
                               source_path=os.path.relpath(svg,output).replace('\\','/'),source_sha256=sha(svg),
                               png_sha256=sha(png),alpha_bbox=list(bounds),scale=scale,view_offset=list(offset)))
    manifest=dict(route='cutout',status='technical_unapproved',camera_pitch_degrees=35,
                  canvas=[512,512],pivot=list(PIVOT),reference_body_height_px=288,
                  source_script_sha256=sha(Path(__file__)),frames=frames,
                  calibration=calibration,actual_reference_height_px=actual_height,
                  source_geometry='Original newly authored projected layered geometry; no raster tracing or mirroring.',
                  reference_paths=['art/candidates/player_capybara_v1/visual_concepts/chr_player_clean_concept_ag1_v001.png'],
                  anatomical_sides={'scarf_knot':'left','bag':'right'},
                  pivot_semantics='fixed rig ground origin / four-foot support center; no per-view or per-frame repositioning',
                  rear_shortening_design_percent=8,light='screen_upper_left',
                  limitations=['Vector technical shape study, not production paint.','Soak pose has no water overlay.'])
    (output/'render_manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
    rows=['file_path,raw_path,source_path,game_path']
    for f in frames:
        rows.append(f'{(output/f["path"]).relative_to(ROOT).as_posix()},,{(output/f["source_path"]).resolve().relative_to(ROOT).as_posix()},')
    (output/'all_png_manifest.csv').write_text('\n'.join(rows)+'\n',encoding='utf-8')
    print(output)


if __name__ == '__main__':
    main()
