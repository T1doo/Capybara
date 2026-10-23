"""Export a small same-source cutout counterpart to the v004 DR sample.

Only build outputs are written. Four foot plates are deformed in 2D at runtime;
five head/scarf replacements handle the out-of-plane pickup. This is not a full
frame sequence relabelled as cutout, nor a production animation component.
"""

import argparse
import hashlib
import json
import sys
import time
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/art"))
from build_player_mesh_v001 import alpha_metadata, configure_camera
from render_player_motion import projected, skin_point


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def body_section(source, name, keep):
    result = source.copy()
    result.data = source.data.copy()
    bpy.context.collection.objects.link(result)
    result.name = name
    result.shape_key_clear()
    mesh = bmesh.new()
    mesh.from_mesh(result.data)
    discard = [face for face in mesh.faces if not keep(face.calc_center_median().x)]
    bmesh.ops.delete(mesh, geom=discard, context="FACES")
    mesh.to_mesh(result.data)
    mesh.free()
    result.data.update()
    result.visible_shadow = False
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--model-dir", type=Path, required=True)
    parser.add_argument("--motion-bank", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    model, bank, output = args.model_dir.resolve(), args.motion_bank.resolve(), args.output_dir.resolve()
    for path in (model, bank, output):
        if (ROOT / "build") not in path.parents:
            raise ValueError("Use inputs/NEW output strictly below repository build")
    if output.exists():
        raise ValueError("Refusing to overwrite a previous sample")
    source = json.loads((model / "render_manifest.json").read_text())
    motion = json.loads(bank.read_text())
    blend = model / "player_paint_projection_study.blend"
    if sha(blend) != source["blend_sha256"] or sha(blend) != motion["model_sha256"]:
        raise ValueError("A/B must use exactly the same packed model/material source")
    output.mkdir(parents=True)
    (output / "exporter_source.py").write_bytes(Path(__file__).read_bytes())
    started = time.monotonic()
    bpy.ops.wm.open_mainfile(filepath=str(blend))
    scene, camera = bpy.context.scene, bpy.context.scene.camera
    root = bpy.data.objects["Character_v002__X_forward_Y_anatomical_left_Z_up"]
    configure_camera({"root": root}, camera, root.rotation_euler.z * 180 / 3.141592653589793,
                     camera.data.ortho_scale * 640 / 512)
    scene.render.resolution_x = scene.render.resolution_y = 640
    scene.render.threads = 8
    body = bpy.data.objects["Continuous_back_shoulders_and_long_blunt_head"]
    torso = body_section(body, "Cutout_torso_overlap_to_0p28", lambda x: x < .28)
    head = body_section(body, "Cutout_head_overlap_from_minus_0p08", lambda x: x > -.08)
    body_dip = body.shape_key_add(name="Cutout_v004_occlusion_dip")
    for vertex, point in zip(body.data.vertices, body_dip.data):
        point.co = skin_point(vertex.co, .28)
    features = list(bpy.data.objects["Head_features_control"].children_recursive)
    scarf = list(bpy.data.objects["Scarf__knot_anatomical_left"].children_recursive)
    bag = list(bpy.data.objects["Leaf_satchel__anatomical_right"].children_recursive)
    renderables = [o for o in root.children_recursive if o.type in {"MESH", "CURVE"}]
    holdout = bpy.data.materials.new("Cutout_original_body_occlusion_only")
    holdout.use_nodes = True
    nodes, links = holdout.node_tree.nodes, holdout.node_tree.links
    links.new(nodes.new("ShaderNodeHoldout").outputs[0], nodes.get("Material Output").inputs["Surface"])
    original_materials = list(body.data.materials)
    original_meshes = {o: [v.co.copy() for v in o.data.vertices] for o in [head] + features + scarf if o.type == "MESH"}
    original_curves = {o: [(p, p.co.copy(), p.handle_left.copy(), p.handle_right.copy())
                          for spline in o.data.splines for p in spline.bezier_points]
                       for o in features + scarf if o.type == "CURVE"}
    feet, groups = [], []
    for label in ("Fore_Left", "Fore_Right", "Hind_Left", "Hind_Right"):
        control = bpy.data.objects[label + "_foot_control"]
        group = [bpy.data.objects[label + "_tapered_short_leg"]] + list(control.children_recursive)
        hips = projected(camera, root.matrix_world @ Vector((control.location.x, control.location.y, .48)), 640)
        sole = projected(camera, control.matrix_world @ Vector((.16, 0, .005)), 640)
        feet.append({"id": label, "hip": list(hips), "sole": list(sole)})
        # Full hidden foot pixels are needed when a swing reveals the far limb.
        # These plates are drawn below the torso, which clips them in 2D.
        groups.append((label, group, [0.0], False))
    groups += [("torso", [torso], [0.0], False),
               ("head", [head] + features, [0, .25, .5, .75, 1], False),
               ("scarf", scarf, [0, .25, .5, .75, 1], True), ("bag", bag, [0.0], True)]
    entries = []
    for label, group, dips, occlude in groups:
        group = [o for o in group if o.type in {"MESH", "CURVE"}]
        for dip in dips:
            body_dip.value = dip
            for obj, vertices in original_meshes.items():
                matrix = root.matrix_world.inverted() @ obj.matrix_world
                inv = matrix.inverted()
                for vertex, rest in zip(obj.data.vertices, vertices):
                    vertex.co = inv @ skin_point(matrix @ rest, dip * .28)
                obj.data.update()
            for obj, points in original_curves.items():
                matrix = root.matrix_world.inverted() @ obj.matrix_world
                inv = matrix.inverted()
                for point, co, left, right in points:
                    point.co = inv @ skin_point(matrix @ co, dip * .28)
                    point.handle_left = inv @ skin_point(matrix @ left, dip * .28)
                    point.handle_right = inv @ skin_point(matrix @ right, dip * .28)
            # Cloth is clipped by the actual posed body. Torso/head overlap and
            # full foot plates preserve pixels that motion may later reveal.
            for obj in renderables:
                obj.visible_camera = obj in group
            body.visible_camera = occlude
            body.data.materials.clear()
            for material in original_materials:
                body.data.materials.append(holdout if occlude else material)
            bpy.context.view_layer.update()
            path = output / (label + "_%02d.png" % round(dip * 4))
            scene.render.filepath = str(path)
            bpy.ops.render.render(write_still=True)
            alpha = alpha_metadata(path)
            if alpha["edge_alpha_pixels"] or alpha["alpha_height"] == 0:
                raise ValueError("Invalid cutout plate: " + path.name)
            entries.append({"layer": label, "dip": dip, "path": path.name, "sha256": sha(path), **alpha})
            print("CUTOUT PLATE " + path.name, flush=True)
    result = {"status": "technical_unapproved", "direction": "down_right", "canvas": [640, 640],
              "pivot": [320, 480], "display_scale": .5, "camera_pitch_degrees": 35,
              "model_sha256": sha(blend), "b_manifest_sha256": sha(bank), "exporter_sha256": sha(Path(__file__)),
              "helper_sha256": sha(ROOT / "tools/art/render_player_motion.py"), "feet": feet, "layers": entries,
              "draw_order": ["Hind_Left", "Fore_Left", "Hind_Right", "Fore_Right", "torso", "head", "scarf", "bag"],
              "method": "four 2D foot plates + torso + fixed bag + five head/scarf pickup replacements; same v004 source",
              "limitations": "DR walk/pickup only; hidden layer/overlap and replacement transitions require visual QA; no route approval",
              "elapsed_seconds": time.monotonic() - started, "blender": bpy.app.version_string}
    (output / "layer_manifest.json").write_text(json.dumps(result, indent=2) + "\n")
    print("CUTOUT LAYERS COMPLETE: %d plates" % len(entries), flush=True)


if __name__ == "__main__":
    main()
