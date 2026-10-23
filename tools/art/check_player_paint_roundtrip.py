"""Render an original sRGB paint through an unlit Image Texture, preserving color management."""

import argparse
import hashlib
import json
from pathlib import Path
import sys

import bpy

ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    output = args.output_dir.resolve()
    if (ROOT / "build") not in output.parents or output.exists():
        raise ValueError("Choose a new build-only output")
    output.mkdir(parents=True)
    source = ROOT / "art/candidates/player_v003_paintover_v001/paintover_a_v001.png"
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    bpy.ops.mesh.primitive_plane_add(size=2)
    plane = bpy.context.object
    material = bpy.data.materials.new("sRGB_unlit_roundtrip")
    material.use_nodes = True
    nodes, links = material.node_tree.nodes, material.node_tree.links
    nodes.clear()
    image = bpy.data.images.load(str(source))
    image.colorspace_settings.name = "sRGB"
    texture = nodes.new("ShaderNodeTexImage")
    texture.image, texture.interpolation = image, "Closest"
    emission = nodes.new("ShaderNodeEmission")
    links.new(texture.outputs["Color"], emission.inputs["Color"])
    transparent = nodes.new("ShaderNodeBsdfTransparent")
    mix = nodes.new("ShaderNodeMixShader")
    links.new(texture.outputs["Alpha"], mix.inputs[0])
    links.new(transparent.outputs[0], mix.inputs[1])
    links.new(emission.outputs[0], mix.inputs[2])
    result = nodes.new("ShaderNodeOutputMaterial")
    links.new(mix.outputs[0], result.inputs["Surface"])
    plane.data.materials.append(material)
    bpy.ops.object.camera_add(location=(0, 0, 2))
    camera = bpy.context.object
    camera.data.type, camera.data.ortho_scale = "ORTHO", 2
    scene = bpy.context.scene
    scene.camera = camera
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 1
    scene.cycles.use_denoising = False
    scene.render.threads_mode, scene.render.threads = "FIXED", 4
    scene.render.resolution_x, scene.render.resolution_y = image.size
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.dither_intensity = 0
    scene.display_settings.display_device = "sRGB"
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.view_settings.exposure, scene.view_settings.gamma = 0, 1
    scene.render.filepath = str(output / "roundtrip.png")
    bpy.ops.render.render(write_still=True)
    (output / "source.json").write_text(json.dumps({"source_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
        "input": "sRGB Image Texture", "shader": "unlit emission with Alpha connected, matching the paint blend", "output": "Standard/sRGB",
        "blender": bpy.app.version_string}, indent=2))


if __name__ == "__main__":
    main()
