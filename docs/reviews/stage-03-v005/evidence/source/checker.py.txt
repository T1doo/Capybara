"""Independently inspect live draw contacts, actual motion and native source PNGs."""

import argparse
import hashlib
import json
import math
from pathlib import Path

from PIL import Image


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def check(manifest_path, record_path, allow_smoke):
    source = json.loads(manifest_path.read_text())
    record = json.loads(record_path.read_text())
    assert sha(manifest_path) == record["manifest_sha256"] and source["complete"]
    assert len(source["headings"]) == 16
    named = {h["screen_facing"] for h in source["headings"] if h["screen_facing"] != "turn_inbetween"}
    assert named == {"up", "up_right", "right", "down_right", "down", "down_left", "left", "up_left"}
    axes = {"up": (0, -1), "up_right": (1, -1), "right": (1, 0), "down_right": (1, 1),
            "down": (0, 1), "down_left": (-1, 1), "left": (-1, 0), "up_left": (-1, -1)}
    p = source["projection"]
    determinant = p[0][0] * p[1][1] - p[0][1] * p[1][0]
    expected_yaw = {name: math.atan2((-p[1][0] * dx + p[0][0] * dy) / determinant,
                                    (p[1][1] * dx - p[0][1] * dy) / determinant) for name, (dx, dy) in axes.items()}
    angle_error = lambda a, b: abs(math.atan2(math.sin(a-b), math.cos(a-b)))
    for view in source["headings"]:
        if view["screen_facing"] in named:
            assert angle_error(view["yaw"], expected_yaw[view["screen_facing"]]) < 1e-5
    rows = record["rows"]
    assert len(rows) == record["ticks"] == (1400 if record["smoke_only"] else 3840)
    assert allow_smoke or not record["smoke_only"]
    assert record["speed"] == 240 and record["radius"] == 22 and record["scale"] == [3, 3]
    assert record["pickup_count"] == 1 and record["unsupported_pickups"] == 0 and record["gait_resets"] == 1
    assert record["inventory_delta"] == 1 and record["pickup_visual_consumed"]
    images = [e for h in source["headings"] for e in h["upper"]]
    images += [f["image"] for h in source["headings"] for f in h["feet"]]
    pixels = 0
    for entry in images:
        path = (manifest_path.parent / entry["path"]).resolve()
        assert manifest_path.parent in path.parents and sha(path) == entry["sha256"]
        with Image.open(path) as image:
            assert image.mode == "RGBA" and image.size == (640, 640)
            box = image.getchannel("A").getbbox()
            assert box is not None and list(box) == entry["alpha_bbox"]
            assert min(box[:2]) > 0 and max(box[2:]) < 640
            pixels += (box[2] - box[0] + 2) * (box[3] - box[1] + 2) * 4
    assert record["texture_bytes"] == pixels and record["textures"] == len(images)
    previous_position, previous = [-160, -220], None
    marker_error = slide = 0
    comparisons = blocked = stable_block = 0
    moving_exact = set()
    facing_seen = set()
    heading_seen = set()
    for number, row in enumerate(rows):
        assert row["tick"] == number and abs(row["delta"] - 1 / 60) < 1e-6
        motion = [row["position"][i] - previous_position[i] for i in range(2)]
        assert math.dist(motion, row["motion"]) < 1e-5
        assert math.hypot(*motion) <= 240 * row["delta"] + record["safe_margin"] + 1e-4
        previous_position = row["position"]
        facing_seen.add(row["facing"])
        heading_seen.add(row["heading"])
        view = source["headings"][row["heading"]]
        aligned = angle_error(row["yaw"], expected_yaw[row["facing"]]) < 1e-4
        if view["screen_facing"] == row["facing"] and aligned and math.hypot(*motion) > 1:
            moving_exact.add(row["facing"])
        is_blocked = row["axes"] != [0, 0] and math.hypot(*motion) < .001
        blocked += is_blocked
        # A blocked actor can still be turning in place. Allow the final two
        # support steps to finish after alignment, then require no idle marching.
        stable_block = stable_block + 1 if is_blocked and aligned and previous and previous["facing"] == row["facing"] else 0
        for i, foot in enumerate(row["feet"]):
            assert all(math.isfinite(v) for v in foot["drawn_sole"] + foot["requested_sole"])
            marker_error = max(marker_error, math.dist(foot["drawn_sole"], foot["requested_sole"]))
            if previous:
                before = previous["feet"][i]
                if before["stance"] and foot["stance"] and before["episode"] == foot["episode"]:
                    slide = max(slide, math.dist(before["drawn_sole"], foot["drawn_sole"]))
                    comparisons += 1
            if stable_block > 20:
                assert foot["stance"] and abs(foot["lift"]) < 1e-6, "marching while actually blocked"
        previous = row
    assert facing_seen == moving_exact == named, "each facing must actually walk with its matching plate"
    assert heading_seen == set(range(16)) and blocked > 30
    assert comparisons > 1000 and marker_error < .02 and slide < .25
    return {"scope": "authored source UV markers measured through actual 2D draw triangles; not image-inferred contact or visual approval",
            "ticks": len(rows), "nominal_seconds": len(rows) / 60, "moving_exact_facings": sorted(moving_exact),
            "turn_headings": len(heading_seen), "blocked_ticks": blocked, "stance_comparisons": comparisons,
            "max_drawn_marker_error_px": marker_error, "max_stance_slide_px": slide,
            "cropped_texture_bytes": pixels, "source_images": len(images),
            "record_sha256": sha(record_path), "manifest_sha256": sha(manifest_path)}


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("manifest", type=Path)
    parser.add_argument("record", type=Path)
    parser.add_argument("--allow-smoke", action="store_true")
    args = parser.parse_args()
    print(json.dumps(check(args.manifest.resolve(), args.record.resolve(), args.allow_smoke), indent=2))
