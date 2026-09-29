"""Editable capybara shape revision: continuous head/body, cupped ears and real toes."""

import math
import bpy
from mathutils import Matrix, Vector

from build_player_mesh_v001 import cord, detail_ellipsoid, empty, loft, mesh_object
from player_mesh_v002_materials import assign_body_tones, palette


def make_ears(features, colors: dict) -> None:
    for side, sign in (("Left", 1), ("Right", -1)):
        vertices = []
        # Concentric raised rim and recessed cup; anatomical-left upper rim folds outward.
        for radius, depth in ((1.0, 0.0), (.75, .033), (.39, .005), (.03, -.014)):
            for i in range(24):
                angle = math.tau * i / 24
                x = .31 + .12 * math.cos(angle) * radius
                z = 1.105 + .14 * math.sin(angle) * radius
                fold = .025 * max(0, math.sin(angle)) if side == "Left" else 0
                vertices.append((x, sign * (.40 + depth + fold), z - fold * .5))
        faces = [(r * 24 + i, r * 24 + (i + 1) % 24,
                  (r + 1) * 24 + (i + 1) % 24, (r + 1) * 24 + i)
                 for r in range(3) for i in range(24)]
        ear = mesh_object(side + "_rounded_cupped_ear", vertices, faces, colors["limb"], features)
        ear.data.materials.append(colors["inner"])
        for face in ear.data.polygons:
            face.material_index = int(face.index >= 24)
        solid = ear.modifiers.new("Thin_cup_back", "SOLIDIFY")
        solid.thickness = .024


def make_face(features, colors: dict) -> None:
    make_ears(features, colors)
    for side, sign in (("Left", 1), ("Right", -1)):
        detail_ellipsoid(side + "_small_side_eye", (.62, sign * .474, 1.01),
                         (.063, .024, .037), colors["eye"], features)
        cord(side + "_quiet_upper_lid", [(.553, sign * .465, 1.025),
             (.605, sign * .482, 1.050), (.670, sign * .482, 1.034)], .009, colors["nose"], features)
        detail_ellipsoid(side + "_tiny_glint", (.637, sign * .498, 1.023),
                         (.007, .0035, .006), colors["glint"], features)
        # Nostril slits sit at the upper corners of the muzzle, not on a round pig-like plate.
        detail_ellipsoid(side + "_nostril_slit", (1.455, sign * .235, .771),
                         (.014, .043, .017), colors["eye"], features)
    loft("Upper_muzzle_bridge", [(1.405, .235, .055, .808),
         (1.440, .257, .058, .799), (1.464, .235, .045, .788)], colors["nose"], features, exponent=2.8)
    cord("Vertical_muzzle_seam", [(1.467, 0, .660), (1.466, 0, .570), (1.460, 0, .495)],
         .005, colors["nose"], features)
    cord("Quiet_lower_mouth", [(1.448, -.195, .508), (1.465, 0, .488), (1.448, .195, .508)],
         .005, colors["nose"], features)


def make_feet(root, colors: dict) -> list:
    feet = []
    for label, x in (("Fore", .66), ("Hind", -.94)):
        for side, y in (("Left", .40), ("Right", -.40)):
            control = empty(label + "_" + side + "_foot_control", root)
            control.location = (x, y, 0)
            vertices = []
            for z, rx, ry in ((.075, .12, .105), (.17, .125, .11),
                              (.30, .16, .135), (.48, .23, .18)):
                for i in range(24):
                    angle = math.tau * i / 24
                    vertices.append((rx * math.cos(angle), ry * math.sin(angle), z))
            faces = [tuple(reversed(range(24))), tuple(range(72, 96))]
            faces += [(r * 24 + i, r * 24 + (i + 1) % 24,
                       (r + 1) * 24 + (i + 1) % 24, (r + 1) * 24 + i)
                      for r in range(3) for i in range(24)]
            leg = mesh_object(label + "_" + side + "_tapered_short_leg", vertices, faces,
                              colors["limb"], root)
            leg.location = (x, y, 0)
            loft(label + "_" + side + "_broad_foot_pad", [
                (-.14, .07, .055, .062), (-.06, .14, .068, .075),
                (.07, .16, .057, .064), (.20, .12, .040, .047)], colors["foot"], control)
            for toe in range(3):
                detail_ellipsoid(label + "_" + side + "_toe_" + str(toe),
                                 (.16, (toe - 1) * .089, .065), (.095, .052, .060),
                                 colors["foot"], control)
            feet.append({"control": control, "leg": leg, "rest": Vector((x, y, 0)),
                         "leg_vertices": [v.co.copy() for v in leg.data.vertices]})
    return feet


def make_scarf(root, colors: dict):
    control = empty("Scarf__knot_anatomical_left", root)
    vertices = []
    for row in range(4):
        for i in range(48):
            angle = i * math.tau / 48
            c, s = math.cos(angle), math.sin(angle)
            y = math.copysign(abs(c) ** (2 / 2.35), c) * (.635 - row * .005)
            z = .727 + math.copysign(abs(s) ** (2 / 2.35), s) * (.524 + .006 * math.sin(row * 2))
            # The lower neck band hangs forward under the throat instead of a rigid upright collar.
            x = -.015 + row * .044 + .43 * max(0, -s) ** 1.3
            vertices.append((x, y, z))
    faces = [(r * 48 + i, r * 48 + (i + 1) % 48,
              (r + 1) * 48 + (i + 1) % 48, (r + 1) * 48 + i)
             for r in range(3) for i in range(48)]
    band = mesh_object("Draped_low_neck_cloth", vertices, faces, colors["scarf"], control)
    solid = band.modifiers.new("Cloth_thickness", "SOLIDIFY")
    solid.thickness = .016
    detail_ellipsoid("Small_left_cloth_knot", (.19, .619, .67), (.10, .038, .075), colors["fold"], control)
    mesh_object("Two_short_left_cloth_tails", [
        (.16, .630, .64), (.25, .638, .65), (.36, .628, .40), (.23, .640, .45),
        (.19, .644, .62), (.14, .638, .61), (.02, .630, .46), (.11, .645, .43)
    ], [(0, 1, 2, 3), (4, 5, 6, 7)], colors["scarf"], control)
    return control


def make_bag(root, colors: dict):
    control = empty("Leaf_satchel__anatomical_right", root)
    center_x, center_z = -.49, .52
    outline = []
    for i in range(40):
        angle = math.tau * i / 40
        radius = 1.0 - .45 * math.exp(-((angle - math.pi / 2) / .14) ** 2)
        outline.append((center_x + .34 * math.cos(angle) * radius,
                        center_z + .32 * math.sin(angle) * radius))
    vertices = [(x, y, z) for y in (-.676, -.787) for x, z in outline]
    faces = [tuple(reversed(range(40))), tuple(range(40, 80))]
    faces += [(i, (i + 1) % 40, (i + 1) % 40 + 40, i + 40) for i in range(40)]
    bag = mesh_object("Rounded_lily_bag_with_notch", vertices, faces, colors["leaf"], control, subdivision=0)
    bevel = bag.modifiers.new("Rounded_sewn_leaf_edge", "BEVEL")
    bevel.width, bevel.segments = .016, 3
    for edge in range(5):
        angle = math.pi * .27 + edge * math.pi * .39
        cord("Leaf_vein_" + str(edge), [(center_x, -.805, center_z + .045),
             (center_x + .145 * math.cos(angle), -.812, center_z + .145 * math.sin(angle)),
             (center_x + .292 * math.cos(angle), -.800, center_z + .267 * math.sin(angle))],
             .004, colors["edge"], control)
    cord("Leaf_flap_seam", [(center_x - .31, -.805, center_z + .03),
         (center_x, -.813, center_z - .012), (center_x + .31, -.805, center_z + .03)],
         .005, colors["edge"], control)
    cord("Both_attached_shoulder_strap", [(-.73, -.73, .74), (-.58, -.63, 1.04),
         (-.33, -.35, 1.286), (-.14, 0, 1.298), (-.16, .40, 1.20), (-.23, .59, .98),
         (-.28, .68, .71), (-.19, .60, .42), (-.08, .32, .23), (-.06, 0, .20),
         (-.06, -.30, .25), (-.16, -.57, .43), (-.22, -.70, .73)],
         .021, colors["edge"], control)
    detail_ellipsoid("Small_original_wood_toggle", (center_x, -.825, center_z + .028),
                     (.035, .019, .04), colors["wood"], control)
    return control


def make_character() -> dict:
    colors = palette()
    root = empty("Character_v002__X_forward_Y_anatomical_left_Z_up")
    root["status"] = "technical_unapproved"
    body = loft("Continuous_back_shoulders_and_long_blunt_head", [
        (-1.60, .06, .10, .69), (-1.54, .25, .31, .69), (-1.31, .53, .48, .69),
        (-.98, .67, .57, .72), (-.60, .69, .565, .735), (-.25, .65, .545, .74),
        (.10, .58, .51, .72), (.36, .54, .49, .74), (.63, .525, .46, .76),
        (.90, .48, .39, .73), (1.16, .435, .30, .68), (1.39, .39, .24, .645),
        (1.46, .355, .22, .645)], colors["fur"], root)
    assign_body_tones(body)
    body.shape_key_add(name="Basis")
    breath = body.shape_key_add(name="Idle_breath")
    dip = body.shape_key_add(name="Pickup_head_dip")
    pivot = Vector((.15, 0, .73))
    rotation = Matrix.Rotation(.15, 3, "Y")
    for index, vertex in enumerate(body.data.vertices):
        breath.data[index].co.z += max(0, vertex.co.z - .2) * .009
        weight = max(0, min(1, (vertex.co.x - .10) / .32))
        dip.data[index].co = vertex.co.lerp(rotation @ (vertex.co - pivot) + pivot, weight)
    features = empty("Head_features_control", root)
    make_face(features, colors)
    return {"root": root, "body": body, "features": features, "feet": make_feet(root, colors),
            "scarf": make_scarf(root, colors), "bag": make_bag(root, colors)}
