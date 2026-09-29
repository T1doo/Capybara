"""Original object-space pigment study. No image texture or external asset is loaded."""

import bpy


def pigment(name: str, color: tuple, use_fur_tone: bool = False,
            stroke_scale: tuple = (3.0, 13.0, 16.0)):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    shader = nodes.get("Principled BSDF")
    shader.inputs["Roughness"].default_value = 1.0
    shader.inputs["Specular IOR Level"].default_value = .035
    shader.inputs["Emission Strength"].default_value = .13
    coords = nodes.new("ShaderNodeTexCoord")
    scale = nodes.new("ShaderNodeVectorMath")
    scale.operation = "MULTIPLY"
    scale.inputs[1].default_value = stroke_scale
    links.new(coords.outputs["Object"], scale.inputs[0])
    grain = nodes.new("ShaderNodeTexNoise")
    grain.inputs["Scale"].default_value = 6.0
    grain.inputs["Detail"].default_value = 2.0
    grain.inputs["Roughness"].default_value = .65
    links.new(scale.outputs[0], grain.inputs["Vector"])
    tones = nodes.new("ShaderNodeValToRGB")
    tones.color_ramp.elements[0].position = .25
    tones.color_ramp.elements[0].color = (.70, .65, .60, 1)
    tones.color_ramp.elements[1].position = .76
    tones.color_ramp.elements[1].color = (1.16, 1.09, .99, 1)
    links.new(grain.outputs["Fac"], tones.inputs[0])
    multiply = nodes.new("ShaderNodeMixRGB")
    multiply.blend_type = "MULTIPLY"
    multiply.inputs[0].default_value = .56
    multiply.inputs[1].default_value = (*color, 1)
    if use_fur_tone:
        attribute = nodes.new("ShaderNodeVertexColor")
        attribute.layer_name = "FurTone"
        links.new(attribute.outputs["Color"], multiply.inputs[1])
    links.new(tones.outputs["Color"], multiply.inputs[2])
    links.new(multiply.outputs[0], shader.inputs["Base Color"])
    links.new(multiply.outputs[0], shader.inputs["Emission Color"])
    bump = nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = .075
    bump.inputs["Distance"].default_value = .012
    links.new(grain.outputs["Fac"], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], shader.inputs["Normal"])
    return mat


def palette() -> dict:
    return {
        "fur": pigment("Fur__authored_tone_zones_and_directional_pigment", (.32, .19, .10), True),
        "limb": pigment("Short_limb_warm_umber", (.29, .165, .085)),
        "foot": pigment("Dark_toes_and_pads", (.125, .074, .046), stroke_scale=(9, 9, 9)),
        "nose": pigment("Muted_muzzle_leather", (.18, .115, .077), stroke_scale=(12, 12, 12)),
        "eye": pigment("Small_calm_dark_brown_eye", (.024, .013, .007)),
        "inner": pigment("Warm_inner_ear", (.205, .11, .067)),
        "glint": pigment("Small_cream_eye_glint", (.80, .70, .49)),
        "scarf": pigment("Lake_teal_cloth", (.056, .245, .26), stroke_scale=(18, 6, 18)),
        "fold": pigment("Teal_cloth_fold", (.044, .19, .20), stroke_scale=(18, 6, 18)),
        "leaf": pigment("Olive_lily_satchel", (.235, .285, .085), stroke_scale=(8, 8, 8)),
        "edge": pigment("Quiet_leaf_seams", (.145, .19, .050)),
        "wood": pigment("Wood_toggle", (.46, .285, .100)),
    }


def assign_body_tones(body) -> None:
    """Broad anatomy-dependent zones, independent of camera and shared by all views."""
    tones = body.data.color_attributes.new(name="FurTone", type="FLOAT_COLOR", domain="POINT")
    for vertex, entry in zip(body.data.vertices, tones.data):
        x, y, z = vertex.co
        top = max(0.0, min(1.0, (z - .30) / .95))
        muzzle = max(0.0, min(1.0, (x - .83) / .65))
        flank = min(1.0, abs(y) / .68)
        entry.color = (.25 + .115 * top + .025 * muzzle - .015 * flank,
                       .135 + .081 * top + .023 * muzzle,
                       .064 + .048 * top + .012 * muzzle, 1)
