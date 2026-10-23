"""Recompute v004 cached foot markers against actual recorded Player motion."""

import argparse
import hashlib
import json
import math
from pathlib import Path

from PIL import Image


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def check(bank_path, record_path):
    bank = json.loads(bank_path.read_text())
    record = json.loads(record_path.read_text())
    assert bank["complete"] and bank["motion_sha256"] == sha(record_path)
    assert len(bank["timeline"]) == len(record["rows"]) == 3840
    assert record["speed"] == 240 and record["duration_game_seconds"] == 64
    assert len(record["events"]) == 1 and record["events"][0]["kind"] == "committed_pickup"
    frames = {frame["pose_index"]: frame for frame in bank["frames"]}
    assert set(frames) == set(range(len(bank["poses"])))
    for frame in frames.values():
        path = (bank_path.parent / frame["path"]).resolve()
        assert bank_path.parent.resolve() in path.parents
        assert sha(path) == frame["sha256"]
        with Image.open(path) as image:
            assert image.size == tuple(bank["canvas"]) and image.mode == "RGBA"
            bbox = image.getchannel('A').getbbox()
            assert list(bbox) == frame["alpha_bbox"]
            assert bbox[0] > 0 and bbox[1] > 0 and bbox[2] < image.width and bbox[3] < image.height
    marker_error = max_slide = 0
    comparisons = 0
    previous = None
    previous_position = [-160.0, -220.0]
    maximum_actual_displacement = 0.0
    for actual, planned in zip(record["rows"], bank["timeline"]):
        assert planned["tick"] == actual["tick"] and planned["position"] == actual["position"]
        assert abs(actual["delta"] - 1 / 60) < 1e-6
        displacement = [actual["position"][axis] - previous_position[axis] for axis in range(2)]
        assert math.dist(displacement, actual["motion"]) < 1e-5
        previous_position = actual["position"]
        maximum_actual_displacement = max(maximum_actual_displacement, math.hypot(*displacement))
        frame = frames[planned["pose"]]
        soles = []
        for pixel, contact in zip(frame["soles"], planned["contacts"]):
            world = [actual["position"][axis] + (pixel[axis] - bank["pivot"][axis]) * bank["display_scale"] for axis in range(2)]
            marker_error = max(marker_error, math.dist(world, contact["sole_world"]))
            soles.append(world)
        if previous:
            before, before_soles = previous
            for foot in range(4):
                now = planned["contacts"][foot]
                prior = before["contacts"][foot]
                if now["stance"] and prior["stance"] and now["episode"] == prior["episode"]:
                    max_slide = max(max_slide, math.dist(soles[foot], before_soles[foot]))
                    comparisons += 1
        previous = planned, soles
    assert marker_error < .02 and max_slide < .25
    assert sum(row["collisions"] > 0 for row in record["rows"]) > 30
    return {"scope": "authored sole markers, not image-inferred contact or visual approval",
            "actual_player_ticks": 3840, "nominal_seconds": 64, "rendered_poses": len(frames),
            "stance_comparisons": comparisons, "max_marker_error_px": marker_error,
            "max_stance_slide_px": max_slide, "record_sha256": sha(record_path), "bank_sha256": sha(bank_path)}


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("bank", type=Path)
    parser.add_argument("record", type=Path)
    args = parser.parse_args()
    print(json.dumps(check(args.bank.resolve(), args.record.resolve()), indent=2))
