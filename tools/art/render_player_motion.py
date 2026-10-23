"""Render a bounded v004 pose bank from real Player motion; keep source art untouched."""

import argparse
import hashlib
import json
import math
from pathlib import Path
import sys
import time

import bpy
from mathutils import Matrix, Vector
from bpy_extras.object_utils import world_to_camera_view

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/art"))
from player_motion_plan import plan, REST
from build_player_mesh_v001 import alpha_metadata, configure_camera
from player_mesh_v002_motion import screen_yaw


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def projected(camera, point, size):
    uv = world_to_camera_view(bpy.context.scene, camera, Vector(point))
    return Vector((uv.x * size, (1 - uv.y) * size))


def skin_point(point, angle):
    weight = max(0, min(1, (point.x - .1) / .32))
    pivot = Vector((.1, 0, .72))
    return point.lerp(Matrix.Rotation(angle, 3, "Y") @ (point - pivot) + pivot, weight)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--model-dir", type=Path, required=True)
    parser.add_argument("--motion", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--plan-only", action="store_true")
    parser.add_argument("--preview", action="store_true")
    parser.add_argument("--stills", action="store_true")
    parser.add_argument("--coverage", action="store_true")
    parser.add_argument("--first-ticks", type=int, default=3840)
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    if not 1 <= args.first_ticks <= 3840 or (args.first_ticks != 3840 and (args.preview or args.stills or args.coverage)):
        raise ValueError("A bounded motion cost sample cannot mix with static/coverage modes")
    model, motion, output = args.model_dir.resolve(), args.motion.resolve(), args.output_dir.resolve()
    for source in (model, motion, output):
        if (ROOT / "build") not in source.parents:
            raise ValueError("All run inputs/outputs must remain in build")
    if output.exists():
        raise ValueError("Output already exists")
    source_manifest = json.loads((model / "render_manifest.json").read_text())
    blend = model / "player_paint_projection_study.blend"
    if sha(blend) != source_manifest["blend_sha256"]:
        raise ValueError("Model blend changed")
    record = json.loads(motion.read_text())
    if not record["passed"] or len(record["rows"]) != 3840 or record["speed"] != 240:
        raise ValueError("Expected actual 64-second 240px/s motion record")
    output.mkdir(parents=True)
    started = time.monotonic()
    bpy.ops.wm.open_mainfile(filepath=str(blend))
    scene, camera = bpy.context.scene, bpy.context.scene.camera
    size, display_scale = 640, .5
    old_scale = camera.data.ortho_scale
    root = bpy.data.objects["Character_v002__X_forward_Y_anatomical_left_Z_up"]
    configure_camera({"root": root}, camera, math.degrees(root.rotation_euler.z), old_scale * size / 512)
    scene.render.resolution_x = scene.render.resolution_y = size
    scene.render.threads = 8
    if args.coverage:
        for material in bpy.data.materials:
            if not material.use_nodes:
                continue
            nodes, links = material.node_tree.nodes, material.node_tree.links
            out = nodes.get("Material Output")
            if out is None or not out.inputs["Surface"].links:
                continue
            painted = out.inputs["Surface"].links[0].from_node
            diagnostic = nodes.new("ShaderNodeEmission")
            if any(token in material.name for token in ("Fur__", "Short_limb", "Lake_teal", "Teal_cloth", "Olive_lily")) and painted.type == "MIX_SHADER":
                color = nodes.new("ShaderNodeMixRGB")
                color.inputs[1].default_value = (1, 0, 0, 1)
                color.inputs[2].default_value = (0, 1, 0, 1)
                links.new(painted.inputs[0].links[0].from_socket, color.inputs[0])
                links.new(color.outputs[0], diagnostic.inputs["Color"])
            else:
                diagnostic.inputs["Color"].default_value = (.05, .15, 1, 1)
            links.new(diagnostic.outputs[0], out.inputs["Surface"])
    origin = projected(camera, (0, 0, 0), size)
    x = (projected(camera, (1, 0, 0), size) - origin) * display_scale
    y = (projected(camera, (0, 1, 0), size) - origin) * display_scale
    height_scale = -(projected(camera, (0, 0, 1), size) - origin).y * display_scale
    data = plan(record, [[x.x, y.x], [x.y, y.y]], height_scale)
    directions = ["down_right", "down_left", "up_right", "up_left"]
    if args.stills:
        data["poses"] = [{"yaw": math.radians(screen_yaw(direction)), "feet": [[*rest, 0, 0] for rest in REST],
                          "dip": 0, "breath": 0} for direction in directions]
        data["timeline"] = []
    data.update({"canvas": [size, size], "pivot": [320, 480], "display_scale": display_scale,
                 "asset_version": "player_motion_v004_technical_unapproved", "fps": 60,
                 "motion_sha256": sha(motion), "model_sha256": sha(blend),
                 "planner_sha256": sha(ROOT / "tools/art/player_motion_plan.py"),
                 "renderer_sha256": sha(Path(__file__)), "frames": []})
    (output / "pose_plan.json").write_text(json.dumps(data, separators=(",", ":")))
    (output / "renderer_source.py").write_bytes(Path(__file__).read_bytes())
    (output / "planner_source.py").write_bytes((ROOT / "tools/art/player_motion_plan.py").read_bytes())
    print("MOTION PLAN: %d unique poses / 3840 real physics ticks; max reach %.2fpx" % (len(data["poses"]), data["max_ankle_reach_px"]), flush=True)
    if args.plan_only:
        return
    body = bpy.data.objects["Continuous_back_shoulders_and_long_blunt_head"]
    dip = body.shape_key_add(name="V004_sample_pickup")
    for vertex, target in zip(body.data.vertices, dip.data):
        target.co = skin_point(vertex.co, .28)
    skins, curve_skins = [], []
    for parent_name in ("Head_features_control", "Scarf__knot_anatomical_left"):
        for obj in bpy.data.objects[parent_name].children_recursive:
            matrix = root.matrix_world.inverted() @ obj.matrix_world
            if obj.type == "MESH":
                skins.append((obj, matrix, matrix.inverted(), [v.co.copy() for v in obj.data.vertices]))
            elif obj.type == "CURVE":
                points = [(point, point.co.copy(), point.handle_left.copy(), point.handle_right.copy())
                          for spline in obj.data.splines for point in spline.bezier_points]
                curve_skins.append((obj, matrix, matrix.inverted(), points))
    feet = []
    for label in ("Fore_Left", "Fore_Right", "Hind_Left", "Hind_Right"):
        leg = bpy.data.objects[label + "_tapered_short_leg"]
        feet.append((bpy.data.objects[label + "_foot_control"], leg,
                     [v.co.copy() for v in leg.data.vertices], max(v.co.z for v in leg.data.vertices)))
    frames_dir = output / "frames"
    frames_dir.mkdir()
    indices = range(len(data["poses"]))
    if args.first_ticks != 3840:
        indices = sorted({row["pose"] for row in data["timeline"][:args.first_ticks]})
    if args.preview:
        indices = sorted({0, max(range(len(data["poses"])), key=lambda i: data["poses"][i]["dip"]),
                          max(range(len(data["poses"])), key=lambda i: abs(data["poses"][i]["yaw"])),
                          max(range(len(data["poses"])), key=lambda i: max(math.hypot(foot[0]-REST[j][0], foot[1]-REST[j][1]) for j, foot in enumerate(data["poses"][i]["feet"])))})
    for index in indices:
        pose = data["poses"][index]
        root.rotation_euler.z = pose["yaw"]
        dip.value = pose["dip"]
        body.data.shape_keys.key_blocks["Idle_breath"].value = pose["breath"]
        for obj, matrix, inv_matrix, vertices in skins:
            for vertex, rest in zip(obj.data.vertices, vertices):
                vertex.co = inv_matrix @ skin_point(matrix @ rest, pose["dip"] * .28)
            obj.data.update()
        for obj, matrix, inv_matrix, points in curve_skins:
            for point, co, left, right in points:
                point.co = inv_matrix @ skin_point(matrix @ co, pose["dip"] * .28)
                point.handle_left = inv_matrix @ skin_point(matrix @ left, pose["dip"] * .28)
                point.handle_right = inv_matrix @ skin_point(matrix @ right, pose["dip"] * .28)
        for foot_index, (control, leg, vertices, top) in enumerate(feet):
            location = Vector(pose["feet"][foot_index][:3])
            control.location = location
            control.rotation_euler.z = pose["feet"][foot_index][3]
            offset = location - Vector((*REST[foot_index], 0))
            for vertex, rest in zip(leg.data.vertices, vertices):
                weight = max(0, min(1, (top - rest.z) / (top - .075)))
                vertex.co = rest + offset * weight
            leg.data.update()
        bpy.context.view_layer.update()
        path = frames_dir / ("pose_%04d.png" % index)
        scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        alpha = alpha_metadata(path)
        if alpha["edge_alpha_pixels"]:
            raise ValueError("Pose clips unchanged-scale padded canvas: " + str(index))
        markers = []
        for control, _leg, _vertices, _top in feet:
            p = projected(camera, control.matrix_world @ Vector((.16, 0, .005)), size)
            markers.append([p.x, p.y])
        data["frames"].append({"pose_index": index, "path": "frames/" + path.name, "sha256": sha(path), "soles": markers,
                               "direction": directions[index] if args.stills else "motion_sample",
                               "pose": "standing_v004" if args.stills else "motion_%04d" % index, **alpha})
        if index % 20 == 0:
            print("MOTION RENDER %d/%d" % (index, len(data["poses"])), flush=True)
            (output / "render_progress.json").write_text(json.dumps({"done": index + 1, "total": len(data["poses"])}))
    data["complete"] = not args.preview and not args.stills and not args.coverage and args.first_ticks == 3840
    data["rendered_ticks"] = args.first_ticks
    data["subset_complete"] = args.first_ticks < 3840
    data["elapsed_seconds"] = time.monotonic() - started
    data["stills_complete"] = args.stills
    data["coverage_diagnostic"] = args.coverage
    (output / "motion_manifest.json").write_text(json.dumps(data, separators=(",", ":")))
    print("MOTION BANK COMPLETE: " + str(output), flush=True)


if __name__ == "__main__":
    main()
