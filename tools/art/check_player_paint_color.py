"""Small display-referred paint round-trip calibration through pinned Blender views."""

import argparse
import json
from pathlib import Path
import sys

import bpy

ROOT = Path(__file__).resolve().parents[2]
SWATCHES = [(24, 24, 24), (96, 96, 96), (169, 134, 96), (60, 116, 124),
            (115, 130, 64), (208, 194, 169), (240, 240, 240)]


def linear(value: int) -> float:
    srgb = value / 255
    return srgb / 12.92 if srgb <= .04045 else ((srgb + .055) / 1.055) ** 2.4


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    output = args.output_dir.resolve()
    if (ROOT / "build") not in output.parents or output.exists():
        raise ValueError("Choose a new build-only calibration directory")
    output.mkdir(parents=True)
    image = bpy.data.images.new("Known_sRGB_paint_as_scene_linear", width=112, height=16, float_buffer=True)
    pixels = []
    for _y in range(16):
        for x in range(112):
            pixels.extend([*(linear(v) for v in SWATCHES[x // 16]), 1])
    image.pixels.foreach_set(pixels)
    scene = bpy.context.scene
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.color_depth = "8"
    scene.render.dither_intensity = 0
    scene.display_settings.display_device = "sRGB"
    scene.view_settings.look = "None"
    scene.view_settings.exposure, scene.view_settings.gamma = 0, 1
    for view in ("AgX", "Standard"):
        scene.view_settings.view_transform = view
        image.save_render(str(output / (view.lower() + ".png")), scene=scene)
    (output / "expected.json").write_text(json.dumps({"blender": bpy.app.version_string,
        "input": "sRGB paint decoded to scene-linear RGB", "image_colorspace": image.colorspace_settings.name,
        "swatches_srgb8": SWATCHES, "sample_xy": [[i * 16 + 8, 8] for i in range(len(SWATCHES))]}, indent=2))
    print("PAINT COLOR CALIBRATION WRITTEN " + str(output), flush=True)


if __name__ == "__main__":
    main()
