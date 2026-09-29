"""Freeze one paintover projection into rest UVs on an original editable character.

Front visibility weights reject back-facing/occluded surfaces. The original mesh and
unpainted material remain the fallback; this is a one-view study, not approved art.
"""

import argparse
import hashlib
import json
from pathlib import Path
import sys

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/art"))
from build_player_mesh_v001 import alpha_metadata


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def project_rest_uvs(camera) -> dict:
    scene = bpy.context.scene
    bpy.context.view_layer.update()
    depsgraph = bpy.context.evaluated_depsgraph_get()
    toward_camera = camera.rotation_euler.to_matrix() @ Vector((0, 0, 1))
    counts = {"meshes": 0, "vertices": 0, "painted_vertices": 0}
    for obj in scene.objects:
        if obj.type != "MESH":
            continue
        uv_map = obj.data.uv_layers.new(name="PaintRestProjection")
        weight = obj.data.attributes.new(name="PaintVisibility", type="FLOAT", domain="POINT")
        normal_matrix = obj.matrix_world.to_3x3().inverted().transposed()
        uvs = []
        for vertex in obj.data.vertices:
            world_point = obj.matrix_world @ vertex.co
            uv = world_to_camera_view(scene, camera, world_point)
            uvs.append((uv.x, uv.y))
            normal = (normal_matrix @ vertex.normal).normalized()
            facing = normal.dot(toward_camera)
            hit = scene.ray_cast(depsgraph, world_point + toward_camera * 10,
                                 -toward_camera, distance=20)
            visible = hit[0] and hit[4].original == obj.original
            amount = max(0, min(1, (facing - .08) / .40)) if visible else 0
            weight.data[vertex.index].value = amount
            counts["vertices"] += 1
            counts["painted_vertices"] += int(amount > 0)
        for loop in obj.data.loops:
            uv_map.data[loop.index].uv = uvs[loop.vertex_index]
        obj.data.update()
        counts["meshes"] += 1
    return counts


def install_paint(image) -> None:
    for material in list(bpy.data.materials):
        if not material.use_nodes:
            continue
        nodes, links = material.node_tree.nodes, material.node_tree.links
        output = nodes.get("Material Output")
        if output is None or not output.inputs["Surface"].links:
            continue
        original = output.inputs["Surface"].links[0].from_socket
        uv = nodes.new("ShaderNodeUVMap")
        uv.uv_map = "PaintRestProjection"
        texture = nodes.new("ShaderNodeTexImage")
        texture.image, texture.extension = image, "CLIP"
        links.new(uv.outputs[0], texture.inputs["Vector"])
        visibility = nodes.new("ShaderNodeAttribute")
        visibility.attribute_name = "PaintVisibility"
        mask = nodes.new("ShaderNodeMath")
        mask.operation = "MULTIPLY"
        links.new(visibility.outputs["Fac"], mask.inputs[0])
        links.new(texture.outputs["Alpha"], mask.inputs[1])
        painted = nodes.new("ShaderNodeEmission")
        links.new(texture.outputs["Color"], painted.inputs["Color"])
        mix = nodes.new("ShaderNodeMixShader")
        links.new(mask.outputs[0], mix.inputs[0])
        links.new(original, mix.inputs[1])
        links.new(painted.outputs[0], mix.inputs[2])
        links.new(mix.outputs[0], output.inputs["Surface"])


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model-manifest", type=Path, required=True)
    parser.add_argument("--paintover", type=Path, required=True)
    parser.add_argument("--paintover-sha256", required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    source, paint, output = [p.resolve() for p in (args.model_manifest, args.paintover, args.output_dir)]
    if (ROOT / "build") not in source.parents or (ROOT / "build") not in output.parents or output.exists():
        raise ValueError("Use model evidence and a new output directory strictly below build")
    if (ROOT / "art") not in paint.parents or sha(paint) != args.paintover_sha256:
        raise ValueError("Only the explicitly hashed original project paintover is allowed")
    record = json.loads(source.read_text(encoding="utf-8"))
    source_blend = (source.parent / record["blend_path"]).resolve()
    if source.parent not in source_blend.parents or sha(source_blend) != record["blend_sha256"]:
        raise ValueError("Source model hash/path mismatch")
    output.mkdir(parents=True)
    bpy.ops.wm.open_mainfile(filepath=str(source_blend))
    scene = bpy.context.scene
    paint_image = bpy.data.images.load(str(paint), check_existing=False)
    paint_image.pack()
    coverage = project_rest_uvs(scene.camera)
    install_paint(paint_image)
    body = bpy.data.objects["Continuous_back_shoulders_and_long_blunt_head"]
    frames = []
    for label, breath in (("paint_rest", 0.0), ("paint_breath", 1.0)):
        body.data.shape_keys.key_blocks["Idle_breath"].value = breath
        bpy.context.view_layer.update()
        path = output / (label + ".png")
        scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        frames.append({"direction": "down_right", "pose": label, "path": path.name,
                       "sha256": sha(path), **alpha_metadata(path)})
    body.data.shape_keys.key_blocks["Idle_breath"].value = 0
    blend = output / "player_paint_projection_study.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(blend))
    (output / "source_snapshot.py").write_bytes(Path(__file__).read_bytes())
    result = {"route": "blender_v003_rest_uv_paint", "canvas": record["canvas"],
              "pivot": record["pivot"], "display_scale": record["display_scale"], "frames": frames,
              "source_model_manifest_sha256": sha(source), "source_blend_sha256": sha(source_blend),
              "paintover_sha256": sha(paint), "source_script_sha256": sha(Path(__file__)),
              "coverage": coverage, "blend_sha256": sha(blend), "status": "technical_unapproved",
              "limits": "one front view; rest-UV visibility is fixed, hidden surfaces unpainted; no turn/walk/quality acceptance"}
    (output / "render_manifest.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print("PAINT PROJECTION STUDY COMPLETE " + str(output), flush=True)


if __name__ == "__main__":
    main()
