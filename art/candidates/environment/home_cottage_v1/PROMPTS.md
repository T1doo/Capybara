# HOME_COTTAGE_V1 提示词记录

日期：2026-09-03
工具：OpenAI ImageGen built-in
参考：项目内 `home_visual_a1`，只用于色板、材质、相机和光向。

## ENV-HOME-COTTAGE-A1

```text
Use case: stylized-concept
Asset type: isolated transparent modular cottage candidate for an original high-resolution non-pixel 2D/2.5D cozy Godot game
Primary request: Generate one completely original waterside homestead cottage as a clean isolated game asset. Use Image 1 only as the project's own approved visual-direction reference for palette, soft gouache material, upper-left lighting, and approximately 35-degree 3/4 top-down weak-orthographic camera. Do not crop, trace, extract, or reproduce the exact house or scene layout from Image 1.
Input images: Image 1 is a style/palette/camera reference only; it is not an edit target and no pixels should be copied
Scene/backdrop: genuinely transparent RGBA canvas; no environment, grass, path, plants attached to the ground, frame, checkerboard, halo, colored matte, platform, or cast shadow
Subject: one compact cozy cottage designed for a broad-bodied capybara resident. A clear single front entrance faces down-left/downward toward the player, with a wide low wooden door, shallow two-step threshold, cream lime-plaster walls, warm honey-brown exposed timber framing, a deep mossy lake-teal shingle roof, one small dormer, one simple stone chimney, and two readable windows with teal-gray glass. The footprint should feel about six 64px grid cells wide and four cells deep after game scaling. Roof overhangs are structurally plausible. Door, windows, beams, shingles, chimney, steps, gutters, and wall corners must connect coherently. Include only restrained integrated details such as one flower box and a tiny hanging rain chain; no loose props.
Style/medium: premium original children's storybook game asset, hand-painted gouache with broad controlled shapes, restrained watercolor variation, subtle paper grain inside opaque forms, polished and charming, non-pixel, production-readable at game scale
Composition/framing: complete building centered with generous true transparent padding, fixed 35-degree 3/4 top-down weak perspective, roof top plane and front/side wall planes clearly visible, no cropping, no horizon
Lighting/mood: soft daylight from upper left; all form shading falls gently lower right; no baked ground shadow
Color palette: match only the general A1 palette family—cream plaster, honey timber, mossy lake teal roof, muted sage accents, warm gray stone; natural and restrained
Technical constraints: true clean alpha-zero background; no glow or fringe; one building only; no text, numbers, symbols, logo, signboard, watermark, signature, character, animal, scenery, ground shadow, fog, sky, or UI; architecture must be physically coherent; silhouette must remain readable when displayed around 420–520px wide; source should support later manual separation of roof, walls, door, windows, chimney and steps
Avoid: copying the exact A1 house, resemblance to a specific existing game, generic 3D render, plastic material, photorealism, pixel art, isometric voxel style, black outline, fisheye, strong vanishing perspective, multiple competing front doors, impossible roof junctions, warped windows, floating beams, merged chimney, illegible shingles, dense vines, excessive flowers, background remnants, fake checkerboard transparency, halo, cast shadow
```

## ENV-HOME-COTTAGE-A1-BG-EXTRACT

```text
Use case: background-extraction
Asset type: transparent isolated cottage game-asset candidate
Primary request: Remove only the entire pale checkerboard background and replace it with genuine alpha-zero transparency.
Input images: Image 1 is the exact edit target. Preserve the cottage itself.
Constraints: change only the background; preserve the cottage's silhouette, architecture, roof, chimney, dormer, beams, plaster, windows, front door, steps, flower box, rain chain, colors, painterly texture, camera angle, lighting, scale, position, and every building detail exactly. Preserve the complete building without cropping. Keep generous transparent padding. Do not repaint, redesign, enlarge, shrink, rotate, relight, sharpen, simplify, or add anything. No ground and no cast shadow.
Technical requirement: output must be a true 32-bit RGBA PNG with alpha-zero pixels everywhere outside the cottage. No white matte, checkerboard, paper, colored background, glow, halo, fringe, dust, stray pixels, text, watermark, or signature.
```
