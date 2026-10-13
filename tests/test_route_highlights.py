"""Regression checks for the baked Razi starmap route-guide assets."""
import re
import struct
import unittest
import zlib
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
    def test_shared_directional_strokes_is_valid_indexed_png(self):
        path=ROOT/"graphics/route-highlights/directional-strokes.png"
        raw=path.read_bytes()
        self.assertEqual(raw[:8],b"\x89PNG\r\n\x1a\n")
        sections={}
        offset=8
        while offset<len(raw):
            count=struct.unpack(">I",raw[offset:offset+4])[0]
            marker=raw[offset+4:offset+8]
            payload=raw[offset+8:offset+8+count]
            actual=struct.unpack(">I",raw[offset+8+count:offset+12+count])[0]
            self.assertEqual(zlib.crc32(marker+payload)&0xffffffff,actual)
            sections.setdefault(marker,[]).append(payload)
            offset+=count+12
        self.assertEqual(offset,len(raw))
        self.assertEqual(struct.unpack(">IIBB",sections[b"IHDR"][0][:10]),
                         (2048,2048,2,3))
        self.assertEqual(sections[b"tRNS"][0],bytes((0,35,120,205)))
        pixels=zlib.decompress(b"".join(sections[b"IDAT"]))
        self.assertEqual(len(pixels),2048*(1+2048//4))
        self.assertEqual(pixels[0],0)

    def test_complete_masks_and_positioned_layers(self):
        rows=entries()
        self.assertEqual(len(rows),14)
        self.assertEqual(len({frozenset((a,b)) for a,b,*_ in rows}),14)
        for a,b,kind,path,w,h,sx,sy,ax,ay,bx,by in rows:
            p=ROOT/path
            self.assertTrue(p.is_file(),p)
            raw=p.read_bytes()
            self.assertEqual(raw[:8],b'\x89PNG\r\n\x1a\n')
            offset=8
            chunks=[]
            while offset < len(raw):
                self.assertGreaterEqual(len(raw)-offset,12,p)
                length=struct.unpack(">I",raw[offset:offset+4])[0]
                chunk_type=raw[offset+4:offset+8]
                end=offset+8+length
                self.assertLessEqual(end+4,len(raw),p)
                expected_crc=struct.unpack(">I",raw[end:end+4])[0]
                actual_crc=zlib.crc32(raw[offset+4:end]) & 0xffffffff
                self.assertEqual(actual_crc,expected_crc,(p,chunk_type))
                chunks.append((chunk_type,length))
                offset=end+4
                if chunk_type==b'IEND':
                    break
            self.assertEqual(chunks[0],(b'IHDR',13),p)
            self.assertEqual(chunks[-1],(b'IEND',0),p)
            self.assertEqual(offset,len(raw),p)
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
        self.assertIn('if mode=="off"',module)
        self.assertIn('M.color_for_guide(guide,route)',module)
        self.assertIn('severity>=5',module)
        self.assertIn('local stage_colors=',module)
        self.assertIn('function M.stage_for_location(name)',module)
        self.assertIn('for _,name in ipairs(entries)',module)
        self.assertIn('M.strokes_for_connection(route,mode)',module)
        self.assertIn('SHEET="__razi-protocol__/graphics/route-highlights/directional-strokes.png"',module)
        self.assertIn('local LIMIT=1800',module)
        self.assertIn('function M.field_marker() return nil end',module)
        self.assertIn('shift=guide.shift,scale=4',module)
        self.assertNotIn('layer(4.084',module)
        self.assertNotIn('rift-deep-space.png',module)
        self.assertIn('local function route_point(route,a,b,t)',module)
        self.assertIn('local o=route.origin or {}',module)
        self.assertIn('route.shape=="line"',module)
        self.assertNotIn('data:extend',module)
        self.assertNotIn('connection.length=',module)
        self.assertIsNone(re.search(r'route\.shape\s*=\s*[^=]',module))
        self.assertNotIn('data.raw["space-connection"][name]=',module)
if __name__=="__main__":
    unittest.main()
