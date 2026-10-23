# Rear color source — unapproved

The target is the original v003 up-left native render; the existing clean down-right paintover supplies paint handling only. Source hashes and the unchanged native generator are recorded in MANIFEST.json. No quarantined input is used. There is no game path.

Raw normalized Alpha>128 IoU is 0.8494628321 because the generated composition shifted vertically. Translation-only analysis found a native-to-paint shift of (+4,-29) pixels on the 1254 square, improving IoU to 0.9799096775. This supports a limited UV registration, not invariance of all interior features. UV offset (4/1254,+29/1254) accounts for bottom-origin UVs; source pixels and geometry remain unchanged. The raw RGBA cannot be directly approved as a sprite.

Front/rear paints have separate fixed rest UVs and visibility weights. The 2026-09-30 study filled much of the previously plain rear region; the 2026-10-23 v004 sample must still test overlap color, grazing edges, face details and areas exposed by pickup/turn. Actual sample completion belongs in Stage3 LOG, not this source record. The input paint is sRGB; Standard versus AgX color-chip results do not alone prove all fallback material or four-atmosphere consistency.
