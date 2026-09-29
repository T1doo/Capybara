# Route B v002 — editable shape and one-direction gait study

Status: **technical_unapproved / comparison_incomplete**. This is a revision of the existing Blender route, not a new production pipeline or a PLAYER_MASTER approval. Stage 3 remains in progress.

## Source and scope

The original [v001 review](../../art/candidates/player_animation_ab_v001/REVIEW.md) remains valid historical evidence. Its script and `.blend` were not overwritten. New source is split into [renderer](../../tools/art/build_player_mesh_v002.py), [geometry](../../tools/art/player_mesh_v002_geometry.py), [materials](../../tools/art/player_mesh_v002_materials.py) and [motion](../../tools/art/player_mesh_v002_motion.py); v001's original mesh/camera utilities are reused and hashed in each render manifest. No reference image, third-party model or texture is loaded. Clean project anatomy guidance remains AG1; clean AG4 was visually inspected, not projected onto the model. No quarantined image or user reference is used.

Changes include a continuous longer head/shoulder mesh, a small upper muzzle bridge instead of the old oval nose plate, cupped ears, small side eyes, short tapered legs with three toes, a draped lower scarf and a rounded lily bag with a complete shoulder strap. Body vertex colors define broad warm fur zones; object-space procedural pigment reduces uniform color. These are editable original geometry/material instructions, not a claim of human-painted art.

All output remains in ignored `build/art-pipeline/player_mesh_v002/`. Nothing was added to `game/assets`, `art/approved` or `art/source_layers`.

## Executed evidence — 2026-09-29

Source baseline: `f5fb86a14e7c034953945a901cbb96f100ef1848` plus the new uncommitted v002 sources. The baseline's [exact Windows CI 36558684608](https://github.com/T1doo/Capybara/actions/runs/36558684608) succeeded; it does not cover this implementation. New implementation CI must be verified separately after commit.

| Evidence | Actual result |
|---|---|
| `four_views_walk_20260929_r3/render_manifest.json` | SHA-256 `989a0601665b2e920283853322cb148aea6913802013a722f5a7ed2835521a52`; 4 standing directions + 18 down-right walk frames; Blender 4.5.13 LTS Cycles CPU, 32 samples, 4 threads; generation 60.22 seconds including calibration/save |
| Editable `player_mesh_v002.blend` in that directory | SHA-256 `9c31e71670d8f1dd21a22e0d3115a03cf8304bad174c87abc3fa85ba4d799e64`; source/material/shape controls retained; not a finished animation rig |
| Fixed image geometry | 512×512 true RGBA, 22/22 empty Alpha borders; camera pitch 35°, ground-origin pivot (256,384), display scale 0.5; one standing down-right calibration near 288 native px, then unchanged across all views/frames |
| `static_gpu_20260929/capture_manifest.json` | Four actual 1280×720 Compatibility GPU views in the existing home, fixed camera (0,-96), player (64,0), same 0.5 scale; exit 0; all four images visually inspected |
| `walk_gpu_20260929_r4/walk_probe.json` | SHA-256 `e3b48e28f5f75fd8d3ab236b9e9eaf6f5c667ae2080974c42893440da8181a47`; Godot 4.7.2 / NVIDIA RTX4060 Laptop GPU, real Player movement and collisions, synthetic down/right Input actions, unchanged 240 px/s, 36 physics ticks / two cycles; exit 0 |
| [Independent saved-evidence checker](../../tools/art/check_player_mesh_v002.py) | Recomputes all source/blend/frame hashes and Alpha bboxes, reconstructs GPU foot transforms and real displacement instead of trusting `passed`; 64 stance comparisons, maximum marker drift `0.00001706 px/tick`, maximum movement error `0.00000326 px/tick`; exit 0 |

The 35° camera compresses one ground-plane axis. The v001 yaw angles 0/-90/90/180 do not project to 45° screen diagonals. v002 explicitly inverts that projection before choosing anatomical yaw, and computes step length from the actual Blender camera projection at fixed display scale. This changes actor yaw relative to v001 while retaining the camera/pivot protocol; do not call the two silhouettes an identical-pose comparison. Accessories remain fixed to anatomical sides, with no mirroring.

The gait keeps each stance sole stationary against the real Player's translation. During swing, the ankle/toes move while the upper leg stays at its hip; contact velocity is continuous at the cycle boundary. Markers locate the authored toe soles. They are **not** image-inferred contacts or proof that every visible rendered foot/occlusion is artistically correct. The GPU fixture uses a shared approximate static ground shadow, not individual animated contact shadows. Screenshot capture may cover multiple physics ticks; `requested_tick` and actual `render_tick` are recorded separately. This is not a 60 fps performance measurement or a complete movie review.

## Visual decision

The four actual home screenshots still show a smooth model sample. The rounded bag and individual toes are more legible, and the two accessory sides are coherent. However, the head/back remain overly regular, the scarf reads as a narrow band, and fine procedural pigment mostly disappears at the game size. The head does not yet carry AG1/AG4's painted muzzle/cheek structure. **AB-VIS-003 and AB-VIS-004 remain unresolved.** Adding more noise or choosing B only because its contact math passes would not meet the art contract.

Only one direction has a two-cycle walk probe. No eight-direction traversal, continuous idle/pickup/soak set, turns, slope/terrain support, final foot shadows, runtime atlas/import/memory budget, clothing-extension production-cost trial, physical controller or independent visual acceptance has been completed. `ART3-100`, `CAP-0502` and `CAP-0503` retain their existing statuses. Do not expand two complete animation pipelines before the representative surface/shape reaches the target art standard.

Next bounded task: improve one representative model surface/face using controlled original painterly material work and inspect it at 144px. Preserve this gait/camera calibration for later directions; do not generate unrelated per-frame images or lower movement speed.

## Failures retained

- `shape_probe_20260929` is the first single-view shape attempt; it uses the earlier yaw and has an unfinished opposite-side strap. It is superseded for comparison, not deleted.
- `four_views_walk_20260929` stopped after calibration with a Python `TypeError` (`Vector.length` is a property). Blender defaulted to process exit 0 despite the traceback. The failure is not treated as passing. Subsequent runs use `--python-exit-code 1`; `_r2` rendered successfully, then `_r3` repaired the complete strap and rendered all 22 frames again.
- First GPU invocation failed parsing a method call in a constant expression. Second failed before movement because JSON float arrays were compared with integer arrays. Both logs remain in `build`; neither is a gameplay regression or a pass.
- `walk_gpu_20260929_r3` genuinely failed: maximum movement/contact error 4 px/tick. Its recording driver auto-enabled on entering the tree and recorded 24 warm-up ticks while Player was disabled. Disabling the driver **after** adding it corrected the fixture; `_r4` actually passed with original move speed and collisions. No tolerance or game movement was weakened.

## Reproduction

Use the pinned Blender 4.5.13 LTS executable, with a **new** output directory under repository `build`:

```powershell
& $blenderBin --background --factory-startup --python-exit-code 1 --python tools/art/build_player_mesh_v002.py -- --output-dir build/art-pipeline/player_mesh_v002/new_run --samples 32 --threads 4 --walk-probe
& $env:GODOT_BIN --path game --script res://../tools/art/probe_player_mesh_walk.gd -- $absoluteRenderManifest $newAbsoluteGpuOutput
python tools/art/check_player_mesh_v002.py $absoluteRenderManifest $newGpuReport
```

The render manifest has a hash for every required source and frame. GPU and render outputs are local evidence; a clean checkout must regenerate them. Preserve old run directories, and inspect all directions plus stance/swing extremes in the actual home before making a new visual decision.
