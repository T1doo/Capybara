"""Bounded route-B head/cheek revision from the preserved v002 editable model.

Only geometry is changed; camera, lights, material, scale and foot controls are held.
The new build .blend preserves prior keys as exploratory controls, not accepted poses.
"""

import argparse
import hashlib
import json
import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/art"))
from build_player_mesh_v001 import alpha_metadata, configure_camera
from player_mesh_v002_motion import screen_yaw

OLD_X = [.10, .36, .63, .90, 1.16, 1.39, 1.46]
NEW_X = [.10, .28, .51, .75, 1.00, 1.18, 1.235]


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def head_x(value: float) -> float:
    if value <= OLD_X[0]:
        return value
    for index in range(len(OLD_X) - 1):
        if value <= OLD_X[index + 1]:
            weight = (value - OLD_X[index]) / (OLD_X[index + 1] - OLD_X[index])
            return NEW_X[index] * (1 - weight) + NEW_X[index + 1] * weight
    return NEW_X[-1] + value - OLD_X[-1]


def revise_shape() -> dict:
    root = bpy.data.objects["Character_v002__X_forward_Y_anatomical_left_Z_up"]
    body = bpy.data.objects["Continuous_back_shoulders_and_long_blunt_head"]
    features = bpy.data.objects["Head_features_control"]
    # Seven anterior cross-sections: a small shoulder valley followed by a broad cheek/muzzle mass.
    sections = [(.10, .58, .51, .72), (.28, .52, .46, .72), (.51, .57, .45, .735),
                (.75, .59, .43, .725), (1.00, .555, .365, .675),
                (1.18, .505, .30, .64), (1.235, .465, .285, .63)]
    if len(body.data.vertices) != 13 * 32:
        raise ValueError("Unexpected source topology; do not silently reshape a different model")
    for row, (x, width, height, center) in enumerate(sections, start=6):
        for index in range(32):
            angle = math.tau * index / 32
            c, s = math.cos(angle), math.sin(angle)
            y = math.copysign(abs(c) ** (2 / 2.35), c) * width
            lower_belly = 1.12 if s < 0 and row > 7 else 1.0
            z = center + math.copysign(abs(s) ** (2 / 2.35), s) * height * lower_belly
            vertex = body.data.vertices[row * 32 + index]
            change = Vector((x, y, z)) - vertex.co
            for key in body.data.shape_keys.key_blocks:
                key.data[vertex.index].co += change
            vertex.co = (x, y, z)
    body.data.update()
    for obj in features.children:
        if obj.type == "CURVE":
            for spline in obj.data.splines:
                for point in spline.bezier_points:
                    point.co.x = head_x(point.co.x)
                    if "lid" in obj.name:
                        point.co.y *= 1.10
                        point.co.z -= .02
        elif "eye" in obj.name or "glint" in obj.name:
            obj.location.x = head_x(obj.location.x)
            obj.location.y *= 1.10
            obj.location.z -= .02
        elif "nostril" in obj.name:
            obj.location.x = head_x(obj.location.x)
            obj.location.y *= .75
        elif obj.type == "MESH":
            for vertex in obj.data.vertices:
                vertex.co.x = head_x(vertex.co.x)
                if "muzzle" in obj.name:
                    vertex.co.y *= .80
                    vertex.co.z = .798 + (vertex.co.z - .798) * 1.45
            obj.data.update()
    root["status"] = "v003_shape_study_not_approved"
    return {"root": root}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model-manifest", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--preview-only", action="store_true")
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    source, output = args.model_manifest.resolve(), args.output_dir.resolve()
    if (ROOT / "build") not in source.parents or (ROOT / "build") not in output.parents or output.exists():
        raise ValueError("Use a preserved model and NEW output directory strictly below build")
    record = json.loads(source.read_text(encoding="utf-8"))
    original_blend = (source.parent / record["blend_path"]).resolve()
    if source.parent not in original_blend.parents or sha(original_blend) != record["blend_sha256"]:
        raise ValueError("Source blend path/hash differs")
    bpy.ops.wm.open_mainfile(filepath=str(original_blend))
    output.mkdir(parents=True)
    character = revise_shape()
    scene, camera = bpy.context.scene, bpy.context.scene.camera
    views = ["down_right"] if args.preview_only else ["down_right", "down_left", "up_right", "up_left"]
    frames = []
    for direction in views:
        configure_camera(character, camera, screen_yaw(direction), record["orthographic_scale"])
        path = output / (direction + "_idle.png")
        scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        alpha = alpha_metadata(path)
        if alpha["edge_alpha_pixels"]:
            raise ValueError("Revised model clips unchanged canvas")
        frames.append({"direction": direction, "pose": "shape_v003", "path": path.name,
                       "sha256": sha(path), **alpha})
    configure_camera(character, camera, screen_yaw("down_right"), record["orthographic_scale"])
    blend = output / "player_shape_v003.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(blend))
    (output / "source_snapshot.py").write_bytes(Path(__file__).read_bytes())
    result = {"route": "blender_v003_shape_only", "canvas": record["canvas"], "pivot": record["pivot"],
              "display_scale": record["display_scale"], "camera_pitch_degrees": 35,
              "orthographic_scale": record["orthographic_scale"], "frames": frames,
              "source_model_manifest_sha256": sha(source), "source_blend_sha256": sha(original_blend),
              "source_script_sha256": sha(Path(__file__)), "blend_path": blend.name,
              "blend_sha256": sha(blend), "status": "technical_unapproved",
              "limits": "static shape study; old morph deltas retained provisionally; no motion acceptance"}
    (output / "render_manifest.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print("PLAYER SHAPE V003 COMPLETE " + str(output), flush=True)


if __name__ == "__main__":
    main()
