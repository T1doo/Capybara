# 阔叶树冠材质

日期：2026-09-12。提示词：FOLIAGE-MATERIAL-001。生成方式：内置 ImageGen，一次生成，无输入图片、外部 API 或付费依赖。

用途：原生有机树冠网格内的笔触与叶簇，不是透明树、不作为整幅背景；不要求无缝平铺。沿用 WORLD_STYLE_MASTER 的苔绿、鼠尾草绿、暖黄绿与左上柔光，不修改用户锁定的角色或家园概念。

原图完整保留；原型仅使用独立网格轮廓、受限UV和运行时明暗/对比着色。禁止把该不透明方图直接当透明sprite。初次临时文件名中的willow已改成准确的broadleaf，不宣称具体柳树物种。

## 完整提示词

```text
Use case: stylized-concept
Asset type: opaque painted foliage material for an original high-resolution storybook 2D game.
Primary request: one square, edge-to-edge hand-painted texture of a dense broadleaf tree crown. It will be sampled inside separately authored organic canopy silhouettes, not used as a whole tree or background scene.
Subject: small overlapping oval leaves arranged in softly rounded clusters with varied directions and sizes; convincing leafy depth without individually outlined sticker leaves. Dense coverage across the entire canvas, no gaps to sky or ground, no central focal object.
Style/medium: warm gouache and soft impasto picture-book painting, delicate visible brush marks, charming and natural, non-pixel. Subtle texture; avoid photographic leaf veins, glossy plastic, coarse noise, repeated stamped motifs or sharp black outlines.
Lighting/mood: softly diffuse upper-left illumination, lighter sage and warm young-leaf highlights, deep muted olive green recesses; keep the overall tonal range restrained so characters remain readable.
Palette: moss and willow green, muted sage, warm yellow-green highlights, restrained deep blue-green recesses; no neon green.
Composition: square material swatch filling every pixel, leaf detail fairly evenly distributed, no vignette, no borders. No trunks, branches, fruit, flowers, water, buildings or characters. No text, labels, logos, watermarks or checkerboard. Deliberately opaque RGB material, not an alpha sprite. Original design, no existing IP or artist imitation.
```

## 初审

独立 foliage_review 实际查看图片并校验哈希，无可见High，允许通用阔叶原型用途；需实景检查高光/暗孔隙对比、叶尺度与重复。原图无文字、Logo或棋盘，不把其不透明格式当Alpha通过。正式发布批准为false。
