# PLAYER_CAPYBARA_V1 清洁文字链视觉轮 02

日期：2026-09-03
工具：OpenAI ImageGen built-in
输入：仅原创文字设定；未向生成工具提供用户附件、旧隔离图、第三方角色或风格图。

## CHAR-CLEAN-AG1

```text
Use case: stylized-concept
Asset type: original protagonist character concept for a high-resolution non-pixel 2D cozy Godot game
Primary request: Create one exceptionally appealing, cute but anatomically unmistakable original capybara character. This is a fresh text-only design; do not use or imitate any attached or previously shown image.
Scene/backdrop: simple warm cream presentation background, no environment, no props, no text
Subject: a low, long, heavy barrel-shaped capybara in calm standing pose, 3/4 view with a gentle slight top-down game camera. The belly hangs close to the ground. Four legs are extremely short, sturdy, and mostly tucked beneath the torso; only small dark feet show. The neck is almost invisible because the broad head flows directly from the shoulders. The muzzle is wide, blunt, rectangular-oval, and distinctly capybara-like, with a dark nose at the very front. Eyes are small, dark, almond-shaped, placed high on the head. Ears are very small, rounded, widely spaced, and set toward the back/top of the head. Back is softly arched and rump is full. No visible tail.
Character details: warm gray-brown fur; left ear has a very subtle outward fold; a lake-teal waterproof scarf lies low around the shoulders with a small side knot, never like a collar or headband; a small lily-pad-shaped cross-body satchel with real side thickness and strap, clearly separate from the body
Style/medium: polished original children's storybook character design, soft hand-painted gouache and restrained painterly shading, clean readable silhouette, sophisticated and charming, cozy rather than babyish, high finish suitable for a character art bible
Composition/framing: whole body centered with generous margins, all four small feet visible enough to understand stance, no cropping
Lighting/mood: soft upper-left daylight, peaceful, gently humorous, warm
Color palette: muted warm taupe and chestnut, lake teal, moss/lily green, dark warm brown line accents; bright but not saturated
Materials/textures: subtle short coarse capybara fur texture, woven scarf, matte waterproof satchel
Constraints: unmistakably a capybara; body length clearly greater than body height; leg visible length less than one sixth of torso height; small eyes and tiny ears; no oversized head; no long neck; no prominent cheeks; no baked shadow; no logo, watermark, signature, readable text, fruit, shorts, hat, collar, or extra accessories
Avoid: dog, puppy, guinea pig, hamster, mouse, bear, otter, rabbit, long legs, thin legs, pointed ears, floppy dog ears, huge sparkling pet eyes, spherical body, upright posture, plush-toy proportions, photorealism, 3D plastic render, pixel art, anime, thick black outline, headband-like scarf, badge-like bag, extra limbs, malformed feet
```

结果：`generated_raw` AG1 为 1402×1122 RGB。独立视觉审查确认其长低桶状体、宽钝口鼻、小眼和极短腿在 144 px 仍保持水豚身份；错误朝向、复杂耳形、大披肩围巾与密集毛纹必须在技术重绘中替换。

## CHAR-CLEAN-AH1

```text
Use case: stylized-concept
Asset type: original protagonist character concept for a high-resolution non-pixel 2D cozy Godot game
Primary request: Create one polished, charming, anatomically unmistakable original capybara character from text only. This is a new design; do not use or imitate any attached or previously shown image. Correct the common mistakes of an oversized potato body, cape-like scarf, oversized head, and side-profile camera.
Scene/backdrop: plain warm cream presentation background, no environment, no props, no text
Subject: a compact but clearly long-bodied adult capybara standing calmly in a readable 3/4 top-down game view, facing down-right. Body is a low rounded rectangle/bean with a gently arched back; body length about 1.7 times body height, belly close to the ground but not touching it. All four legs are extremely short, thick, dark, and mostly hidden beneath the body, with just enough separation to animate a walk. The broad wedge-shaped head flows from the shoulders with almost no visible neck. Muzzle is wide, blunt, and boxy-oval, not round. Nose is small and dark at the front. Eyes are small, dark, calm, and placed high on the head with one restrained highlight. Ears are tiny, rounded, widely spaced, set toward the back/top; left ear has a slight outward fold. No visible tail.
Character details: warm gray-brown coarse fur; a narrow lake-teal waterproof scarf rests low around the shoulders, with a small asymmetrical knot on the character's left side and two short tails, never covering the back and never resembling a cape, collar, or headband; a small lily-pad cross-body satchel sits low on the far flank with visible side thickness, short strap, and a subtle notch
Style/medium: sophisticated original children's storybook illustration, soft gouache with clean shape design and restrained fur strokes, cozy, expressive, and cute without baby-animal proportions; high-end 2D game character art bible finish
Composition/framing: whole body centered with generous transparent-looking cream margin, facing down-right; top planes of back, head, muzzle, scarf, and satchel visibly readable; no cropping
Lighting/mood: soft daylight from upper left, calm and quietly cheerful
Color palette: muted warm taupe and chestnut, lake teal, moss green, deep warm brown; natural and moderately bright
Materials/textures: subtle coarse capybara fur, matte woven waterproof scarf, soft structured satchel
Constraints: unmistakably capybara; true 3/4 top-down view; head smaller than one third of total silhouette length; torso not spherical; visible leg length less than one fifth of body height; four short feet; tiny round ears; small eyes; wide boxy muzzle; no baked cast shadow; no text, logo, watermark, signature, fruit, shorts, hat, collar, cape, or extra accessories
Avoid: dog, puppy, guinea pig, hamster, mouse, bear, otter, rabbit, giant potato body, oversized head, round cheeks, long or thin legs, pointed/floppy ears, large sparkling eyes, side profile, upright posture, plush toy, photorealism, 3D plastic render, pixel art, anime, thick black outline, scarf covering back, headband scarf, badge bag, extra limbs, malformed feet
```

结果：`generated_raw` AH1 为 1334×1179 RGB。其 down-right 俯视关系较清楚，但独立视觉审查在 144 px 复现物种漂移：宠物眼、收窄脸、不规则耳和头套式围巾使其接近豚鼠/海狸鼠，因此保持 `rejected_visual`，不得进入活动候选或成为图像参考。
