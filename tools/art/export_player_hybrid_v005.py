"""Bounded turn plates + independent feet from the preserved v004 source.

No trajectory or animation frame bank is consumed. Upper-body turn/pickup plates
preserve native shoulder/cloth occlusion; four complete foot plates are animated
as 2D meshes at runtime. Outputs remain unapproved, strictly below build.
"""

import argparse
import hashlib
import json
import math
from pathlib import Path
import sys
import time

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/art"))
from build_player_mesh_v001 import alpha_metadata, configure_camera
from render_player_motion import projected, skin_point

FOOT_IDS = ["Fore_Left", "Fore_Right", "Hind_Left", "Hind_Right"]


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--model-dir", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--heading-count", type=int, choices=[16, 32], default=16)
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    model, output = args.model_dir.resolve(), args.output_dir.resolve()
    if any((ROOT / "build") not in p.parents for p in (model, output)) or output.exists():
        raise ValueError("Use a preserved model and a NEW output directory strictly in build")
    source = json.loads((model / "render_manifest.json").read_text())
    blend = model / "player_paint_projection_study.blend"
    if sha(blend) != source["blend_sha256"] or source["color_pipeline"]["output_view"] != "Standard":
        raise ValueError("Expected preserved Standard/sRGB v004 packed model")
    output.mkdir(parents=True)
    (output / "exporter_source.py").write_bytes(Path(__file__).read_bytes())
    started = time.monotonic()
    bpy.ops.wm.open_mainfile(filepath=str(blend))
    scene, camera = bpy.context.scene, bpy.context.scene.camera
    root = bpy.data.objects["Character_v002__X_forward_Y_anatomical_left_Z_up"]
    reference_yaw = root.rotation_euler.z
    scale = camera.data.ortho_scale * 640 / 512
    configure_camera({"root": root}, camera, math.degrees(reference_yaw), scale)
    scene.render.resolution_x = scene.render.resolution_y = 640
    scene.render.threads = 8
    renderables = [o for o in root.children_recursive if o.type in {"MESH", "CURVE"}]
    foot_groups = []
    for label in FOOT_IDS:
        control = bpy.data.objects[label + "_foot_control"]
        foot_groups.append([bpy.data.objects[label + "_tapered_short_leg"]] + list(control.children_recursive))
    foot_objects = {o for group in foot_groups for o in group}
    upper = [o for o in renderables if o not in foot_objects]
    body = bpy.data.objects["Continuous_back_shoulders_and_long_blunt_head"]
    dip_key = body.shape_key_add(name="V005_pickup_same_v004_skin")
    for vertex, point in zip(body.data.vertices, dip_key.data):
        point.co = skin_point(vertex.co, .28)
    detail_objects = list(bpy.data.objects["Head_features_control"].children_recursive)
    detail_objects += list(bpy.data.objects["Scarf__knot_anatomical_left"].children_recursive)
    mesh_rest = {o: [v.co.copy() for v in o.data.vertices] for o in detail_objects if o.type == "MESH"}
    curve_rest = {o: [(p, p.co.copy(), p.handle_left.copy(), p.handle_right.copy())
                      for spline in o.data.splines for p in spline.bezier_points]
                  for o in detail_objects if o.type == "CURVE"}

    def set_dip(value):
        dip_key.value = value
        for obj, vertices in mesh_rest.items():
            matrix = root.matrix_world.inverted() @ obj.matrix_world
            inv = matrix.inverted()
            for vertex, rest in zip(obj.data.vertices, vertices):
                vertex.co = inv @ skin_point(matrix @ rest, value * .28)
            obj.data.update()
        for obj, points in curve_rest.items():
            matrix = root.matrix_world.inverted() @ obj.matrix_world
            inv = matrix.inverted()
            for point, co, left, right in points:
                point.co = inv @ skin_point(matrix @ co, value * .28)
                point.handle_left = inv @ skin_point(matrix @ left, value * .28)
                point.handle_right = inv @ skin_point(matrix @ right, value * .28)
        bpy.context.view_layer.update()

    def render(name, objects):
        for obj in renderables:
            obj.visible_camera = obj in objects
        path = output / (name + ".png")
        scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        alpha = alpha_metadata(path)
        if alpha["edge_alpha_pixels"]:
            raise ValueError("Clipped native plate: " + name)
        print("HYBRID PLATE " + name, flush=True)
        return {"path": path.name, "sha256": sha(path), **alpha}

    origin = projected(camera, (0, 0, 0), 640)
    x = (projected(camera, (1, 0, 0), 640) - origin) * .5
    y = (projected(camera, (0, 1, 0), 640) - origin) * .5
    height = -(projected(camera, (0, 0, 1), 640) - origin).y * .5
    # Exact screen-facing headings matter under the 35-degree projection: equal
    # world-input angles are not equal model-yaw angles. Insert only turn inbetweens.
    directions = {"down_right": (1, 1), "right": (1, 0), "up_right": (1, -1), "up": (0, -1),
                  "up_left": (-1, -1), "left": (-1, 0), "down_left": (-1, 1), "down": (0, 1)}
    determinant = x.x * y.y - y.x * x.y
    exact = []
    for label, (dx, dy) in directions.items():
        angle = math.atan2((-x.y * dx + x.x * dy) / determinant, (y.y * dx - y.x * dy) / determinant)
        offset = (angle - reference_yaw) % math.tau
        if min(offset, math.tau - offset) < 1e-5:
            offset = 0.0
        exact.append((offset, label))
    exact.sort()
    samples = []
    for i, (offset, label) in enumerate(exact):
        following = exact[i + 1][0] if i + 1 < len(exact) else math.tau
        for part in range(args.heading_count // 8):
            samples.append((reference_yaw + offset + (following - offset) * part / (args.heading_count // 8),
                            label if part == 0 else "turn_inbetween"))
    headings, references = [], []
    for index, (yaw, screen_facing) in enumerate(samples):
        configure_camera({"root": root}, camera, math.degrees(yaw), scale)
        set_dip(0)
        upper_plates = [render("upper_%02d_0" % index, upper)]
        # This batch proves turning/locomotion; pickup replacements remain DR-only.
        if index == 0:
            for key, value in enumerate((.25, .5, .75, 1), start=1):
                set_dip(value)
                upper_plates.append(render("upper_%02d_%d" % (index, key), upper))
            set_dip(0)
        feet = []
        for foot_id, group in zip(FOOT_IDS, foot_groups):
            control = bpy.data.objects[foot_id + "_foot_control"]
            hip = projected(camera, root.matrix_world @ Vector((control.location.x, control.location.y, .48)), 640)
            sole = projected(camera, control.matrix_world @ Vector((.16, 0, .005)), 640)
            feet.append({"id": foot_id, "hip": list(hip), "sole": list(sole),
                         "image": render("%s_%02d" % (foot_id, index), group)})
        headings.append({"index": index, "yaw": yaw, "screen_facing": screen_facing, "upper": upper_plates, "feet": feet})
        if index % (args.heading_count // 4) == 0:
            references.append({"heading": index, "image": render("native_reference_%02d" % index, renderables)})
        (output / "progress.json").write_text(json.dumps({"headings_done": index + 1, "headings_total": args.heading_count}))
    result = {"schema": 1, "status": "technical_unapproved", "complete": True,
              "model_sha256": sha(blend), "canvas": [640, 640], "pivot": [320, 480], "display_scale": .5,
              "reference_yaw": reference_yaw, "projection": [[x.x, y.x], [x.y, y.y]], "height_scale": height,
              "headings": headings, "native_references": references,
              "method": "bounded upper-body turn plates + four independent live 2D foot meshes; no trajectory input",
              "heading_sampling": "eight exact screen facings plus bounded turn inbetweens; not uniform model yaw",
              "limits": "candidate; discrete turn plates, approximate limb skin/shadows; five DR-only pickup replacements; no approval",
              "exporter_sha256": sha(Path(__file__)), "skin_helper_sha256": sha(ROOT / "tools/art/render_player_motion.py"),
              "blender": bpy.app.version_string, "samples": scene.cycles.samples, "threads": 8,
              "elapsed_seconds": time.monotonic() - started}
    (output / "hybrid_manifest.json").write_text(json.dumps(result, indent=2) + "\n")
    print("HYBRID SOURCE COMPLETE: %d headings" % len(headings), flush=True)


if __name__ == "__main__":
    main()
