# v003 head/cheek shape and rest-UV paint study

Status: **technical_unapproved**, not PLAYER_MASTER or a selected animation route. The single-view surface experiment does not close ART3-100 or the Stage 3 visual gate.

## Geometry revision

[The v003 native shape script](../../../tools/art/probe_player_shape_v003.py) reads the preserved v002 model with an exact source `.blend` hash. It shortens the long taper of the head, adds a broad cheek/muzzle mass after a small shoulder valley, deepens the lower contour, repositions existing face details and narrows/deepens the nasal patch. The same camera, lights, palette, foot controls, scale and ground pivot remain. It does not overwrite any prior `.blend` or source layer. Original shape-key deltas are retained only as provisional controls and are **not** requalified as correct v003 motions.

Actual Blender 4.5.13 LTS/Cycles CPU/32-sample runs on 2026-09-29: `build/art-pipeline/player_shape_v003/preview_20260929` first direction (nose still too stripe-like); `four_views_20260929` four standing directions after a smaller nasal patch, exit 0. Source snapshots are saved in each output. The latter manifest SHA is `057c5634be5c8469e9f17385838924df7ab663ba0446dbb7d29177ac0d0e69ff`; editable blend SHA `d85bef8b195b8793bbe576db71c9381ba8d8b25accbb5978a434685c0e5e9e46`. `four_views_gpu_20260929` then captured all four in the same 1280×720 Godot Compatibility home, exit 0. The raw four directions were inspected; the overly tapered head is reduced, but the broad rounded face is still a simplified model form, not accepted adult character anatomy or painting.

## Controlled paintover

The [exact two-input prompt](PROMPTS.md) explicitly assigns the native render as geometry/framing target and clean AG4 as paint-handling reference. The original output and a byte-identical native target are preserved in this directory via Git LFS. The [manifest](MANIFEST.json) records both source hashes, native generator hash, original render manifest hash and local reproduction limits. No old quarantined image or user reference was used.

The tool returned 1254×1254 RGBA instead of the target's 512 square. Normalizing only for **analysis**, Alpha >128 overlap IoU is `0.9767724336`; 2.3075% of the painted visible mask lies outside the native target, and about 0.0160% of the target is missing. There are faint low-Alpha pixels away from the intended body; nonzero-Alpha bbox is (19,20,1230,1236), while the border maximum is 0. The paintover therefore **cannot be approved or directly exported as the character sprite**. Eye/edge details are also not proven pixel-invariant. No crop, erase, repaint or other raster correction was applied to hide these differences.

## Rest-UV projection trial

[The Blender projection script](../../../tools/art/probe_player_paint_projection.py) fixes UVs at the original rest pose. It uses the actual native camera projection and ray visibility with surface-facing weights, leaving hidden/back-facing surfaces on their original material. Paintover Alpha gates the blend, and native geometry determines the final silhouette. The emissive paint branch avoids lighting the already shaded color field twice with another direct light; the scene still applies its AgX display transform, so this is not a color-exact paintover round trip. Curves keep their original material because they have no paint visibility attribute. The original editable source remains intact, and the projection study writes a new packed `.blend`.

Actual `build/art-pipeline/player_paint_projection_v001/first_20260929` rendered rest and small breath extrema, exit 0, on the same 512 canvas and 0.5 world scale. Visibility mapping covers 1373 of 7200 control vertices across 35 meshes; this count is not surface-coverage or quality approval. `first_gpu_20260929` captured both states in the same real Godot 4.7.2 Compatibility / RTX4060 Laptop GPU home, exit 0. The static and breath PNGs were inspected: directional painted fur is more coherent than the earlier box-texture trial, and no large new shoulder seam is obvious in this tiny deformation. This observation does **not** establish complete idle or any walk/pickup/soak acceptance.

The render manifests retain every image hash and source/blend hash. The projection script snapshot is stored beside its output. These `.blend`/GPU artifacts remain local ignored build evidence; clean checkout regenerates them. Only the native target and original paintover PNGs are distributed as unapproved candidates.

## Remaining gaps and next step

Only the down-right surface is painted. Hidden surfaces, grazing transitions, moving accessory occlusion, turns and color consistency across independent directions still need controlled source views and texture-bake review. Fixed visibility masks must not be reused blindly when motion reveals a previously hidden region. The current ray test distinguishes occluding objects but does not disambiguate self-occlusion between different faces of the same mesh; that is an additional required refinement before accepting projection coverage. The old v002 two-cycle foot result is not v003 animation evidence. The candidate remains too provisional for formal entry integration.

Continue on this **same** editable route: validate projection seams and control the missing material regions before expanding a full animation set. Keep one representative view at the original game scale as the style check, preserve all rejected attempts, and do not declare a final mother image from a single appealing static render.
