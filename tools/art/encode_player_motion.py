"""Transcode the real Godot viewport AVI to a small review MP4 using pinned Blender."""

import argparse
import hashlib
import json
from pathlib import Path
import sys

import bpy

ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--compare", type=Path)
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    source, output = args.input.resolve(), args.output.resolve()
    if (ROOT / "build") not in source.parents or (ROOT / "build") not in output.parents or output.exists():
        raise ValueError("Use a captured build AVI and a new build MP4")
    comparison = args.compare.resolve() if args.compare else None
    if comparison and (ROOT / "build") not in comparison.parents:
        raise ValueError("Comparison capture must remain in build")
    scene = bpy.context.scene
    editor = scene.sequence_editor_create()
    movie = editor.strips.new_movie("Actual_Godot_GPU_capture", str(source), channel=2, frame_start=1)
    second = None
    if comparison:
        second = editor.strips.new_movie("Same_tick_comparison", str(comparison), channel=3, frame_start=1)
        movie.transform.offset_x, second.transform.offset_x = -640, 640
        movie.blend_type = second.blend_type = "ALPHA_OVER"
    try:
        editor.strips.new_sound("Captured_game_audio", str(source), channel=1, frame_start=1)
    except RuntimeError:
        pass  # Some Godot AVI builds contain no audio stream; video provenance is unchanged.
    frame_count = min(movie.frame_final_duration, second.frame_final_duration) if second else movie.frame_final_duration
    scene.frame_start, scene.frame_end = 1, frame_count
    scene.render.fps, scene.render.fps_base = 60, 1
    scene.render.resolution_x, scene.render.resolution_y = 2560 if second else 1280, 720
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "FFMPEG"
    scene.render.ffmpeg.format = "MPEG4"
    scene.render.ffmpeg.codec = "H264"
    scene.render.ffmpeg.constant_rate_factor = "MEDIUM"
    scene.render.ffmpeg.ffmpeg_preset = "GOOD"
    scene.render.ffmpeg.audio_codec = "AAC"
    scene.render.ffmpeg.gopsize = 60
    scene.display_settings.display_device = "sRGB"
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.view_settings.exposure, scene.view_settings.gamma = 0, 1
    scene.sequencer_colorspace_settings.name = "sRGB"
    scene.render.filepath = str(output)
    bpy.ops.render.render(animation=True)
    result = {"input_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
              "output_sha256": hashlib.sha256(output.read_bytes()).hexdigest(),
              "frames": frame_count, "fps": 60,
              "duration_seconds": frame_count / 60,
              "resolution": [scene.render.resolution_x, scene.render.resolution_y],
              "comparison_sha256": hashlib.sha256(comparison.read_bytes()).hexdigest() if comparison else None,
              "layout": "unscaled A left / B right, same capture start" if second else "single actual viewport",
              "codec": "H264 MP4", "color": "sRGB sequencer + Standard view; no artistic regrade",
              "source": "actual Godot Compatibility viewport capture, not a concept illustration",
              "blender": bpy.app.version_string}
    output.with_suffix('.json').write_text(json.dumps(result, indent=2) + '\n')
    print("REVIEW MOVIE ENCODED " + str(output), flush=True)


if __name__ == "__main__":
    main()
