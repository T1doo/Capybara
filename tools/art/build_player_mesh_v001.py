"""Original loft-mesh character route B. Editable technical sample, not approved art.

Run with Blender --background --factory-startup --python this_file -- --output-dir DIR.
All assets are new files under the caller's output directory; existing assets are refused.
No reference image is loaded, traced, sampled, or used as a texture.
"""

import argparse
import hashlib
import json
import math
from pathlib import Path
import sys

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Matrix, Vector

PIVOT = (256, 384)

def options():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", required=True)
    parser.add_argument("--samples", type=int, default=24)
    parser.add_argument("--threads", type=int, default=4)
    return parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])


def material(name, color):
    result = bpy.data.materials.new(name)
    result.diffuse_color = (*color, 1)
    result.use_nodes = True
    shader = result.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1)
    shader.inputs["Roughness"].default_value = 0.92
    shader.inputs["Specular IOR Level"].default_value = 0.12
    return result


def mesh_object(name, vertices, faces, mat, parent=None, smooth=True, subdivision=1):
    mesh = bpy.data.meshes.new(name + "_editable_mesh")
    if any(index < 0 or index >= len(vertices) for face in faces for index in face):
        raise ValueError("Invalid authored face index in " + name)
    mesh.from_pydata(vertices, [], faces)
    if mesh.validate(verbose=True):
        raise ValueError("Mesh validation repaired invalid authored data: " + name)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    for face in mesh.polygons:
        face.use_smooth = smooth
    if subdivision:
        modifier = obj.modifiers.new("Controlled surface subdivision", "SUBSURF")
        modifier.levels = subdivision
        modifier.render_levels = subdivision
    if parent:
        obj.parent = parent
    return obj


def loft(name, sections, mat, parent, exponent=2.35, segments=32):
    """Custom cross sections (x, half-width, half-height, center-z), no body spheres."""
    vertices = []
    for x, width, height, center_z in sections:
        for index in range(segments):
            angle = index * math.tau / segments
            c, s = math.cos(angle), math.sin(angle)
            y = math.copysign(abs(c) ** (2 / exponent), c) * width
            z = math.copysign(abs(s) ** (2 / exponent), s) * height + center_z
            vertices.append((x, y, z))
    faces = [tuple(reversed(range(segments)))]
    for row in range(len(sections) - 1):
        for index in range(segments):
            nxt = (index + 1) % segments
            faces.append((row * segments + index, row * segments + nxt,
                          (row + 1) * segments + nxt, (row + 1) * segments + index))
    faces.append(tuple((len(sections) - 1) * segments + i for i in range(segments)))
    return mesh_object(name, vertices, faces, mat, parent)


def empty(name, parent=None):
    obj = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(obj)
    obj.parent = parent
    obj.empty_display_size = 0.18
    obj.empty_display_type = "PLAIN_AXES"
    return obj


def detail_ellipsoid(name, center, scale, mat, parent):
    # Tiny eyes/wood fastening only. Main silhouette is authored from continuous section meshes.
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, location=center)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(mat)
    obj.parent = parent
    for face in obj.data.polygons:
        face.use_smooth = True
    return obj


def cord(name, points, radius, mat, parent):
    curve = bpy.data.curves.new(name + "_curve", "CURVE")
    curve.dimensions = "3D"
    curve.bevel_depth = radius
    curve.bevel_resolution = 2
    spline = curve.splines.new("BEZIER")
    spline.bezier_points.add(len(points) - 1)
    for point, coordinate in zip(spline.bezier_points, points):
        point.co = coordinate
        point.handle_left_type = "AUTO"
        point.handle_right_type = "AUTO"
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    obj.parent = parent
    return obj


def make_character():
    root = empty("Character_Root__X_forward_Y_anatomical_left_Z_up")
    root["status"] = "technical_exploration_not_approved"
    root["reference_scope"] = "AG1 clean text-derived anatomy invariants; no image texture/reference loaded"
    palette = {
        "fur": material("Warm gray brown base__no_painted_texture_claim", (0.30, 0.155, 0.065)),
        "foot": material("Dark warm brown feet", (0.125, 0.075, 0.048)),
        "nose": material("Broad warm dark muzzle plane", (0.23, 0.143, 0.086)),
        "eye": material("Small calm dark brown eyes", (0.028, 0.017, 0.011)),
        "inner": material("Subtle ear inset", (0.265, 0.158, 0.105)),
        "glint": material("Restrained cream eye glint", (0.8, 0.72, 0.52)),
        "scarf": material("Lake teal waterproof scarf", (0.055, 0.23, 0.24)),
        "fold": material("Teal fold tonal variation", (0.04, 0.17, 0.18)),
        "leaf": material("Quiet olive lily leaf satchel", (0.25, 0.30, 0.075)),
        "edge": material("Leaf satchel thickness", (0.135, 0.17, 0.04)),
        "wood": material("Original wooden fastener", (0.45, 0.29, 0.105)),
    }
    sections = [
        (-1.36, .075, .12, .63), (-1.29, .30, .32, .63), (-1.10, .52, .49, .63),
        (-.83, .67, .535, .64), (-.43, .685, .53, .65), (-.05, .62, .515, .66),
        (.24, .56, .50, .69), (.48, .58, .54, .725), (.75, .57, .485, .705),
        (1.00, .53, .395, .64), (1.16, .49, .315, .57),
        (1.24, .465, .28, .55), (1.275, .435, .255, .55),
    ]
    body = loft("Continuous_body_shoulders_broad_wedge_head", sections, palette["fur"], root)
    body.shape_key_add(name="Basis")
    breath = body.shape_key_add(name="Idle_breath_subtle")
    pickup = body.shape_key_add(name="Pickup_head_dip")
    soak = body.shape_key_add(name="Soak_lower_body")
    for i, vertex in enumerate(body.data.vertices):
        x, y, z = vertex.co
        breath.data[i].co.z += max(0, z - .15) * .012
        amount = max(0, min(1, (x - .20) / .28))
        head_pivot = Vector((.20, 0, .69))
        bent = Matrix.Rotation(.12, 3, "Y") @ (vertex.co - head_pivot) + head_pivot
        pickup.data[i].co = vertex.co.lerp(bent, amount)
        soak.data[i].co.z = max(.035, z - .085)

    features = empty("Head_features_pose_control", root)
    for side, sign in (("Left", 1), ("Right", -1)):
        detail_ellipsoid(side + "_small_side_eye", (.74, sign * .560, .900),
                         (.060, .019, .037), palette["eye"], features)
        detail_ellipsoid(side + "_single_tiny_highlight", (.753, sign * .575, .910),
                         (.009, .006, .008), palette["glint"], features)
        ear_vertices = []
        for depth in (0, .052):
            for i in range(16):
                angle = math.tau * i / 16
                x = .36 + .095 * math.cos(angle)
                z = 1.11 + .135 * math.sin(angle)
                if side == "Left" and i in (3, 4):
                    z -= .018  # Shallow anatomical-left fold, never a pointed torn ear.
                ear_vertices.append((x, sign * (.43 + depth), z))
        ear_faces = [tuple(reversed(range(16))), tuple(range(16, 32))]
        ear_faces += [(i, (i + 1) % 16, (i + 1) % 16 + 16, i + 16) for i in range(16)]
        mesh_object(side + "_small_rounded_ear", ear_vertices, ear_faces, palette["fur"], features)
        detail_ellipsoid(side + "_ear_cup_inset", (.36, sign * .486, 1.11),
                         (.057, .010, .075), palette["inner"], features)
    muzzle = loft("Blunt_rectangular_muzzle_plane", [
        (1.268, .30, .100, .645), (1.277, .300, .100, .645), (1.284, .282, .087, .645)
    ], palette["nose"], features, exponent=3.8)
    for side in (-1, 1):
        detail_ellipsoid("Small_nostril_" + str(side), (1.287, side * .145, .658),
                         (.012, .044, .024), palette["eye"], features)
    cord("Quiet_mouth_seam", [(1.276, -.22, .414), (1.284, 0, .399), (1.276, .22, .414)],
         .006, palette["foot"], features)

    feet = []
    for label, x in (("Fore", .62), ("Hind", -.62)):
        for side, y in (("Left", .28), ("Right", -.28)):
            foot_root = empty(label + "_" + side + "_foot_control", root)
            foot_root.location = (x, y, 0)
            loft(label + "_" + side + "_short_sturdy_foot", [
                (-.13, .060, .065, .09), (-.07, .115, .095, .10),
                (.10, .122, .08, .082), (.20, .08, .054, .061), (.215, .055, .04, .06)
            ], palette["foot"], foot_root, exponent=2.4, segments=20)
            leg_vertices = []
            for z, half_x, half_y in ((.09, .105, .09), (.22, .105, .095), (.36, .13, .115), (.44, .16, .135)):
                for i in range(16):
                    theta = math.tau * i / 16
                    leg_vertices.append((half_x * math.cos(theta), half_y * math.sin(theta), z))
            leg_faces = [tuple(reversed(range(16))), tuple(range(48, 64))]
            leg_faces += [(r * 16 + i, r * 16 + (i + 1) % 16,
                           (r + 1) * 16 + (i + 1) % 16, (r + 1) * 16 + i)
                          for r in range(3) for i in range(16)]
            mesh_object(label + "_" + side + "_short_leg_hidden_into_belly",
                        leg_vertices, leg_faces, palette["fur"], foot_root)
            feet.append(foot_root)

    scarf_root = empty("Scarf__knot_anatomical_left", root)
    vertices = []
    for row in range(3):
        x = .08 + row * .095
        for i in range(32):
            theta = i * math.tau / 32
            c, s = math.cos(theta), math.sin(theta)
            y = math.copysign(abs(c) ** (2 / 2.35), c) * (.637 - row * .028)
            z = .69 + math.copysign(abs(s) ** (2 / 2.35), s) * .532
            vertices.append((x, y, z))
    faces = [(r * 32 + i, r * 32 + (i + 1) % 32, (r + 1) * 32 + (i + 1) % 32,
              (r + 1) * 32 + i) for r in range(2) for i in range(32)]
    scarf = mesh_object("Low_neck_narrow_cloth_wrap", vertices, faces, palette["scarf"], scarf_root)
    solidify = scarf.modifiers.new("Editable cloth thickness", "SOLIDIFY")
    solidify.thickness = .012
    mesh_object("Scarf_side_knot_and_short_folded_tail", [
        (.19, .55, .61), (.40, .55, .65), (.37, .59, .48), (.23, .60, .48),
        (.28, .59, .49), (.49, .60, .29), (.31, .59, .35), (.24, .59, .47),
        (.27, .58, .49), (.10, .58, .28), (.05, .56, .39), (.21, .58, .53)
    ], [(0, 1, 2, 3), (4, 5, 6, 7), (8, 9, 10, 11)], palette["fold"], scarf_root)

    bag_root = empty("Leaf_satchel__fixed_anatomical_right", root)
    # Leaf outline lives in XZ, with a real folded notch and shallow Y thickness.
    outline = [(-.32, .30), (-.43, .23), (-.50, .09), (-.49, -.09), (-.38, -.22),
               (-.19, -.27), (.02, -.24), (.16, -.10), (.19, .09), (.10, .23),
               (-.05, .29), (-.14, .16), (-.18, .30)]
    bag_vertices = [(x, y, z + .49) for y in (-.67, -.78) for x, z in outline]
    n = len(outline)
    bag_faces = [tuple(reversed(range(n))), tuple(range(n, 2 * n))]
    bag_faces += [(i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n)]
    bag = mesh_object("Leaf_bag_real_thickness_and_notch", bag_vertices, bag_faces, palette["leaf"], bag_root, subdivision=0)
    bevel = bag.modifiers.new("Soft stitched leather leaf edge", "BEVEL")
    bevel.width = .025
    bevel.segments = 3
    flap_vertices = [
        (x, -.792, z + .495) for x, z in outline[:3] + [(-.40, .035), (.13, .045)] + outline[8:]
    ]
    mesh_object("Leaf_bag_separate_upper_flap", flap_vertices,
                [tuple(range(len(flap_vertices)))], palette["leaf"], bag_root, subdivision=0)
    cord("Shoulder_strap_with_both_attachment_points", [
        (-.43, -.71, .73), (-.35, -.62, .94), (-.12, -.37, 1.165),
        (.09, .06, 1.185), (.03, .43, 1.06), (-.30, .59, .81)
    ], .028, palette["edge"], bag_root)
    cord("Leaf_bag_quiet_center_vein", [(-.15, -.80, .70), (-.16, -.807, .53), (-.20, -.795, .29)],
         .006, palette["edge"], bag_root)
    detail_ellipsoid("Small_wood_toggle_not_logo", (-.15, -.82, .57), (.055, .022, .032), palette["wood"], bag_root)
    return {"root": root, "body": body, "features": features, "feet": feet,
            "scarf": scarf_root, "bag": bag_root, "muzzle": muzzle}


def reset_pose(character, pose):
    for key in character["body"].data.shape_keys.key_blocks:
        key.value = 0
    character["features"].location = (0, 0, 0)
    character["features"].rotation_euler = (0, 0, 0)
    character["scarf"].location = (0, 0, 0)
    character["bag"].rotation_euler = (0, 0, 0)
    for i, foot in enumerate(character["feet"]):
        foot.location = (.62 if i < 2 else -.62, .28 if i % 2 == 0 else -.28, 0)
    if pose == "idle_breath":
        character["body"].data.shape_keys.key_blocks["Idle_breath_subtle"].value = 1
    elif pose.startswith("walk"):
        phase = 1 if pose.endswith("a") else -1
        for i, foot in enumerate(character["feet"]):
            gait = phase * (1 if i in (0, 3) else -1)
            foot.location.x += gait * .085
            foot.location.z = .055 if gait > 0 else 0
        character["bag"].rotation_euler.x = phase * .025
    elif pose == "pickup":
        character["body"].data.shape_keys.key_blocks["Pickup_head_dip"].value = 1
        character["features"].rotation_euler.y = .12
        pivot = Vector((.20, 0, .69))
        character["features"].location = pivot - Matrix.Rotation(.12, 3, "Y") @ pivot
        character["feet"][0].location.x += .10
        character["feet"][0].location.z = .04
    elif pose == "soak":
        character["body"].data.shape_keys.key_blocks["Soak_lower_body"].value = 1
        character["features"].location.z = -.085
        character["scarf"].location.z = -.085


def aim(obj, point):
    obj.rotation_euler = (Vector(point) - obj.location).to_track_quat("-Z", "Y").to_euler()


def evaluated_points(character):
    depsgraph = bpy.context.evaluated_depsgraph_get()
    points = []
    for obj in bpy.context.scene.objects:
        if obj.type not in {"MESH", "CURVE"}:
            continue
        evaluated = obj.evaluated_get(depsgraph)
        mesh = evaluated.to_mesh()
        points.extend(evaluated.matrix_world @ vertex.co for vertex in mesh.vertices)
        evaluated.to_mesh_clear()
    return points


def configure_camera(character, camera, yaw, scale):
    character["root"].rotation_euler.z = math.radians(yaw)
    bpy.context.view_layer.update()
    camera.data.ortho_scale = scale
    camera.location = (6, -6, math.sqrt(72) * math.tan(math.radians(35)))
    aim(camera, (0, 0, 0))
    # Fixed anatomical ground origin, not the view-dependent foreground foot or Alpha bottom.
    anchor = Vector((0, 0, 0))
    view = camera.rotation_euler.to_matrix()
    target_ndc = Vector((PIVOT[0] / 512, 1 - PIVOT[1] / 512))
    bpy.context.view_layer.update()
    actual = world_to_camera_view(bpy.context.scene, camera, anchor)
    camera.location += view @ Vector(((actual.x - target_ndc.x) * scale, (actual.y - target_ndc.y) * scale, 0))
    bpy.context.view_layer.update()


def alpha_metadata(path):
    image = bpy.data.images.load(str(path), check_existing=False)
    width, height = image.size
    pixels = image.pixels[:]
    indices = [i for i in range(width * height) if pixels[i * 4 + 3] > 0]
    if not indices:
        raise RuntimeError("Empty Alpha render: " + str(path))
    xs = [i % width for i in indices]
    ys = [i // width for i in indices]
    bbox = [min(xs), height - max(ys) - 1, max(xs) + 1, height - min(ys)]
    edges = sum(1 for x, y in zip(xs, ys) if x in (0, width - 1) or y in (0, height - 1))
    bpy.data.images.remove(image)
    return {"alpha_bbox": bbox, "alpha_height": bbox[3] - bbox[1], "edge_alpha_pixels": edges}


def main():
    args = options()
    output = Path(args.output_dir).resolve()
    output.mkdir(parents=True, exist_ok=True)
    frame_specs = [(name, yaw, "idle") for name, yaw in (
        ("down_right", 0), ("down_left", -90), ("up_right", 90), ("up_left", 180))]
    frame_specs += [("down_right", 0, pose) for pose in ("idle_breath", "walk_a", "walk_b", "pickup", "soak")]
    planned = [output / (direction + "_" + pose + ".png") for direction, _, pose in frame_specs]
    planned += [output / "player_mesh_v001.blend", output / "render_manifest.json",
                output / "calibration_down_right.png"]
    if any(path.exists() for path in planned):
        raise RuntimeError("Refusing to overwrite a previous sample; choose a new run directory")
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    # Factory startup can retain unused built-in grease-pencil materials with library paths.
    for unused in list(bpy.data.materials):
        bpy.data.materials.remove(unused, do_unlink=True)
    character = make_character()
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = args.samples
    scene.cycles.use_denoising = True
    scene.render.threads_mode = "FIXED"
    scene.render.threads = args.threads
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
    for name, position, energy, size in (
        ("Screen_upper_left_soft_key", (-3.5, -5.5, 7.0), 650, 5.0),
        ("Broad_weak_fill", (4, 3, 5), 130, 5.0),
    ):
        bpy.ops.object.light_add(type="AREA", location=position)
        light = bpy.context.object
        light.name = name
        light.data.energy = energy
        light.data.shape = "DISK"
        light.data.size = size
        aim(light, (0, 0, .6))
    bpy.ops.object.camera_add()
    camera = bpy.context.object
    camera.name = "Fixed_35_degree_orthographic_camera"
    camera.data.type = "ORTHO"
    scene.camera = camera
    configure_camera(character, camera, 0, 4.0)
    projected = [world_to_camera_view(scene, camera, point) for point in evaluated_points(character)]
    reference_extent = max(point.y for point in projected) - min(point.y for point in projected)
    scale = 4.0 * reference_extent * 512 / 288
    configure_camera(character, camera, 0, scale)
    calibration = output / "calibration_down_right.png"
    scene.render.filepath = str(calibration)
    bpy.ops.render.render(write_still=True)
    calibration_alpha = alpha_metadata(calibration)
    if calibration_alpha["edge_alpha_pixels"]:
        raise RuntimeError("Reference calibration clips; revise shared canvas/pivot before rendering")
    # One standing-reference raster calibration, shared by every direction and action.
    scale *= calibration_alpha["alpha_height"] / 288
    frames = []
    for direction, yaw, pose in frame_specs:
        reset_pose(character, "idle")
        configure_camera(character, camera, yaw, scale)
        reset_pose(character, pose)
        bpy.context.view_layer.update()
        path = output / (direction + "_" + pose + ".png")
        scene.render.filepath = str(path)
        print("PLAYER_AB_FRAME " + direction + " " + pose, flush=True)
        bpy.ops.render.render(write_still=True)
        alpha = alpha_metadata(path)
        if alpha["edge_alpha_pixels"]:
            raise RuntimeError("Frame clips shared canvas: " + path.name)
        frames.append({"direction": direction, "pose": pose, "path": path.name,
                       "sha256": hashlib.sha256(path.read_bytes()).hexdigest(), **alpha})
    reset_pose(character, "idle")
    configure_camera(character, camera, 0, scale)
    bpy.ops.wm.save_as_mainfile(filepath=str(output / "player_mesh_v001.blend"))
    manifest = {
        "route": "blender", "camera_pitch_degrees": 35, "canvas": [512, 512],
        "pivot": list(PIVOT), "reference_body_height_px": 288,
        "pivot_definition": "fixed rig ground origin (0,0,0), invariant across directions and poses",
        "scale_calibration": "one down_right standing raster calibration; fixed for all final frames",
        "actual_reference_alpha_height_px": frames[0]["alpha_height"],
        "orthographic_scale": scale, "frames": frames,
        "source_script_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        "blend_path": "player_mesh_v001.blend", "blender_version": bpy.app.version_string,
        "accessories": {"scarf_knot": "anatomical_left", "satchel": "anatomical_right"},
        "limitations": ["technical_exploration_not_approved", "no_painterly_texture_claim",
                        "key_poses_not_finished_animation", "no_ground_shadow_baked",
                        "no_water_mask_baked", "no_third_party_images_or_assets_loaded"],
    }
    (output / "render_manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print("PLAYER_AB_COMPLETE " + str(output), flush=True)


if __name__ == "__main__":
    main()
