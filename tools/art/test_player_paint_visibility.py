"""Actual Blender geometry regressions for camera paint occlusion and surface baking."""

import argparse
import json
from pathlib import Path
import sys

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/art"))
from player_paint_surface import bake_render_surfaces, evaluated_coordinates, projection_sample


def reset():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    bpy.ops.object.camera_add(location=(0, 0, 5))
    camera = bpy.context.object
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 4
    camera.data.clip_start, camera.data.clip_end = .1, 20
    bpy.context.scene.camera = camera
    bpy.context.scene.render.resolution_x = bpy.context.scene.render.resolution_y = 256
    return camera


def plates(name: str, heights: list):
    vertices, faces = [], []
    for z, extent in heights:
        start = len(vertices)
        vertices += [(-extent, -extent, z), (extent, -extent, z),
                     (extent, extent, z), (-extent, extent, z)]
        faces.append(tuple(range(start, start + 4)))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    return obj


def sample(obj, point, camera, normal=(0, 0, 1)):
    bpy.context.view_layer.update()
    return projection_sample(obj, Vector(point), Vector(normal), camera,
                             bpy.context.evaluated_depsgraph_get())


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    output = args.output_dir.resolve()
    if (ROOT / "build") not in output.parents or output.exists():
        raise ValueError("Choose a new build-only fixture directory")
    output.mkdir(parents=True)
    rows = []
    camera = reset()
    obj = plates("Two_front_facing_sheets_in_ONE_mesh", [(0, .5), (1, 1)])
    rear = sample(obj, (0, 0, 0), camera)
    assert rear["weight"] == 0 and rear["reason"] == "same_mesh_depth_occlusion"
    assert abs(rear["depth_separation"] - 1) < 1e-5
    rows.append({"case": "same_mesh_hidden_front_facing_sheet", "observed": rear})
    front = sample(obj, (0, 0, 1), camera)
    assert front["weight"] == 1
    rows.append({"case": "visible_front_sheet", "observed": front})
    back = sample(obj, (0, 0, 1), camera, (0, 0, -1))
    assert back["weight"] == 0 and back["reason"] == "back_or_grazing"
    rows.append({"case": "back_facing", "observed": back})
    grazing = sample(obj, (0, 0, 1), camera, (1, 0, .04))
    assert grazing["weight"] == 0 and grazing["reason"] == "back_or_grazing"
    rows.append({"case": "grazing_surface", "observed": grazing})
    plates("Separate_occluder", [(2, .8)])
    blocked = sample(obj, (0, 0, 1), camera)
    assert blocked["weight"] == 0 and blocked["reason"] == "other_object_occlusion"
    rows.append({"case": "other_object_occlusion", "observed": blocked})
    outside = sample(obj, (4, 0, 1), camera)
    assert outside["weight"] == 0 and outside["reason"] == "outside_frame"
    rows.append({"case": "outside_orthographic_frame", "observed": outside})
    clipped = sample(obj, (0, 0, 5.1), camera)
    assert clipped["weight"] == 0 and clipped["reason"] == "clipped"
    rows.append({"case": "behind_camera_clip", "observed": clipped})
    camera = reset()
    obj = plates("Nonuniform_scaled_surface", [(0, .5)])
    obj.location = (.2, -.3, .4)
    obj.scale = (1.5, .75, 2)
    transformed = sample(obj, (.2, -.3, .4), camera)
    assert transformed["weight"] == 1
    rows.append({"case": "nonuniform_object_transform", "observed": transformed})
    camera.data.type = "PERSP"
    try:
        sample(obj, (.2, -.3, .4), camera)
    except ValueError:
        rows.append({"case": "perspective_projection_rejected"})
    else:
        raise AssertionError("Perspective camera silently used orthographic rays")
    camera = reset()
    thick = plates("Centered_thickness_surface", [(0, 1)])
    modifier = thick.modifiers.new("Actual_thickness", "SOLIDIFY")
    modifier.thickness, modifier.offset = .2, 0
    wrong_layer = sample(thick, (0, 0, 0), camera)
    assert wrong_layer["weight"] == 0 and wrong_layer["reason"] == "same_mesh_depth_occlusion"
    bake_render_surfaces()
    actual_surface = sample(thick, (0, 0, .1), camera)
    assert actual_surface["weight"] == 1
    rows.append({"case": "thickness_surface_not_control_plane", "control_plane": wrong_layer, "surface": actual_surface})
    reset()
    bpy.ops.mesh.primitive_cube_add()
    obj = bpy.context.object
    obj.shape_key_add(name="Basis")
    breath = obj.shape_key_add(name="Breath")
    for vertex in breath.data:
        vertex.co.z *= 1.15
    modifier = obj.modifiers.new("Subdivision", "SUBSURF")
    modifier.levels = modifier.render_levels = 1
    before = []
    for value in (0, .35, 1):
        breath.value = value
        before.append(evaluated_coordinates(obj))
    breath.value = .35
    bake = bake_render_surfaces()
    assert bake["preserved_shape_keys"] == 1 and len(obj.modifiers) == 0
    assert abs(obj.data.shape_keys.key_blocks["Breath"].value - .35) < 1e-6
    maximum = 0.0
    for value, expected in zip((0, .35, 1), before):
        obj.data.shape_keys.key_blocks["Breath"].value = value
        actual = evaluated_coordinates(obj)
        assert len(actual) == len(expected)
        maximum = max(maximum, max((a - b).length for a, b in zip(actual, expected)))
    assert maximum < 1e-6
    rows.append({"case": "subdivided_shape_key_surfaces_preserved", "max_error": maximum, "bake": bake})
    modifier = obj.modifiers.new("Mismatched_preview", "SUBSURF")
    modifier.levels, modifier.render_levels = 1, 2
    try:
        bake_render_surfaces()
    except ValueError:
        rows.append({"case": "different_render_subdivision_rejected"})
    else:
        raise AssertionError("Mismatched render surface accepted")
    (output / "results.json").write_text(json.dumps({"passed": len(rows), "cases": rows}, indent=2) + "\n")
    print("PAINT VISIBILITY FIXTURES PASSED: %d/%d" % (len(rows), len(rows)), flush=True)


if __name__ == "__main__":
    main()
