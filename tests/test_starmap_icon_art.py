"""Regression checks for actual Razi starmap PNG and editable route SVG art.

The source generator uses only Node's built-in fs/path modules and writes
unfiltered RGBA PNGs. Inspect every image and validate its deflate stream so
corrupt or visually repeated marker files cannot silently ship.
"""
import hashlib
from pathlib import Path
import struct
import unittest
import xml.etree.ElementTree as ET
import zlib

ROOT = Path(__file__).resolve().parents[1]
NAV = [
    "calidus-gate", "solaris-gate", "nyxaris-gate", "vibrant-gate",
    "vespera-gate", "beetlejuice-gate", "umbra-gate",
    "vibrant-rim-inner", "vibrant-rim-outer",
    "umbra-rim-inner", "umbra-rim-outer",
]
ROUTES = ["planetary-route", "interstellar-route", "asteroid-route", "deep-space-route"]


def rgba(path):
    content = path.read_bytes()
    assert content[:8] == b"\x89PNG\r\n\x1a\n", path
    assert struct.unpack(">II", content[16:24]) == (64, 64), path
    assert content[24:26] == b"\x08\x06", path
    cursor = 8
    blocks = []
    while cursor < len(content):
        length = struct.unpack(">I", content[cursor:cursor + 4])[0]
        kind = content[cursor + 4:cursor + 8]
        data = content[cursor + 8:cursor + 8 + length]
        checksum = struct.unpack(">I", content[cursor + 8 + length:cursor + 12 + length])[0]
        assert zlib.crc32(kind + data) == checksum, path
        if kind == b"IDAT":
            blocks.append(data)
        cursor += length + 12
    assert cursor == len(content) and blocks, path
    inflated = zlib.decompress(b"".join(blocks))
    lines = []
    for y in range(64):
        line = inflated[y * 257:(y + 1) * 257]
        assert line[0] == 0 and len(line) == 257, path
        lines.append(line[1:])
    return b"".join(lines)


class StarmapArtTests(unittest.TestCase):
    def test_every_png_is_unique_and_readable(self):
        images = {}
        for stem in NAV + ROUTES:
            path = ROOT / "graphics/icons" / ("routes" if stem in ROUTES else "navigation") / (stem + ".png")
            with self.subTest(stem=stem):
                self.assertLess(path.stat().st_size, 40000)
                pixels = rgba(path)
                alpha = pixels[3::4]
                self.assertEqual(alpha[0], 0, "Corners must be transparent")
                self.assertGreater(sum(a > 40 for a in alpha), 150)
                self.assertLess(sum(a > 40 for a in alpha), 3400)
                images[stem] = pixels
        self.assertEqual(len({hashlib.sha256(pixels).digest() for pixels in images.values()}), 15)
        # Detect recolors/tiny one-pixel differences by checking the alpha
        # and RGB channels across each complete image at native resolution.
        keys = list(images)
        for i, a in enumerate(keys):
            for b in keys[i + 1:]:
                x, y = images[a], images[b]
                changed = sum(
                    max(abs(x[k + c] - y[k + c]) for c in range(4)) > 18
                    for k in range(0, len(x), 4)
                )
                self.assertGreater(changed, 175, f"{a} is too similar to {b}")

        # Distinct silhouettes matter more than different PNG hashes/colors.
        # The rim entry/exit markers must not reuse a slipstream outline.
        for i, a in enumerate(NAV):
            for b in NAV[i + 1:]:
                aa = images[a][3::4]
                bb = images[b][3::4]
                changed_shape = sum(abs(x - y) > 70 for x, y in zip(aa, bb))
                self.assertGreater(changed_shape, 200, f"{a} and {b} still share an outline")

    def test_route_svg_sources_correspond_to_categories(self):
        for stem in ROUTES:
            with self.subTest(stem=stem):
                path = ROOT / "graphics/icons/routes" / (stem + ".svg")
                root = ET.parse(path).getroot()
                self.assertEqual(root.attrib.get("viewBox"), "0 0 64 64")
                self.assertGreater(len(root), 6, "Handful of crisp vectors is preferred to an over-detailed SVG")
        source = (ROOT / "scripts/generate_navigation_markers.js").read_text()
        self.assertIn("paint.svg()", source)
        self.assertIn('spec.kind==="route"', source)
        self.assertIn("function orbitPoint(", source)
        self.assertNotIn("function oct(", source)

    def test_existing_prototype_contracts_are_preserved(self):
        location = (ROOT / "prototypes/system/location_icons.lua").read_text()
        routes = (ROOT / "prototypes/system/route_icons.lua").read_text()
        for stem in NAV:
            self.assertIn("navigation/" + stem + ".png", location)
        for stem in ROUTES:
            self.assertIn("routes/" + stem + ".png", routes)
        self.assertIn("if not connection or has_icon(connection)", routes)


if __name__ == "__main__":
    unittest.main()
