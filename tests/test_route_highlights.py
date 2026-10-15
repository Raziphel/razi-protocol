"""Razi data-stage route colors: native risk categories and continuous strokes."""
import json
from pathlib import Path
import struct
import unittest
import zlib

ROOT=Path(__file__).resolve().parents[1]

def read(path):
    return (ROOT/path).read_text(encoding="utf-8")


class BuiltInOverlayTests(unittest.TestCase):
    def test_external_overlay_is_not_a_dependency(self):
        info=json.loads(read("info.json"))
        self.assertEqual(info["factorio_version"], "2.1")
        self.assertIn("! space-route-overlay",info["dependencies"])
        self.assertNotIn("~ space-route-overlay >= 0.2.7",info["dependencies"])

    def test_native_geometry_and_data_stage_order(self):
        source=read("data-final-fixes.lua")
        layout='require("prototypes.system.galaxy_layout").confirm_critical_positions()'
        overlay='require("prototypes.system.route_highlights").data_final_fixes()'
        tooltips='require("prototypes.system.route_intel").data_final_fixes()'
        self.assertLess(source.index(tooltips),source.index(overlay))
        self.assertLess(source.index(layout),source.index(overlay))
        overlay_src=read("prototypes/system/route_highlights.lua")
        for fragment in ('if route.shape=="line" then',
                         "if not cx then", "if abs(sweep)>.95 then return nil end",
                         'table.sort(candidates,function(a,b)',
                         "if layers+#entry.sprites<=LAYER_BUDGET then",
                         "local rendered_span=span+.30",
                         'M.is_navigation_highlight(route,scope)',
                         'reconcile.allowed_pairs[',
                         'unsafe_endpoint={carna=true,gleba=true,velora=true}'):
            self.assertIn(fragment,overlay_src)
        self.assertNotIn("data:extend",overlay_src)
        self.assertNotIn("script.on_event",overlay_src)
        self.assertNotIn("game.tick",overlay_src)
        self.assertNotIn('require("space-route-overlay")',overlay_src)

    def test_hazard_palette_has_one_source_of_truth(self):
        hazard=read("prototypes/system/route_hazards.lua")
        renderer=read("prototypes/system/route_highlights.lua")
        self.assertIn("local danger_colors=hazards.colors",renderer)
        self.assertIn("local rank=M.threat_tier(route)",renderer)
        self.assertIn("if mode==\"chapter\" and rank<4",renderer)
        self.assertIn("if M.is_belt_crossing(route) then tier=math.max(4,tier) end",hazard)
        for tone in ('r=.42,g=.64,b=.77','r=.38,g=.70,b=.68',
                     'r=.48,g=.76,b=.54','r=.94,g=.73,b=.38',
                     'r=.92,g=.43,b=.36'):
            self.assertIn(tone,hazard)
        options=read("settings.lua")
        self.assertIn('name="razi-route-overlay-mode"',options)
        self.assertIn('default_value="danger"',options)
        self.assertIn('name="razi-route-overlay-scope"',options)
        self.assertIn('default_value="major"',options)

    def test_anti_aliased_directional_atlas(self):
        asset=ROOT/"graphics/route-highlights/continuous-strokes.png"
        image=asset.read_bytes()
        self.assertLess(asset.stat().st_size,600000)
        self.assertEqual(image[:8],b"\x89PNG\r\n\x1a\n")
        self.assertEqual(struct.unpack(">II",image[16:24]),(1024,1024))
        self.assertEqual(image[24:26],bytes([4,3]))
        compressed=[]
        transparent=False
        palette=False
        off=8
        while off<len(image):
            size=struct.unpack(">I",image[off:off+4])[0]
            kind=image[off+4:off+8]
            chunk=image[off+8:off+8+size]
            checksum=struct.unpack(">I",image[off+8+size:off+12+size])[0]
            self.assertEqual(zlib.crc32(kind+chunk),checksum)
            if kind==b"PLTE":
                palette=len(chunk)==48
            elif kind==b"tRNS":
                transparent=len(chunk)==16 and chunk[0]==0 and chunk[-1]==255
            elif kind==b"IDAT":
                compressed.append(chunk)
            off+=size+12
        self.assertTrue(palette and transparent)
        self.assertEqual(off,len(image))
        raw=zlib.decompress(b"".join(compressed))
        self.assertEqual(len(raw),1024*513)
        def palette_index(x,y):
            row=y*513
            self.assertEqual(raw[row],0)
            packed=raw[row+1+x//2]
            return packed>>4 if x%2==0 else packed&15
        # Horizontal bearing #0 is one connected undashed beam.
        self.assertTrue(all(palette_index(x,64)>0 for x in range(17,110)))
        self.assertEqual(palette_index(0,64),0)
        # A quarter-turn creates a continuous vertical beam (#32).
        self.assertTrue(all(palette_index(64,y)>0 for y in range(4*128+17,4*128+110)))
        src=read("prototypes/system/route_highlights.lua")
        self.assertIn('graphics/route-highlights/continuous-strokes.png',src)
        self.assertIn("local CELL=128",src)
        self.assertIn("local PIXELS=110",src)
        self.assertIn("local MAX_SEGMENTS=64",src)
        generator=read("scripts/generate_route_stroke_atlas.js")
        self.assertIn("const CELL=128,COLUMNS=8,BEARINGS=64,LENGTH=110;",generator)
        self.assertIn("chunk(\"tRNS\"",generator)


if __name__=="__main__":
    unittest.main()
