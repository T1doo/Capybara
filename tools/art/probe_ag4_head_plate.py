"""Diagnose one AG4 head/neck cutout against its unapproved clean plate.

This is a review fixture, not a character rig or game-ready asset. It preserves
the original canvas and leaves all unmasked source pixels bit-for-bit intact.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "art/candidates/player_ag4_v001/chr_player_ag4_down_right_v001.png"
PLATE = ROOT / "art/candidates/player_ag4_body_plate_v001/body_clean_plate_v001.png"
OUTPUT = ROOT / "build/art-pipeline/ag4_head_plate_probe_20260923"
EXPECTED = {
    "source": "e92cd4791957b4db13b65b1c8865c574a54975b907647088de26e8edd7975521",
    "plate": "5da7f8328e08bef767a2e12053968772f86b5976390ada7543fb2eb9f56f4395",
}

# Broad cut around the entire head and neck wrap. This intentionally tests the
# dangerous shoulder reveal; it is not a production contour or limb segmentation.
HEAD_AND_WRAP = [
    (795, 299), (873, 303), (958, 315), (1037, 342), (1111, 392),
    (1172, 464), (1222, 541), (1240, 612), (1232, 673), (1209, 717),
    (1168, 744), (1111, 752), (1071, 771), (1012, 787), (940, 775),
    (871, 750), (819, 725), (772, 684), (724, 622), (702, 553),
    (709, 465), (751, 382),
]


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def save_preview(image: Image.Image, path: Path) -> None:
    bbox = image.getbbox()
    if bbox is None:
        raise ValueError("Empty composite")
    crop = image.crop(bbox)
    crop.thumbnail((256, 256), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (320, 280), (111, 147, 111, 255))
    canvas.alpha_composite(crop, ((320 - crop.width) // 2, 12))
    canvas.convert("RGB").save(path)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=OUTPUT)
    args = parser.parse_args()
    for label, path in (("source", SOURCE), ("plate", PLATE)):
        if sha256(path) != EXPECTED[label]:
            raise ValueError(f"{label} is not the reviewed exact image")
    source = Image.open(SOURCE).convert("RGBA")
    plate = Image.open(PLATE).convert("RGBA")
    if source.size != plate.size or source.size != (1402, 1122):
        raise ValueError("AG4 source and plate must share original 1402x1122 canvas")
    args.output.mkdir(parents=True, exist_ok=True)

    hard_mask = Image.new("L", source.size, 0)
    ImageDraw.Draw(hard_mask).polygon(HEAD_AND_WRAP, fill=255)
    soft_mask = hard_mask.filter(ImageFilter.GaussianBlur(3))
    head = Image.new("RGBA", source.size)
    head.paste(source, (0, 0), soft_mask)
    # Only the masked area receives generated underpainting. Every source pixel
    # outside the mask is untouched in the static background.
    background = Image.composite(plate, source, soft_mask)
    neutral = Image.alpha_composite(background, head)
    background.save(args.output / "background_plate_roi.png")
    head.save(args.output / "head_wrap_cutout.png")
    neutral.save(args.output / "neutral.png")

    shifts = [("raise_12", 0, -12), ("lower_12", 0, 12), ("forward_12", 12, 0)]
    for label, dx, dy in shifts:
        moved = Image.new("RGBA", source.size)
        moved.alpha_composite(head, (dx, dy))
        result = Image.alpha_composite(background, moved)
        result.save(args.output / f"{label}.png")
        save_preview(result, args.output / f"{label}_preview.png")
    save_preview(source, args.output / "source_preview.png")
    save_preview(neutral, args.output / "neutral_preview.png")
    info = {
        "source_path": SOURCE.relative_to(ROOT).as_posix(),
        "source_sha256": EXPECTED["source"],
        "plate_path": PLATE.relative_to(ROOT).as_posix(),
        "plate_sha256": EXPECTED["plate"],
        "canvas": list(source.size),
        "mask_polygon": HEAD_AND_WRAP,
        "mask_feather_px": 3,
        "shifts_native_px": shifts,
        "status": "technical_probe_only_unapproved",
        "limitations": [
            "Broad head-and-wrap mask is not production segmentation.",
            "Original visible feet, bag and torso remain in the stationary background.",
            "Motion probes do not establish walk, foot locks, or four directions.",
        ],
    }
    (args.output / "probe.json").write_text(json.dumps(info, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"output": str(args.output), "status": info["status"]}))


if __name__ == "__main__":
    main()
