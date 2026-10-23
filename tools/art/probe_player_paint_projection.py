"""Freeze one paintover projection into rest UVs on an original editable character.

Front visibility weights reject back-facing/occluded surfaces. The original mesh and
unpainted material remain the fallback; this is a one-view study, not approved art.
"""

import argparse
import hashlib
import json
import math
from pathlib import Path
import sys

import bpy

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/art"))
from build_player_mesh_v001 import alpha_metadata
from player_paint_surface import bake_render_surfaces, projection_sample
from player_mesh_v002_motion import screen_yaw


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def project_rest_uvs(camera, suffix: str = "", uv_offset: tuple = (0.0, 0.0)) -> dict:
    scene = bpy.context.scene
    bpy.context.view_layer.update()
    depsgraph = bpy.context.evaluated_depsgraph_get()
    counts = {"meshes": 0, "vertices": 0, "painted_vertices": 0, "reasons": {}}
    for obj in scene.objects:
        if obj.type != "MESH":
            continue
        uv_map = obj.data.uv_layers.new(name="PaintRestProjection" + suffix)
        weight = obj.data.attributes.new(name="PaintVisibility" + suffix, type="FLOAT", domain="POINT")
        normal_matrix = obj.matrix_world.to_3x3().inverted().transposed()
        uvs = []
        for vertex in obj.data.vertices:
            world_point = obj.matrix_world @ vertex.co
            normal = (normal_matrix @ vertex.normal).normalized()
            sample = projection_sample(obj, world_point, normal, camera, depsgraph)
            uvs.append((sample["uv"][0] + uv_offset[0], sample["uv"][1] + uv_offset[1]))
            amount = sample["weight"]
            reason = sample["reason"]
            counts["reasons"][reason] = counts["reasons"].get(reason, 0) + 1
            weight.data[vertex.index].value = amount
            counts["vertices"] += 1
            counts["painted_vertices"] += int(amount > 0)
        for loop in obj.data.loops:
            uv_map.data[loop.index].uv = uvs[loop.vertex_index]
        obj.data.update()
        counts["meshes"] += 1
    return counts


def install_paint(projections: list) -> None:
    for material in list(bpy.data.materials):
        if not material.use_nodes:
            continue
        nodes, links = material.node_tree.nodes, material.node_tree.links
        output = nodes.get("Material Output")
        if output is None or not output.inputs["Surface"].links:
            continue
        original = output.inputs["Surface"].links[0].from_socket
        color_sum, weight_sum = None, None
        for projection in projections:
            uv = nodes.new("ShaderNodeUVMap")
            uv.uv_map = "PaintRestProjection" + projection["suffix"]
            texture = nodes.new("ShaderNodeTexImage")
            texture.image, texture.extension = projection["image"], "CLIP"
            links.new(uv.outputs[0], texture.inputs["Vector"])
            visibility = nodes.new("ShaderNodeAttribute")
            visibility.attribute_name = "PaintVisibility" + projection["suffix"]
            mask = nodes.new("ShaderNodeMath")
            mask.operation = "MULTIPLY"
            links.new(visibility.outputs["Fac"], mask.inputs[0])
            links.new(texture.outputs["Alpha"], mask.inputs[1])
            weighted = nodes.new("ShaderNodeVectorMath")
            weighted.operation = "SCALE"
            links.new(texture.outputs["Color"], weighted.inputs[0])
            links.new(mask.outputs[0], weighted.inputs[3])
            if color_sum is None:
                color_sum, weight_sum = weighted.outputs[0], mask.outputs[0]
            else:
                colors = nodes.new("ShaderNodeVectorMath")
                colors.operation = "ADD"
                links.new(color_sum, colors.inputs[0])
                links.new(weighted.outputs[0], colors.inputs[1])
                weights = nodes.new("ShaderNodeMath")
                weights.operation = "ADD"
                links.new(weight_sum, weights.inputs[0])
                links.new(mask.outputs[0], weights.inputs[1])
                color_sum, weight_sum = colors.outputs[0], weights.outputs[0]
        denominator = nodes.new("ShaderNodeMath")
        denominator.operation = "MAXIMUM"
        links.new(weight_sum, denominator.inputs[0])
        denominator.inputs[1].default_value = 1e-6
        inverse = nodes.new("ShaderNodeMath")
        inverse.operation = "DIVIDE"
        inverse.inputs[0].default_value = 1
        links.new(denominator.outputs[0], inverse.inputs[1])
        normalized = nodes.new("ShaderNodeVectorMath")
        normalized.operation = "SCALE"
        links.new(color_sum, normalized.inputs[0])
        links.new(inverse.outputs[0], normalized.inputs[3])
        painted = nodes.new("ShaderNodeEmission")
        links.new(normalized.outputs[0], painted.inputs["Color"])
        mix = nodes.new("ShaderNodeMixShader")
        coverage = nodes.new("ShaderNodeMath")
        coverage.operation = "MINIMUM"
        coverage.inputs[1].default_value = 1
        links.new(weight_sum, coverage.inputs[0])
        links.new(coverage.outputs[0], mix.inputs[0])
        links.new(original, mix.inputs[1])
        links.new(painted.outputs[0], mix.inputs[2])
        links.new(mix.outputs[0], output.inputs["Surface"])


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model-manifest", type=Path, required=True)
    parser.add_argument("--paintover", type=Path, required=True)
    parser.add_argument("--paintover-sha256", required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--stress-views", action="store_true")
    parser.add_argument("--rear-paintover", type=Path)
    parser.add_argument("--rear-sha256")
    parser.add_argument("--rear-uv-offset", type=float, nargs=2, default=(0.0, 0.0))
    parser.add_argument("--view-transform", choices=("AgX", "Standard"), default="AgX")
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    source, paint, output = [p.resolve() for p in (args.model_manifest, args.paintover, args.output_dir)]
    if (ROOT / "build") not in source.parents or (ROOT / "build") not in output.parents or output.exists():
        raise ValueError("Use model evidence and a new output directory strictly below build")
    if (ROOT / "art") not in paint.parents or sha(paint) != args.paintover_sha256:
        raise ValueError("Only the explicitly hashed original project paintover is allowed")
    rear = args.rear_paintover.resolve() if args.rear_paintover else None
    if rear and ((ROOT / "art") not in rear.parents or sha(rear) != args.rear_sha256):
        raise ValueError("Rear paintover path/hash mismatch")
    if any(abs(value) > .1 for value in args.rear_uv_offset):
        raise ValueError("UV registration must remain a small explicit offset")
    record = json.loads(source.read_text(encoding="utf-8"))
    source_blend = (source.parent / record["blend_path"]).resolve()
    if source.parent not in source_blend.parents or sha(source_blend) != record["blend_sha256"]:
        raise ValueError("Source model hash/path mismatch")
    output.mkdir(parents=True)
    bpy.ops.wm.open_mainfile(filepath=str(source_blend))
    scene = bpy.context.scene
    scene.display_settings.display_device = "sRGB"
    scene.view_settings.view_transform = args.view_transform
    scene.view_settings.look = "None"
    scene.view_settings.exposure, scene.view_settings.gamma = 0, 1
    scene.render.dither_intensity = 0
    paint_image = bpy.data.images.load(str(paint), check_existing=False)
    paint_image.pack()
    surface_bake = bake_render_surfaces()
    character = bpy.data.objects["Character_v002__X_forward_Y_anatomical_left_Z_up"]
    reference_yaw = character.rotation_euler.z
    coverage = {"down_right": project_rest_uvs(scene.camera)}
    projections = [{"image": paint_image, "suffix": ""}]
    if rear:
        rear_image = bpy.data.images.load(str(rear), check_existing=False)
        rear_image.pack()
        character.rotation_euler.z = math.radians(screen_yaw("up_left"))
        bpy.context.view_layer.update()
        coverage["up_left"] = project_rest_uvs(scene.camera, "_rear", tuple(args.rear_uv_offset))
        projections.append({"image": rear_image, "suffix": "_rear"})
        character.rotation_euler.z = reference_yaw
    install_paint(projections)
    body = bpy.data.objects["Continuous_back_shoulders_and_long_blunt_head"]
    poses = [("paint_rest", 0.0, 0, "down_right"), ("paint_breath", 1.0, 0, "down_right")]
    if rear:
        poses += [("view_" + direction, 0.0, screen_yaw(direction) - math.degrees(reference_yaw), direction)
                  for direction in ("down_left", "up_right", "up_left")]
    if args.stress_views:
        poses += [("turn_minus_30", 0.0, -30, "turn_probe"), ("turn_plus_30", 0.0, 30, "turn_probe")]
        if not rear:
            poses += [("rear_180", 0.0, 180, "up_left")]
    frames = []
    for label, breath, yaw_offset, direction in poses:
        body.data.shape_keys.key_blocks["Idle_breath"].value = breath
        character.rotation_euler.z = reference_yaw + math.radians(yaw_offset)
        bpy.context.view_layer.update()
        path = output / (label + ".png")
        scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        frames.append({"direction": direction, "pose": label, "path": path.name,
                       "yaw_offset_degrees": yaw_offset,
                       "sha256": sha(path), **alpha_metadata(path)})
    body.data.shape_keys.key_blocks["Idle_breath"].value = 0
    character.rotation_euler.z = reference_yaw
    blend = output / "player_paint_projection_study.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(blend))
    (output / "source_snapshot.py").write_bytes(Path(__file__).read_bytes())
    (output / "surface_helper_snapshot.py").write_bytes((ROOT / "tools/art/player_paint_surface.py").read_bytes())
    result = {"route": "blender_v003_rest_uv_paint", "canvas": record["canvas"],
              "pivot": record["pivot"], "display_scale": record["display_scale"], "frames": frames,
              "source_model_manifest_sha256": sha(source), "source_blend_sha256": sha(source_blend),
              "paintover_sha256": sha(paint), "source_script_sha256": sha(Path(__file__)),
              "rear_paintover_sha256": sha(rear) if rear else None,
              "rear_uv_offset": list(args.rear_uv_offset),
              "blender_version": bpy.app.version_string,
              "color_pipeline": {"paint_input": "sRGB decoded by Image Texture", "blend": "scene-linear",
                                 "output_view": args.view_transform, "display": "sRGB", "exposure": 0, "gamma": 1},
              "coverage": coverage, "surface_bake": surface_bake,
              "surface_helper_sha256": sha(ROOT / "tools/art/player_paint_surface.py"),
              "blend_sha256": sha(blend), "status": "technical_unapproved",
              "limits": "one/two source views; fixed rest-UV visibility; seam and missing-surface review required; no animation/quality acceptance"}
    (output / "render_manifest.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print("PAINT PROJECTION STUDY COMPLETE " + str(output), flush=True)


if __name__ == "__main__":
    main()
