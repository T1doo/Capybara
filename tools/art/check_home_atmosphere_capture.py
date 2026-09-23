"""Validate a four-mood GPU capture against cross-material visual landmarks.

Checks photographed pixels, including unshaded ground/water shaders, rather
than trusting that a preset name or a successful screenshot command implies
the atmosphere actually covers the whole scene.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageStat


ROOT = Path(__file__).resolve().parents[2]
BUILD = (ROOT / "build").resolve()
PRESETS = ("clear_morning", "sunset", "rain", "night")
SOURCE_SHA = "e92cd4791957b4db13b65b1c8865c574a54975b907647088de26e8edd7975521"
LANDMARKS = {
    "painted_ground": (550, 200),
    "cottage_wall": (118, 193),
    "painted_bridge": (1020, 420),
    "painted_water": (1050, 160),
    "ag4_player": (700, 410),
}


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def patch_rgb(image: Image.Image, x: int, y: int) -> tuple[float, float, float]:
    return tuple(ImageStat.Stat(image.crop((x - 5, y - 5, x + 5, y + 5))).mean[:3])


def luminance(rgb: tuple[float, float, float]) -> float:
    return rgb[0] * 0.2126 + rgb[1] * 0.7152 + rgb[2] * 0.0722


def verify(directory: Path) -> dict:
    folder = directory.resolve()
    if not folder.is_relative_to(BUILD) or not folder.is_dir():
        raise ValueError("Capture must be an existing build directory")
    manifest = json.loads((folder / "capture_manifest.json").read_text(encoding="utf-8"))
    if manifest.get("ag4_sha256") != SOURCE_SHA or manifest.get("mode") != "Compatibility GPU":
        raise ValueError("Capture provenance or renderer mode differs")
    if manifest.get("same_world_instance") is not True or manifest.get("resolution") != [1280, 720]:
        raise ValueError("Capture does not claim one fixed 1280x720 scene")
    scripts = {
        "atmosphere_script_sha256": ROOT / "game/scenes/visual_prototypes/home_atmosphere_2d.gd",
        "capture_script_sha256": ROOT / "tools/art/capture_home_atmospheres.gd",
    }
    for field, path in scripts.items():
        if manifest.get(field) != digest(path):
            raise ValueError(f"Capture does not match current {path.name}")
    frames = manifest.get("frames", [])
    if [frame.get("preset") for frame in frames] != list(PRESETS):
        raise ValueError("Missing or reordered atmosphere frames")
    images = {}
    for frame in frames:
        path = folder / frame["file"]
        if path.parent != folder or digest(path) != frame.get("sha256"):
            raise ValueError(f"Capture file/hash mismatch: {path}")
        image = Image.open(path).convert("RGB")
        if image.size != (1280, 720):
            raise ValueError(f"Unexpected capture canvas: {path}")
        images[frame["preset"]] = image
    ratios = {}
    for name, (x, y) in LANDMARKS.items():
        day = luminance(patch_rgb(images["clear_morning"], x, y))
        night = luminance(patch_rgb(images["night"], x, y))
        ratios[name] = round(night / day, 3)
        if not 0.25 < night / day < 0.75:
            raise ValueError(f"Night tint fails on {name}: ratio {night / day:.3f}")
    ground_day = patch_rgb(images["clear_morning"], *LANDMARKS["painted_ground"])
    ground_dusk = patch_rgb(images["sunset"], *LANDMARKS["painted_ground"])
    if ground_dusk[0] / ground_dusk[2] < ground_day[0] / ground_day[2] + 0.2:
        raise ValueError("Sunset warmth is not visible on painted ground")
    ground_rain = patch_rgb(images["rain"], *LANDMARKS["painted_ground"])
    if luminance(ground_rain) >= luminance(ground_day) * 0.95:
        raise ValueError("Rain mood does not visibly change painted ground")
    window = (225, 145)
    if luminance(patch_rgb(images["night"], *window)) <= luminance(patch_rgb(images["clear_morning"], *window)) * 1.05:
        raise ValueError("Night window glow is not visible")
    return {"success": True, "source_sha256": SOURCE_SHA, "night_to_morning_luminance": ratios,
            "scope": "fixed GPU screenshot sample landmarks only; not art, weather, or runtime acceptance"}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("capture_dir", type=Path)
    args = parser.parse_args()
    result = verify(args.capture_dir)
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
