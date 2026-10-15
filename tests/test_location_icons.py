"""Static audit for actual shipped 64px starmap marker textures."""
from pathlib import Path
import struct
import unittest
ROOT=Path(__file__).resolve().parents[1]
NAMES=["calidus-gate","solaris-gate","nyxaris-gate","vibrant-gate","vespera-gate","beetlejuice-gate","umbra-gate","vibrant-rim-inner","vibrant-rim-outer","umbra-rim-inner","umbra-rim-outer"]
class LocationIcons(unittest.TestCase):
    def test_icon_pngs(self):
        for stem in NAMES:
            with self.subTest(stem=stem):
                h=(ROOT/"graphics/icons/navigation"/(stem+".png")).read_bytes()[:26]
                self.assertEqual(h[:8],b"\x89PNG\r\n\x1a\n")
                self.assertEqual(struct.unpack(">II",h[16:24]),(64,64))
                self.assertEqual(h[25],6)
    def test_final_pass(self):
        source=(ROOT/"data-final-fixes.lua").read_text()
        a='require("prototypes.system.starmap_trail_cleanup").data_final_fixes()'
        b='require("prototypes.system.location_icons").data_final_fixes()'
        self.assertGreater(source.index(b),source.index(a))
if __name__=="__main__": unittest.main()
