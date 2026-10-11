"""Regression checks for the baked Razi starmap route-guide assets."""
import re
import struct
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
MANIFEST=(ROOT/"prototypes/system/route_highlight_manifest.lua").read_text()
SOURCE=(ROOT/"prototypes/system/route_reconcile.lua").read_text()
PATTERN=(r'from="([^"]+)",to="([^"]+)",kind="([^"]+)",\s*'
         r'filename="__razi-protocol__/([^"]+)",size=\{(\d+),(\d+)\},\s*'
         r'shift=\{([-\d.]+),([-\d.]+)\},\s*'
         r'start=\{([-\d.]+),([-\d.]+)\},finish=\{([-\d.]+),([-\d.]+)\}')
def entries():
    return [(a,b,kind,path,int(w),int(h),float(sx),float(sy),
             float(ax),float(ay),float(bx),float(by))
            for a,b,kind,path,w,h,sx,sy,ax,ay,bx,by
            in re.findall(PATTERN,MANIFEST)]
class RouteHighlightTests(unittest.TestCase):
    def test_complete_masks_and_positioned_layers(self):
        rows=entries()
        self.assertEqual(len(rows),14)
        self.assertEqual(len({frozenset((a,b)) for a,b,*_ in rows}),14)
        for a,b,kind,path,w,h,sx,sy,ax,ay,bx,by in rows:
            p=ROOT/path
            self.assertTrue(p.is_file(),p)
            raw=p.read_bytes()
            self.assertEqual(raw[:8],b'\x89PNG\r\n\x1a\n')
            self.assertEqual(struct.unpack(">II",raw[16:24]),(w,h))
            self.assertIn(tuple(raw[24:26]),((2,3),(1,3)))
            self.assertLessEqual(max(w,h),2048)
            self.assertAlmostEqual(sx/32,(ax+bx)/2,delta=.05)
            self.assertAlmostEqual(sy/32,(ay+by)/2,delta=.05)
    def test_routes_exist_and_native_belt_is_not_replaced(self):
        section=SOURCE.split("local route_specifications = {",1)[1]
        section=section.split("-- Paths replaced by",1)[0]
        pairs={frozenset((a,b)) for a,b in re.findall(
            r'\{"([^"]+)",\s*"([^"]+)",\s*\d+,\s*"[^"]+"\}',section)}
        native=frozenset(("asteroid-belt-inner-edge","asteroid-belt-outer-edge"))
        for a,b,*_ in entries():
            self.assertTrue(frozenset((a,b)) in pairs or frozenset((a,b))==native)
    def test_graphics_setting_and_no_route_mutation(self):
        settings=(ROOT/"settings.lua").read_text()
        module=(ROOT/"prototypes/system/route_highlights.lua").read_text()
        self.assertIn('default_value="subtle"',settings)
        self.assertIn('mods["space-route-overlay"]',module)
        self.assertIn('math.abs(p[1]-guide.start[1])<1.5',module)
        self.assertNotIn('data:extend',module)
        self.assertNotIn('connection.length=',module)
if __name__=="__main__":
    unittest.main()
