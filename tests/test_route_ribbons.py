"""Validate that Razi visibly overlays complete native route paths.

A shared 1024x512 sprite sheet contains 128 antialiased white bearings.
All sprites are colored using the same ten-level quality ladder as the
native tooltip. The native Factorio connection prototype is not changed.
"""
import json
from pathlib import Path
import struct
import unittest
import zlib

ROOT=Path(__file__).resolve().parents[1]
PNG=ROOT/"graphics/route-highlights/route-ribbons.png"

def check_atlas():
    content=PNG.read_bytes()
    assert content.startswith(b"\x89PNG\r\n\x1a\n")
    assert struct.unpack(">II",content[16:24])==(1024,512)
    assert content[24:26]==b"\x08\x06" # 8-bit alpha RGBA
    p=8
    compressed=bytearray()
    while p<len(content):
        size=struct.unpack(">I",content[p:p+4])[0]
        chunk=content[p+4:p+8]
        raw=content[p+8:p+8+size]
        assert zlib.crc32(chunk+raw)==struct.unpack(
            ">I",content[p+8+size:p+12+size])[0]
        if chunk==b"IDAT": compressed.extend(raw)
        p+=12+size
    assert p==len(content)
    pixels=zlib.decompress(compressed)
    stride=1024*4+1
    assert len(pixels)==stride*512
    centers=[]
    for direction in range(128):
        cx=direction%16*64+32
        cy=direction//16*64+32
        offset=cy*stride+1+cx*4+3
        centers.append(pixels[offset])
    assert all(value>=120 for value in centers),centers
    # The transparent page between diagonals must not become a giant
    # colored rectangle in the game atlas.
    assert pixels[1+3]==0
    return True

class RouteRibbonTests(unittest.TestCase):
    def test_128_bearing_rgba_source_and_real_png(self):
        self.assertTrue(check_atlas())
        source=(ROOT/"scripts/generate_route_ribbons.js").read_text()
        self.assertIn("const bearings=128,cell=64",source)
        self.assertIn("ss=3",source)
        self.assertIn("renderAtlas()",source)

    def test_visible_core_with_fine_soft_edges(self):
        """At zoomed-out starmap scale the previous faint hairline vanished."""
        raw=PNG.read_bytes()
        chunks=[]
        pos=8
        while pos<len(raw):
            size=struct.unpack(">I",raw[pos:pos+4])[0]
            kind=raw[pos+4:pos+8]
            if kind==b"IDAT":
                chunks.append(raw[pos+8:pos+8+size])
            pos+=size+12
        rgba=zlib.decompress(b"".join(chunks))
        stride=1024*4+1
        def alpha(bearing,x,y):
            xx=bearing%16*64+x
            yy=bearing//16*64+y
            return rgba[yy*stride+1+xx*4+3]
        for angle in (0,16,32,48,64,80,96,112,127):
            with self.subTest(angle=angle):
                self.assertGreaterEqual(alpha(angle,32,32),235)
        self.assertGreaterEqual(alpha(0,32,30),180)
        self.assertGreaterEqual(alpha(0,32,29),65)
        self.assertEqual(alpha(0,32,22),0)
        # Thickening affects just the centered color ribbon; not the
        # starmap sprite's empty transparent areas or neighboring bearings.
        self.assertEqual(alpha(0,2,2),0)

    def test_vivid_palette_matches_route_tooltips(self):
        import re
        ladder=(ROOT/"scripts/razi_asteroid_difficulty.lua").read_text()
        block=ladder.split("M.route_colors={",1)[1].split("M.route_color_hex={",1)[0]
        triples=[
            tuple(float(channel) for channel in match)
            for match in re.findall(
                r"\\{r=(\\d+\\.\\d+),g=(\\d+\\.\\d+),b=(\\d+\\.\\d+)\\}",
                block)
        ]
        hexblock=ladder.split("M.route_color_hex={",1)[1].split(
            "function M.color_level",1)[0]
        hexes=re.findall(r'"(#[A-F0-9]{6})"',hexblock)
        self.assertEqual(len(triples),10)
        self.assertEqual(len(set(hexes)),10)
        self.assertEqual(
            ["#" + "".join(f"{round(v*255):02X}" for v in triplet)
             for triplet in triples],
            hexes)
        self.assertTrue(all(max(t)-min(t)>=.45 for t in triples))
        renderer=(ROOT/"prototypes/system/route_ribbons.lua").read_text()
        self.assertIn("math.min(1,.96+.004*grade)",renderer)
        self.assertIn("shift={(a.x+b.x)*16,(a.y+b.y)*16}",renderer)

    def test_native_geometry_and_budget(self):
        module=(ROOT/"prototypes/system/route_ribbons.lua").read_text()
        owner=(ROOT/"prototypes/system/route_highlights.lua").read_text()
        for frag in ("local ANGLES,CELL,COLS=128,64,16",
            "local ROUTE_LIMIT,LAYER_BUDGET=128,2400",
            "local TARGET_SPAN=3.6",
            "shift={(a.x+b.x)*16,(a.y+b.y)*16}",
            "scale=d*32/UNIT",
            "owner.route_path(route,a,b)",
            "ladder.route_level(",
            "if sprite.filename==SHEET then return 0 end"):
            self.assertIn(frag,module)
        self.assertIn("M.route_path=route_path",owner)
        self.assertIn("M.is_major=is_major",owner)
        self.assertIn("route_ribbons",owner)
        self.assertIn('if route.shape=="line" then',owner)
        self.assertIn("if not cx then cx,cy=0,0 end",owner)
        self.assertNotIn("script.on_event",module)
        self.assertNotIn("data:extend",module)

    def test_grade_scale_and_default_visibility(self):
        ladder=(ROOT/"scripts/razi_asteroid_difficulty.lua").read_text()
        settings=(ROOT/"settings.lua").read_text()
        self.assertIn("M.route_colors={",ladder)
        self.assertIn("M.route_color_hex={",ladder)
        self.assertIn('default_value="all",allowed_values={"major","all"}',settings)
        info=json.loads((ROOT/"info.json").read_text())
        self.assertIn("! space-route-overlay",info["dependencies"])

if __name__=="__main__":
    unittest.main()
