# Controlled v003 surface paintover

- Prompt ID: PLAYER-V003-PAINT-A-20260929.
- Tool: built-in imagegen; exact model not disclosed. One call with transparency requested.
- Input 1: original native v003 render, copied byte-identically as `native_target_v003.png`; SHA `11183b4bdb8d7bd22483f2e7efb09c75fb1534576d541b14d5f9e8420adfed4d`.
- Input 2: clean project AG4, used for paint handling only; SHA `e92cd4791957b4db13b65b1c8865c574a54975b907647088de26e8edd7975521`.
- Output: 1254×1254 RGBA, `paintover_a_v001.png`, SHA `06781018de02905d017667e0bb03c3a3fde82a2c164ba8153dfa281ab3a4201a`. Raw bytes preserved under ignored `art/generated_raw/player_paintover/`. No manual pixel editing; no game path or approval.

## Exact prompt

```text
Use case: style-transfer / tightly controlled texture paintover.
Asset type: one unapproved paintover candidate for an ORIGINAL editable capybara game model, intended as a later texture-paint reference, NOT a newly designed character.
Input image 1 is the EDIT TARGET: our own orthographic 3D capybara render on real transparency. Input image 2 is ONLY a CLEAN ORIGINAL PROJECT STYLE REFERENCE for soft gouache fur, expressive painted eyes and crafted material rendering. Do NOT copy its different body proportions, camera, silhouette, framing or accessory placement.
Primary request: repaint only the surface appearance of image 1 into beautiful coherent warm gouache storybook brushwork, with deliberate fur direction and subtle muzzle/cheek/eyelid shading. Preserve image 1's exact geometry and drawing coordinates: head length/width, body silhouette, rounded ears, all feet positions, small eyes, small muzzle, scarf band and its fixed left-side knot, right-side lily satchel and complete shoulder strap. Do not enlarge the eyes or add eyelashes. Anatomically these are the same features already present, only with skillful painted material description.
COMPOSITION INVARIANTS: retain the original square canvas and the large empty transparent top margin. In normalized canvas coordinates, the object occupies roughly x 0.218 to 0.759, y 0.332 to 0.895. Its ground pivot stays at (0.5,0.75). Do NOT crop, zoom, recenter, rotate, change the 35-degree orthographic view or change the pose. Nothing may extend beyond the original silhouette. Preserve fully transparent pixels outside the subject, with no ground shadow, no backdrop, no checkerboard, no aura, no sheet labels, text or borders.
Style: non-photorealistic, carefully painted opaque gouache pigment and quiet natural short fur; use medium-scale intentional directional brush marks on the torso and smaller softer strokes on the face. Warm muted grey-brown fur with subdued ochre and umber, softly modeled cheek and blunt muzzle planes, small dark warm-brown eye and tiny restrained glint. Teal fabric should read as painted cloth with restrained folds, olive lily-leaf satchel as crafted painted material with quiet veins, short dark-brown toes. Keep the original low-saturation palette close. Avoid generic random noise, woodgrain striping, marbling, glossy plastic shading, photoreal hair and uniform fuzzy covering.
Image 2 may guide PAINT HANDLING ONLY. It must not replace the exact image 1 model. Entirely original project assets, no existing IP, artist imitation, logo or signature. Output one exact-framing RGBA paintover with true transparent background.
```
