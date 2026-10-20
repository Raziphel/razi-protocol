#!/usr/bin/env python3
"""Static audit for graphics owned by Razi Protocol.

The audit intentionally resolves only ``__razi-protocol__`` paths. References
owned by Factorio and optional mods are data-stage concerns and must not be
reported as missing merely because those mods are absent from the checkout.
"""

from __future__ import annotations

import argparse
import re
import struct
from pathlib import Path
from typing import NamedTuple


MOD_PREFIX = "__razi-protocol__/"
GRAPHICS_REFERENCE = re.compile(
    r"(?P<quote>['\"])(?P<path>__razi-protocol__/graphics/[^'\"]+)(?P=quote)"
)
SOURCE_SUFFIXES = {".lua", ".json", ".cfg"}

# This is a historical layer-removal key, not an image opened by Factorio.
# The old texture is intentionally absent, but the cleanup pass must
# recognize and discard a stale reference injected by earlier mods.
MATCH_ONLY_GRAPHICS = {
    "graphics/route-highlights/directional-strokes.png",
}


REQUIRED_DIMENSIONS = {
    "graphics/ui/razi-corporate-emblem.png": (128, 128),
    "graphics/icons/CalidusStar.png": (1024, 1024),
    "graphics/icons/SolarisStar.png": (1024, 1024),
    "graphics/icons/NyxarisStar.png": (1024, 1024),
    "graphics/icons/VibrantStar.png": (1024, 1024),
    "graphics/icons/BeetleJuiceStar.png": (1024, 1024),
    "graphics/icons/VesperaStar.png": (1024, 1024),
    "graphics/icons/UmbraStar.png": (1024, 1024),
    "graphics/icons/tech-cards/calidus-tech-card.png": (256, 256),
    "graphics/icons/tech-cards/solaris-tech-card.png": (256, 256),
    "graphics/icons/tech-cards/nyxaris-tech-card.png": (256, 256),
    "graphics/icons/tech-cards/vibrant-tech-card.png": (256, 256),
    "graphics/icons/tech-cards/beetlejuice-tech-card.png": (256, 256),
    "graphics/icons/tech-cards/deep-space-tech-card.png": (256, 256),
    "graphics/icons/tech-cards/vespera-tech-card.png": (256, 256),
    "graphics/icons/tech-cards/umbra-tech-card.png": (256, 256),
    "graphics/icons/routes/planetary-route.png": (64, 64),
    "graphics/icons/routes/interstellar-route.png": (64, 64),
    "graphics/icons/routes/asteroid-route.png": (64, 64),
    "graphics/icons/routes/deep-space-route.png": (64, 64),
}

 
# Dynamic paths are assembled from Lua at startup, so filename-only grep is
# insufficient to prove these runtime textures are unused.
ACTIVE_STARMAP = {
    *(f"atlas-starfield-{i}.png" for i in range(1, 5)),
    *(f"atlas-dust-{i}.png" for i in range(1, 4)),
    *(f"glow-{star}.png" for star in
      ("solaris", "nyxaris", "vibrant", "vespera", "beetlejuice", "umbra")),
    "atlas-halo.png", "debris-umbra.png",
    "belt-vibrant-core.png", "belt-vibrant-scatter.png",
    "belt-vibrant-dust.png", "calidus-dyson-stages.png",
}
RUNTIME_ICON_GROUPS = {
    "navigation": (
        "beetlejuice-gate", "calidus-gate", "nyxaris-gate",
        "solaris-gate", "umbra-gate", "umbra-rim-inner",
        "umbra-rim-outer", "vespera-gate", "vibrant-gate",
        "vibrant-rim-inner", "vibrant-rim-outer",
    ),
    "convergence": (
        "razi-convergence-deep-space", "razi-convergence-ignition",
        "razi-convergence-industry", "razi-convergence-resonance",
        "razi-convergence-stellar",
    ),
    "routes": (
        "asteroid-route", "deep-space-route", "interstellar-route",
        "planetary-route",
    ),
}


class Reference(NamedTuple):
    source: Path
    line: int
    mod_path: str


def png_info(path: Path) -> tuple[int, int, bool]:
    """Return width, height, and whether a PNG's color type carries alpha."""
    with path.open("rb") as handle:
        header = handle.read(26)
    if len(header) < 26 or header[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("invalid PNG signature or truncated header")
    if header[12:16] != b"IHDR":
        raise ValueError("missing PNG IHDR chunk")
    width, height = struct.unpack(">II", header[16:24])
    color_type = header[25]
    if not width or not height:
        raise ValueError("zero-sized PNG")
    if color_type in (4, 6):
        return width, height, True
    if color_type == 3:
        # Palette PNGs can have full per-colour opacity via a tRNS chunk.
        # Read the actual chunk headers, not incidental bytes in IDAT.
        data = path.read_bytes()
        offset = 8
        while offset + 12 <= len(data):
            size = int.from_bytes(data[offset:offset+4], "big")
            kind = data[offset+4:offset+8]
            if kind == b"tRNS":
                return width, height, True
            offset += 12 + size
    return width, height, False


def discover_references(root: Path) -> list[Reference]:
    references = []
    excluded = {".git", ".venv", "__pycache__"}
    for source in sorted(root.rglob("*")):
        if (not source.is_file() or source.suffix not in SOURCE_SUFFIXES
                or any(part in excluded for part in source.parts)):
            continue
        text = source.read_text(encoding="utf-8")
        for match in GRAPHICS_REFERENCE.finditer(text):
            # Factorio builds some filenames as PREFIX..name..".png".
            # A literal prefix is not a file, so verify only complete
            # image names here; dynamic families are audited separately.
            path = match.group("path")
            if not path.lower().endswith((".png", ".jpg", ".jpeg", ".webp", ".svg")):
                continue
            references.append(Reference(
                source.relative_to(root),
                text.count("\n", 0, match.start()) + 1,
                path,
            ))
    return references


def _source_contracts(root: Path) -> list[str]:
    errors = []
    final_fixes = (root / "data-final-fixes.lua").read_text(encoding="utf-8")
    final_call = 'require("prototypes.system.route_icons").data_final_fixes()'
    if final_call not in final_fixes:
        errors.append("data-final-fixes.lua: missing final route icon repair pass")
    elif final_fixes.index(final_call) > final_fixes.index(
            'require("prototypes.system.route_highlights").data_final_fixes()'):
        errors.append("data-final-fixes.lua: route icons must precede route rendering")

    for relative in (
        "prototypes/system/route_reconcile.lua",
        "prototypes/system/optional_planets.lua",
        "prototypes/system/community_expansions.lua",
    ):
        text = (root / relative).read_text(encoding="utf-8")
        if 'require("prototypes.system.route_icons")' not in text:
            errors.append(f"{relative}: dynamic routes do not import route_icons")
        if "route_icons.assign" not in text:
            errors.append(f"{relative}: dynamic routes are not assigned an icon")

    system_text = (root / "prototypes/system/seven_systems.lua").read_text(
        encoding="utf-8")
    tech_text = (root / "prototypes/technology/seven_systems.lua").read_text(
        encoding="utf-8")
    cards_text = (root / "prototypes/compat/lab_cards.lua").read_text(
        encoding="utf-8")
    for label, text in (("system", system_text), ("technology", tech_text)):
        for star in ("VesperaStar.png", "UmbraStar.png"):
            if star not in text:
                errors.append(f"seven-system {label}: missing dedicated {star}")
        for placeholder in ("VibrantStar.png", "NyxarisStar.png"):
            if placeholder in text:
                errors.append(
                    f"seven-system {label}: suspicious reused {placeholder}")
    for card in ("vespera-tech-card.png", "umbra-tech-card.png"):
        if card not in cards_text:
            errors.append(f"lab cards: missing dedicated {card}")
    if "tint =" in cards_text:
        errors.append("lab cards: dedicated card artwork must not use tint workarounds")

    route_source = (root / "prototypes/system/route_icons.lua").read_text(
        encoding="utf-8")
    if "icon_size = 64" not in route_source:
        errors.append("route_icons.lua: route icon_size must match the 64px files")
    return errors


def audit_repository(root: Path) -> list[str]:
    root = root.resolve()
    errors = _source_contracts(root)
    references = discover_references(root)
    seen = set()
    for reference in references:
        relative = reference.mod_path[len(MOD_PREFIX):]
        if relative in MATCH_ONLY_GRAPHICS:
            continue
        asset = root / relative
        location = f"{reference.source}:{reference.line}"
        if not asset.is_file():
            errors.append(f"{location}: missing {reference.mod_path}")
            continue
        if asset.suffix.lower() != ".png" or relative in seen:
            continue
        seen.add(relative)
        try:
            width, height, has_alpha = png_info(asset)
        except (OSError, ValueError) as exc:
            errors.append(f"{location}: unreadable PNG {relative}: {exc}")
            continue
        expected = REQUIRED_DIMENSIONS.get(relative)
        if expected and (width, height) != expected:
            errors.append(
                f"{location}: {relative} is {width}x{height}; expected "
                f"{expected[0]}x{expected[1]}")
        if not has_alpha:
            errors.append(f"{location}: {relative} has no alpha channel")

    for relative, expected in REQUIRED_DIMENSIONS.items():
        if relative not in seen:
            errors.append(f"unreferenced required asset: {relative}")

    # The mod portal and README consume these directly, outside Lua prototypes.
    for relative, expected in {
        "thumbnail.png": (256, 256),
        "graphics/branding/razi-protocol-lockup.png": (900, 300),
    }.items():
        try:
            width, height, alpha = png_info(root / relative)
            if (width, height) != expected or not alpha:
                errors.append(f"invalid branding asset: {relative}")
        except (OSError, ValueError) as exc:
            errors.append(f"invalid branding asset: {relative}: {exc}")

    # Catch accidental return of retired graphical clutter. The PNG set is
    # explicit because starmap and icon names are constructed dynamically.
    starmap = root / "graphics/starmap/razi"
    actual = {path.name for path in starmap.glob("*.png")}
    for missing in sorted(ACTIVE_STARMAP - actual):
        errors.append(f"missing dynamic starmap asset: {missing}")
    for stale in sorted(actual - ACTIVE_STARMAP):
        errors.append(f"obsolete or unaudited starmap asset: {stale}")
    for group, names in RUNTIME_ICON_GROUPS.items():
        directory = root / "graphics/icons" / group
        for name in names:
            file = directory / f"{name}.png"
            if not file.is_file():
                errors.append(f"missing generated icon: {file.relative_to(root)}")
                continue
            try:
                size, height, has_alpha = png_info(file)
                if (size, height) != (64, 64) or not has_alpha:
                    errors.append(f"invalid 64px alpha icon: {file.relative_to(root)}")
            except (OSError, ValueError) as exc:
                errors.append(f"invalid generated icon {file.relative_to(root)}: {exc}")
    for old in sorted((root / "graphics/route-highlights").glob("guide-*.png")):
        errors.append(f"obsolete route guide: {old.relative_to(root)}")
    for file in (root / "graphics/convergence").glob("*.png"):
        errors.append(f"obsolete convergence graphic: {file.relative_to(root)}")
    if (root / "prototypes/system/route_highlight_manifest.lua").exists():
        errors.append("obsolete guide-only route_highlight_manifest.lua still shipped")

    return sorted(set(errors))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", nargs="?", type=Path,
                        default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    errors = audit_repository(args.root)
    if errors:
        print("Asset audit failed:")
        for error in errors:
            print(f"  - {error}")
        return 1
    count = len(discover_references(args.root.resolve()))
    print(f"Asset audit passed: {count} Razi-owned graphics references resolved")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
