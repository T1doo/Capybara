"""Screen-aligned gait for the existing 35-degree orthographic camera.

Stance feet countertranslate the unchanged 240 px/s gameplay speed. Rendered markers
are measured through Blender's actual camera; algebra alone is not acceptance.
"""

import math
import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector

FPS = 60
WALK_FRAMES = 18
WALK_PERIOD = WALK_FRAMES / FPS
STANCE_FRACTION = .5
MOVE_SPEED = 240.0
DIRECTIONS = {"down_right": (1, 1), "down_left": (-1, 1),
              "up_right": (1, -1), "up_left": (-1, -1)}


def screen_yaw(direction: str) -> float:
    dx, dy = DIRECTIONS[direction]
    ground_y = dy / math.sin(math.radians(35))
    return math.degrees(math.atan2(dx - ground_y, dx + ground_y))


def project(point: Vector, camera) -> Vector:
    uv = world_to_camera_view(bpy.context.scene, camera, point)
    return Vector((uv.x * 512, (1 - uv.y) * 512))


def place_feet(character: dict, camera, frame: int | None) -> list:
    root = character["root"]
    bpy.context.view_layer.update()
    screen_unit = (project(root.matrix_world @ Vector((1, 0, 0)), camera)
                   - project(root.matrix_world @ Vector((0, 0, 0)), camera)) * .5
    stride = MOVE_SPEED / screen_unit.length * WALK_PERIOD * STANCE_FRACTION
    phase = 0.0 if frame is None else frame / WALK_FRAMES
    markers = []
    for index, foot in enumerate(character["feet"]):
        local_phase = (phase + (0.0 if index in (0, 3) else .5)) % 1
        stance = frame is None or local_phase < STANCE_FRACTION
        dx, lift = 0.0, 0.0
        if frame is not None:
            if stance:
                dx = stride * (.5 - local_phase / STANCE_FRACTION)
            else:
                swing = (local_phase - STANCE_FRACTION) / (1 - STANCE_FRACTION)
                # Cubic swing maintains -v at both contacts; no velocity pop at wrap.
                hermite = -2 * swing**3 + 3 * swing**2
                tangent = 2 * swing**3 - 3 * swing**2 + swing
                dx = stride * (-.5 + hermite - tangent)
                lift = .11 * math.sin(math.pi * swing) ** 2
        offset = Vector((dx, 0, lift))
        foot["control"].location = foot["rest"] + offset
        # Ankle follows the foot, upper leg remains joined to the same hip.
        for vertex, rest in zip(foot["leg"].data.vertices, foot["leg_vertices"]):
            weight = max(0, min(1, (.48 - rest.z) / (.48 - .075)))
            vertex.co = rest + offset * weight
        foot["leg"].data.update()
        markers.append({"id": foot["control"].name, "stance": stance, "phase": local_phase})
    bpy.context.view_layer.update()
    for foot, marker in zip(character["feet"], markers):
        # Sole at the lowest authored toe point, unchanged by camera or alpha cropping.
        sole = foot["control"].matrix_world @ Vector((.16, 0, .005))
        pixel = project(sole, camera)
        marker["sole_native_px"] = [pixel.x, pixel.y]
        marker["sole_height_model"] = sole.z
    return markers
