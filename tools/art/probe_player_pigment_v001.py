"""Apply one registered original pigment candidate to the existing editable model.

This build-only comparison keeps geometry/camera/pose fixed and packs the texture into
a new study .blend. It does not approve art or modify the original v002 sources.
"""

import argparse
import hashlib
import json
from pathlib import Path
import sys

import bpy

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/art"))
from build_player_mesh_v001 import alpha_metadata


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model-manifest", type=Path, required=True)
    parser.add_argument("--candidate-manifest", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--paint-scale", type=float, default=.65)
    parser.add_argument("--soft-weight", type=float, default=.25)
    parser.add_argument("--full-weight", type=float, default=.45)
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    if not .1 <= args.paint_scale <= 2 or not 0 <= args.soft_weight < args.full_weight <= 1:
        raise ValueError("Invalid pigment scale or comparison weights")
    model_path, record_path, output = [path.resolve() for path in
                                      (args.model_manifest, args.candidate_manifest, args.output_dir)]
    if (ROOT / "build") not in model_path.parents or (ROOT / "build") not in output.parents or output.exists():
        raise ValueError("Use model evidence and a NEW output directory strictly in build")
    if (ROOT / "art/candidates") not in record_path.parents:
        raise ValueError("Use a registered candidate manifest")
    model = json.loads(model_path.read_text(encoding="utf-8"))
    record = json.loads(record_path.read_text(encoding="utf-8"))
    texture_path = (ROOT / record["candidate_path"]).resolve()
    blend_path = (model_path.parent / model["blend_path"]).resolve()
    if (ROOT / "art/candidates") not in texture_path.parents or model_path.parent not in blend_path.parents:
        raise ValueError("Source path escaped registered location")
    if sha(texture_path) != record["sha256"] or sha(blend_path) != model["blend_sha256"]:
        raise ValueError("Source hash changed")
    if record["rights_status"] != "clean_text_only" or record["game_path"] or record["release_approved"]:
        raise ValueError("Expected unapproved clean text-only material with no game path")
    output.mkdir(parents=True)
    bpy.ops.wm.open_mainfile(filepath=str(blend_path))
    scene = bpy.context.scene
    texture = bpy.data.images.load(str(texture_path), check_existing=False)
    texture.pack()
    mixes = []
    for name in ("Fur__authored_tone_zones_and_directional_pigment", "Short_limb_warm_umber"):
        material = bpy.data.materials[name]
        nodes, links = material.node_tree.nodes, material.node_tree.links
        shader = nodes.get("Principled BSDF")
        original_color = shader.inputs["Base Color"].links[0].from_socket
        coords = nodes.new("ShaderNodeTexCoord")
        scale = nodes.new("ShaderNodeVectorMath")
        scale.operation = "SCALE"
        scale.inputs[3].default_value = args.paint_scale
        links.new(coords.outputs["Object"], scale.inputs[0])
        paint = nodes.new("ShaderNodeTexImage")
        paint.image = texture
        paint.projection, paint.projection_blend = "BOX", .28
        paint.extension = "REPEAT"
        links.new(scale.outputs[0], paint.inputs["Vector"])
        tint = nodes.new("ShaderNodeHueSaturation")
        tint.inputs["Saturation"].default_value = .72
        tint.inputs["Value"].default_value = .90
        links.new(paint.outputs["Color"], tint.inputs["Color"])
        blend = nodes.new("ShaderNodeMixRGB")
        blend.blend_type = "MIX"
        links.new(original_color, blend.inputs[1])
        links.new(tint.outputs[0], blend.inputs[2])
        links.new(blend.outputs[0], shader.inputs["Base Color"])
        links.new(blend.outputs[0], shader.inputs["Emission Color"])
        mixes.append(blend)
    frames = []
    for label, weight in (("pigment_soft", args.soft_weight), ("pigment_full", args.full_weight)):
        for mix in mixes:
            mix.inputs[0].default_value = weight
        bpy.context.view_layer.update()
        image_path = output / (label + ".png")
        scene.render.filepath = str(image_path)
        bpy.ops.render.render(write_still=True)
        alpha = alpha_metadata(image_path)
        if alpha["edge_alpha_pixels"]:
            raise ValueError("Pigment study clips original fixed canvas")
        frames.append({"direction": "down_right", "pose": label, "path": image_path.name,
                       "weight": weight, "sha256": sha(image_path), **alpha})
    study_blend = output / "player_pigment_study_v001.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(study_blend))
    result = {"route": "blender_v002_pigment_study", "canvas": model["canvas"],
              "pivot": model["pivot"], "display_scale": model["display_scale"],
              "camera_pitch_degrees": model["camera_pitch_degrees"],
              "orthographic_scale": model["orthographic_scale"], "frames": frames,
              "model_manifest_sha256": sha(model_path), "model_blend_sha256": sha(blend_path),
              "candidate_manifest_sha256": sha(record_path), "texture_sha256": sha(texture_path),
              "source_script_sha256": sha(Path(__file__)), "blend_sha256": sha(study_blend),
              "paint_scale": args.paint_scale, "saturation": .72, "value": .90,
              "status": "technical_unapproved", "limitations": ["surface_only_standing_probe",
              "box_projection_seams_and_directional_marks_need_review", "not_a_new_master_or_game_asset"]}
    (output / "render_manifest.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print("PLAYER PIGMENT STUDY COMPLETE " + str(output), flush=True)


if __name__ == "__main__":
    main()
