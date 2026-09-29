"""Check saved render/GPU evidence without trusting its reported pass booleans.

Run with Python and Pillow, passing render_manifest.json and walk_probe.json.
This checks provenance, pixels and real Player motion; it cannot approve visual style.
"""

import argparse
import hashlib
import json
import math
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def local_path(base: Path, value: str) -> Path:
    path = (base / value).resolve()
    if base.resolve() not in path.parents:
        raise ValueError("Evidence path escaped its directory")
    return path


def check(render_path: Path, gpu_path: Path) -> dict:
    render = json.loads(render_path.read_text(encoding="utf-8"))
    gpu = json.loads(gpu_path.read_text(encoding="utf-8"))
    assert gpu["source_manifest_sha256"] == sha(render_path), "GPU read a different render manifest"
    assert gpu["fixture_sha256"] == sha(ROOT / "tools/art/probe_player_mesh_walk.gd"), "Fixture changed"
    for filename, expected in render["sources"].items():
        assert sha(local_path(ROOT / "tools/art", filename)) == expected, "Render source changed: " + filename
    assert sha(local_path(render_path.parent, render["blend_path"])) == render["blend_sha256"], "Blend changed"
    assert render["blender_version"] == "4.5.13 LTS"
    assert render["canvas"] == [512, 512] and render["pivot"] == [256, 384]
    assert render["display_scale"] == .5 and render["camera_pitch_degrees"] == 35
    assert abs(render["actual_reference_alpha_height_px"] - 288) <= 1
    by_frame, directions = {}, set()
    for frame in render["frames"]:
        path = local_path(render_path.parent, frame["path"])
        assert sha(path) == frame["sha256"], "PNG changed: " + frame["path"]
        with Image.open(path) as image:
            assert image.mode == "RGBA" and image.size == (512, 512)
            alpha = image.getchannel("A")
            bbox = alpha.getbbox()
            assert bbox is not None and list(bbox) == frame["alpha_bbox"]
            assert bbox[0] > 0 and bbox[1] > 0 and bbox[2] < 512 and bbox[3] < 512
        if frame["walk_frame"] is None:
            directions.add(frame["direction"])
        else:
            assert frame["direction"] == "down_right"
            assert frame["walk_frame"] not in by_frame
            by_frame[frame["walk_frame"]] = frame
    assert directions == {"down_right", "down_left", "up_right", "up_left"}
    assert set(by_frame) == set(range(18)), "Missing/duplicate walk frames"
    assert gpu["move_speed"] == 240 and gpu["physics_fps"] == 60
    assert len(gpu["rows"]) == 36 and len(gpu["captures"]) == 5
    max_slide, max_move_error, comparisons = 0.0, 0.0, 0
    for index, row in enumerate(gpu["rows"]):
        assert row["tick"] == index + 1 and row["frame_index"] == index % 18
        assert abs(row["delta"] - 1 / 60) < 1e-7
        assert row["player_state"] == "move" and row["input_axes"] == [1.0, 1.0]
        source_feet = by_frame[row["frame_index"]]["feet"]
        assert len(row["feet"]) == len(source_feet) == 4
        for foot, source in zip(row["feet"], source_feet):
            assert foot["id"] == source["id"] and foot["stance"] == source["stance"]
            expected = [row["position"][axis] + (source["sole_native_px"][axis] - [256, 384][axis]) * .5
                        for axis in range(2)]
            assert math.dist(expected, foot["world"]) < .001, "GPU transform differs from render pivot"
        if index == 0:
            continue
        previous = gpu["rows"][index - 1]
        displacement = [row["position"][axis] - previous["position"][axis] for axis in range(2)]
        max_move_error = max(max_move_error, math.dist(displacement, [4 / math.sqrt(2)] * 2))
        for foot, before in zip(row["feet"], previous["feet"]):
            if foot["stance"] and before["stance"] and foot["phase"] > before["phase"]:
                comparisons += 1
                max_slide = max(max_slide, math.dist(foot["world"], before["world"]))
    assert comparisons == 64 and max_slide < .25 and max_move_error < .01
    for capture in gpu["captures"]:
        assert 1 <= capture["requested_tick"] <= capture["render_tick"] <= 36
        assert sha(local_path(gpu_path.parent, capture["file"])) == capture["sha256"]
    return {"result": "technical_pass_not_visual_approval", "rgba_frames": len(render["frames"]),
            "standing_directions": len(directions), "walk_frames": len(by_frame),
            "actual_player_ticks": 36, "stance_comparisons": comparisons,
            "max_stance_slide_px": max_slide, "max_move_error_px": max_move_error,
            "render_sha256": sha(render_path), "gpu_report_sha256": sha(gpu_path)}


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("render_manifest", type=Path)
    parser.add_argument("gpu_report", type=Path)
    args = parser.parse_args()
    print(json.dumps(check(args.render_manifest.resolve(), args.gpu_report.resolve()), indent=2))
