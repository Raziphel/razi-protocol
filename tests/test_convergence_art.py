"""Static artwork checks for the five physical Convergence mandates.

These checks verify the shipped PNG data, useful silhouettes and matching
editable SVG sources. They do not need an installed Factorio executable.
"""
import hashlib
import struct
import unittest
import xml.etree.ElementTree as ET
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "graphics/icons/convergence"
NAMES = ("stellar", "industry", "deep-space", "resonance", "ignition")


def read_png(path):
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise AssertionError(f"{path}: not a PNG")
    assert struct.unpack(">II", data[16:24]) == (64, 64)
    assert data[24:26] == b"\x08\x06", "must have 8-bit RGBA channels"
    offset, compressed, ended = 8, bytearray(), False
    while offset < len(data):
        size = struct.unpack(">I", data[offset:offset+4])[0]
        chunk = data[offset+4:offset+8]
        raw = data[offset+8:offset+8+size]
        checksum = struct.unpack(">I", data[offset+8+size:offset+12+size])[0]
        assert zlib.crc32(chunk + raw) == checksum, path
        if chunk == b"IDAT":
            compressed.extend(raw)
        if chunk == b"IEND":
            ended = True
        offset += 12 + size
    assert ended and offset == len(data), path
    lines = zlib.decompress(compressed)
    assert len(lines) == 64 * 257
    assert all(lines[i * 257] == 0 for i in range(64)), "expect unfiltered scanlines"
    return b"".join(lines[i * 257 + 1:i * 257 + 257] for i in range(64))


class ConvergenceArtTests(unittest.TestCase):
    def test_pngs_have_transparent_64px_silhouettes(self):
        images = {}
        for name in NAMES:
            with self.subTest(name=name):
                file = ART / ("razi-convergence-" + name + ".png")
                self.assertLess(file.stat().st_size, 40000)
                pixels = read_png(file)
                self.assertEqual(len(pixels), 64 * 64 * 4)
                alpha = pixels[3::4]
                self.assertEqual(alpha[0], 0)
                self.assertEqual(alpha[-1], 0)
                self.assertGreater(sum(a > 32 for a in alpha), 600)
                self.assertLess(sum(a > 32 for a in alpha), 3000)
                images[name] = pixels
        self.assertEqual(len({hashlib.sha256(x).digest() for x in images.values()}), 5)

        # Avoid reverting to recolored copies of the same generic orb.
        for i, left in enumerate(NAMES):
            for right in NAMES[i+1:]:
                a, b = images[left][3::4], images[right][3::4]
                changed = sum(abs(x - y) > 70 for x, y in zip(a, b))
                self.assertGreater(changed, 120, f"{left} and {right} share a silhouette")

    def test_svg_sources_and_reproducible_generator(self):
        generator = (ROOT / "scripts/generate_convergence_icons.js").read_text()
        self.assertIn("function draw(stage)", generator)
        self.assertIn("painter.raster()", generator)
        self.assertIn("painter.svg()", generator)
        for name in NAMES:
            with self.subTest(name=name):
                svg = ART / ("razi-convergence-" + name + ".svg")
                root = ET.parse(svg).getroot()
                self.assertEqual(root.attrib["viewBox"], "0 0 64 64")
                self.assertGreater(len(root), 8)
                self.assertIn("'" + name + "'", generator)

    def test_gameplay_art_paths_unmodified(self):
        source = (ROOT / "prototypes/technology/convergence.lua").read_text()
        self.assertIn('artwork[id]..".png",icon_size=64', source)
        self.assertIn('M.shipments={', source)
        self.assertIn('M.assemblies={', source)
        self.assertIn('M.max_recipe_inputs=6', source)


if __name__ == "__main__":
    unittest.main()
