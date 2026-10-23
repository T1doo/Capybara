"""Evaluated rest surfaces and depth-tested camera paint visibility.

Depth tests must use the rendered surface, not a subdivision control cage. Work on a
new study blend: preserve relative shape-key surfaces while baking static modifiers.
"""

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector

SUPPORTED_MODIFIERS = {"SUBSURF", "BEVEL", "SOLIDIFY"}


def evaluated_coordinates(obj) -> list:
    bpy.context.view_layer.update()
    evaluated = obj.evaluated_get(bpy.context.evaluated_depsgraph_get())
    mesh = evaluated.to_mesh()
    try:
        return [vertex.co.copy() for vertex in mesh.vertices]
    finally:
        evaluated.to_mesh_clear()


def bake_render_surfaces() -> dict:
    counts = {"baked_meshes": 0, "control_vertices": 0, "surface_vertices": 0, "preserved_shape_keys": 0}
    for obj in list(bpy.context.scene.objects):
        if obj.type != "MESH":
            continue
        counts["control_vertices"] += len(obj.data.vertices)
        if not obj.modifiers:
            counts["surface_vertices"] += len(obj.data.vertices)
            continue
        for modifier in obj.modifiers:
            if modifier.type not in SUPPORTED_MODIFIERS or modifier.show_render != modifier.show_viewport:
                raise ValueError("Unsupported or viewport/render-mismatched modifier: " + obj.name)
            if modifier.type == "SUBSURF" and modifier.levels != modifier.render_levels:
                raise ValueError("Subdivision viewport/render levels differ: " + obj.name)
        keys = obj.data.shape_keys
        if keys and (not keys.use_relative or keys.animation_data):
            raise ValueError("Only undriven relative shape keys can be preserved: " + obj.name)
        poses = []
        if keys:
            for key in list(keys.key_blocks)[1:]:
                if key.relative_key != keys.key_blocks[0]:
                    raise ValueError("Shape keys must be relative to Basis: " + obj.name)
                poses.append({"name": key.name, "value": key.value, "min": key.slider_min,
                              "max": key.slider_max, "key": key})
                key.value = 0
        bpy.context.view_layer.update()
        depsgraph = bpy.context.evaluated_depsgraph_get()
        surface = bpy.data.meshes.new_from_object(obj.evaluated_get(depsgraph),
                                                 preserve_all_data_layers=True, depsgraph=depsgraph)
        surface.name = obj.data.name + "__evaluated_paint_surface"
        for pose in poses:
            pose["key"].value = 1
            pose["vertices"] = evaluated_coordinates(obj)
            pose["key"].value = 0
            if len(pose["vertices"]) != len(surface.vertices):
                raise ValueError("Modifier changes topology between shape keys: " + obj.name)
        obj.data = surface
        obj.modifiers.clear()
        if keys:
            obj.shape_key_add(name="Basis")
            for pose in poses:
                rebuilt = obj.shape_key_add(name=pose["name"])
                for vertex, coordinate in zip(rebuilt.data, pose["vertices"]):
                    vertex.co = coordinate
                rebuilt.slider_min, rebuilt.slider_max = pose["min"], pose["max"]
                rebuilt.value = pose["value"]
                counts["preserved_shape_keys"] += 1
        counts["baked_meshes"] += 1
        counts["surface_vertices"] += len(surface.vertices)
    bpy.context.view_layer.update()
    return counts


def projection_sample(obj, point: Vector, normal: Vector, camera, depsgraph) -> dict:
    """A ray must hit this surface point, not merely any face of the same object."""
    if camera.data.type != "ORTHO":
        raise ValueError("This fixed-camera paint projection requires an orthographic camera")
    scene = bpy.context.scene
    uv = world_to_camera_view(scene, camera, point)
    toward_camera = (camera.matrix_world.to_3x3() @ Vector((0, 0, 1))).normalized()
    depth = (camera.matrix_world.translation - point).dot(toward_camera)
    result = {"uv": (uv.x, uv.y), "weight": 0.0, "reason": "clipped"}
    if depth <= camera.data.clip_start or depth >= camera.data.clip_end:
        return result
    if not (0 <= uv.x <= 1 and 0 <= uv.y <= 1):
        result["reason"] = "outside_frame"
        return result
    facing = normal.normalized().dot(toward_camera)
    if facing <= .08:
        result["reason"] = "back_or_grazing"
        return result
    origin = point + toward_camera * (depth - camera.data.clip_start)
    hit = scene.ray_cast(depsgraph, origin, -toward_camera,
                         distance=camera.data.clip_end - camera.data.clip_start)
    if not hit[0]:
        result["reason"] = "no_surface_hit"
        return result
    if hit[4].original != obj.original:
        result["reason"] = "other_object_occlusion"
        return result
    # Scale-aware numerical tolerance, not a control-cage-sized allowance for hidden faces.
    epsilon = max(1e-5, obj.dimensions.length * 1e-5)
    separation = (hit[1] - point).length
    result["depth_separation"] = separation
    result["epsilon"] = epsilon
    if separation > epsilon:
        result["reason"] = "same_mesh_depth_occlusion"
        return result
    result["weight"] = max(0, min(1, (facing - .08) / .40))
    result["reason"] = "visible_surface"
    return result
