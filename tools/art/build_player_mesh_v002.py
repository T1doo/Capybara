"""Render an original editable revision of route B; output stays in ignored build.

Blender --background --factory-startup --python-exit-code 1 --python this_file -- --output-dir build/.../new_run
No old .blend, approved source layer, image reference, or product asset is overwritten.
"""

import argparse
import hashlib
import json
from pathlib import Path
import sys
import time

import bpy
from bpy_extras.object_utils import world_to_camera_view

SOURCE_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SOURCE_DIR))
from build_player_mesh_v001 import aim, alpha_metadata, configure_camera, evaluated_points
from player_mesh_v002_geometry import make_character
from player_mesh_v002_motion import FPS, MOVE_SPEED, WALK_FRAMES, place_feet, screen_yaw


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def setup_scene(samples: int, threads: int):
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for material in list(bpy.data.materials):
        bpy.data.materials.remove(material, do_unlink=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = samples
    scene.cycles.seed = 0
    scene.cycles.use_denoising = True
    scene.render.threads_mode = "FIXED"
    scene.render.threads = threads
    scene.render.resolution_x = scene.render.resolution_y = 512
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.color_depth = "8"
    scene.view_settings.view_transform = "AgX"
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs["Color"].default_value = (.72, .76, .80, 1)
    scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value = .65
    for name, position, energy in (("Soft_upper_left_key", (-3.5, -5.5, 7), 650),
                                   ("Broad_weak_fill", (4, 3, 5), 130)):
        bpy.ops.object.light_add(type="AREA", location=position)
        lamp = bpy.context.object
        lamp.name, lamp.data.energy = name, energy
        lamp.data.shape, lamp.data.size = "DISK", 5.0
        aim(lamp, (0, 0, .6))
    bpy.ops.object.camera_add()
    camera = bpy.context.object
    camera.name = "Fixed_35_degree_orthographic_camera"
    camera.data.type = "ORTHO"
    scene.camera = camera
    return scene, camera


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", required=True)
    parser.add_argument("--samples", type=int, default=32)
    parser.add_argument("--threads", type=int, default=4)
    parser.add_argument("--preview-only", action="store_true")
    parser.add_argument("--walk-probe", action="store_true")
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    output = Path(args.output_dir).resolve()
    build = SOURCE_DIR.parents[1] / "build"
    if build.resolve() not in output.parents or output.exists():
        raise ValueError("Choose a NEW output directory strictly inside repository build")
    if not 1 <= args.samples <= 256 or not 1 <= args.threads <= 32:
        raise ValueError("Invalid samples/threads")
    output.mkdir(parents=True)
    started = time.monotonic()
    scene, camera = setup_scene(args.samples, args.threads)
    character = make_character()
    reference_yaw = screen_yaw("down_right")
    configure_camera(character, camera, reference_yaw, 4.0)
    points = [world_to_camera_view(scene, camera, point) for point in evaluated_points(character)]
    scale = 4 * (max(p.y for p in points) - min(p.y for p in points)) * 512 / 288
    configure_camera(character, camera, reference_yaw, scale)
    scene.render.filepath = str(output / "calibration.png")
    bpy.ops.render.render(write_still=True)
    calibration = alpha_metadata(output / "calibration.png")
    if calibration["edge_alpha_pixels"]:
        raise RuntimeError("Calibration clips")
    scale *= calibration["alpha_height"] / 288
    views = ["down_right", "down_left", "up_right", "up_left"]
    if args.preview_only:
        views = views[:1]
    frames = []
    specs = [(direction, None) for direction in views]
    if args.walk_probe:
        specs += [("down_right", frame) for frame in range(WALK_FRAMES)]
    for direction, frame in specs:
        yaw = screen_yaw(direction)
        configure_camera(character, camera, yaw, scale)
        markers = place_feet(character, camera, frame)
        pose = "idle" if frame is None else "walk_%02d" % frame
        path = output / (direction + "_" + pose + ".png")
        scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        alpha = alpha_metadata(path)
        if alpha["edge_alpha_pixels"]:
            raise RuntimeError("Frame clips: " + path.name)
        frames.append({"direction": direction, "pose": pose, "path": path.name,
                       "yaw_degrees": yaw, "walk_frame": frame, "feet": markers,
                       "sha256": sha(path), **alpha})
        print("PLAYER_V002_FRAME " + direction + " " + pose, flush=True)
    configure_camera(character, camera, reference_yaw, scale)
    place_feet(character, camera, None)
    blend = output / "player_mesh_v002.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(blend))
    source_names = ["build_player_mesh_v001.py", "build_player_mesh_v002.py",
                    "player_mesh_v002_geometry.py", "player_mesh_v002_materials.py",
                    "player_mesh_v002_motion.py"]
    manifest = {
        "route": "blender_v002", "canvas": [512, 512], "pivot": [256, 384], "display_scale": .5,
        "camera_pitch_degrees": 35, "orthographic_scale": scale,
        "reference_body_height_px": 288, "actual_reference_alpha_height_px": frames[0]["alpha_height"],
        "scale_calibration": "one DR standing calibration, unchanged across all directions",
        "pivot_definition": "fixed anatomical ground origin, not alpha bottom",
        "frames": frames, "sources": {name: sha(SOURCE_DIR / name) for name in source_names},
        "blend_path": blend.name, "blend_sha256": sha(blend), "blender_version": bpy.app.version_string,
        "samples": args.samples, "threads": args.threads, "render_device": "CPU",
        "walk": {"fps": FPS, "frame_count": WALK_FRAMES, "move_speed": MOVE_SPEED,
                 "scope": "down_right only, diagonal trot study, not full animation acceptance"},
        "elapsed_seconds": round(time.monotonic() - started, 2),
        "accessories": {"scarf_knot": "anatomical_left", "satchel": "anatomical_right"},
        "limitations": ["technical_unapproved", "procedural_pigment_is_not_visual_acceptance",
                        "four_static_views_and_optional_one_direction_walk_probe",
                        "no_image_assets_loaded", "no_baked_ground_shadow"],
    }
    (output / "render_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print("PLAYER_V002_COMPLETE " + str(output), flush=True)


if __name__ == "__main__":
    main()
