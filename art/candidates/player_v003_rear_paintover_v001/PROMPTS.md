# Rear-view controlled paint source

- Prompt ID: PLAYER-V003-REAR-PAINT-A-20260930. Built-in imagegen; exact model not disclosed.
- Native up-left target SHA `f009aee9341456d66412b7e112edc3ed012a8ae95641e5812cbcc85cbbd913a2`.
- Style-only reference: down-right paintover SHA `06781018de02905d017667e0bb03c3a3fde82a2c164ba8153dfa281ab3a4201a`; its native/AG4 parents remain recorded in the original manifest.
- Rear output SHA `c7c384daf098b66950df8d42c124708a40304989b717193174449affa14b2d1b`, 1254 square RGBA. Original bytes retained without pixel editing.
- Raw composition shifted vertically. UV registration is declared separately and does not approve a master/sprite.

## Exact prompt

```text
Use case: tightly controlled surface paintover for an original editable game model.
Input image 1 is the EXACT EDIT TARGET: a native 35-degree orthographic up-left/rear view of our original capybara model on transparency.
Input image 2 is a PAINT AND PALETTE REFERENCE ONLY: our previously painted down-right view of the SAME original model. Transfer its restrained warm grey-brown gouache fur, teal cloth handling and olive accessories. Do not borrow its front-view geometry or pose.
Repaint only the surface colors/material description of image 1. Keep its geometry, exact pose, relative sizes, small visible side eye, round ears, all feet, scarf knot and shoulder strap precisely where they are. It is looking up-left, viewed mainly from behind. Keep the large rounded rear body and partly hidden small olive bag as originally shown. Do not add a tail, extra limbs, eyes on the rear, new accessories, fruit, lettering or logo.
Canvas invariants: keep the square framing and large transparent upper margin. The original visible object occupies normalized x about 0.240 to 0.781 and y 0.391 to 0.914. Keep its pivot at (0.5,0.75). Do not crop, zoom, recenter, rotate or change the 35-degree camera. Repaint within the existing silhouette, retaining true RGBA transparency outside it, with no ground shadow, background, checkerboard, halo or stray opaque marks.
Painting: refined non-photorealistic gouache with subtle short directional fur marks following the rump and back, slightly finer marks on the head; muted earthy grey-brown and subdued ochre/umber, not orange. Match image 2's pigment scale and color family. Describe gentle anatomical planes with quiet broad underpainting, avoiding evenly noisy fuzz or wood-grain stripes. Teal scarf and green strap have restrained painted fabric/leather variation without changing their outlines. The unpainted-model plastic impression should be replaced by coherent storybook paint.
No existing IP, no artist imitation, no watermarks. Output one surface-only paintover matching the rear-view target composition, with true transparent background.
```
