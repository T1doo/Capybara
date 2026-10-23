"""Decode a few ordered frames from the actual captured review movie for visual audit."""

import argparse
from pathlib import Path
import sys

import bpy

ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    source, output = args.input.resolve(), args.output_dir.resolve()
    if (ROOT / "build") not in source.parents or (ROOT / "build") not in output.parents or output.exists():
        raise ValueError("Use a captured build movie and new build output")
    output.mkdir(parents=True)
    scene = bpy.context.scene
    scene.sequence_editor_create().strips.new_movie("Actual_GPU_video", str(source), channel=1, frame_start=1)
    scene.render.resolution_x, scene.render.resolution_y = 1280, 720
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.display_settings.display_device = "sRGB"
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.view_settings.exposure, scene.view_settings.gamma = 0, 1
    scene.sequencer_colorspace_settings.name = "sRGB"
    for number in (130, 136, 142, 148, 250, 272, 294, 375, 395, 425):
        scene.frame_set(number)
        scene.render.filepath = str(output / ("video_%04d.png" % number))
        bpy.ops.render.render(write_still=True)
    print("ACTUAL MOVIE FRAMES EXTRACTED " + str(output), flush=True)


if __name__ == "__main__":
    main()
