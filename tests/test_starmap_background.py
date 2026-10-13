"""Validate all original PNG layers and their safety constraints."""
import pathlib
import struct
import unittest
import zlib
ROOT=pathlib.Path(__file__).resolve().parents[1]
ASSET=ROOT/"graphics/starmap/razi"
NON_BACKGROUND_ASSETS={"calidus-dyson-stages.png"}
SYSTEMS=("calidus","solaris","nyxaris","vibrant","vespera",
         "beetlejuice","umbra","deep-space")
BELTS=("vibrant","vespera","umbra")

def inspect_png(path):
    buf=path.read_bytes()
    assert buf[:8]==b"\x89PNG\r\n\x1a\n",path
    chunks={}
    index=8
    while index<len(buf):
        n=int.from_bytes(buf[index:index+4],"big")
        key=buf[index+4:index+8]
        payload=buf[index+8:index+8+n]
        check=int.from_bytes(buf[index+8+n:index+12+n],"big")
        assert zlib.crc32(key+payload)==check,path
        chunks.setdefault(key,[]).append(payload)
        index+=n+12
    assert index==len(buf)
    w,h,depth,colour=struct.unpack(">IIBB",chunks[b"IHDR"][0][:10])
    raw=zlib.decompress(b"".join(chunks[b"IDAT"]))
    channels={0:1,2:3,3:1,4:2,6:4}[colour]
    assert len(raw)==h*(1+(w*depth*channels+7)//8),path
    transparent=colour in (4,6) or b"tRNS" in chunks
    return w,h,depth,colour,transparent,len(buf)

class StarmapBackgroundTests(unittest.TestCase):
    def test_all_sprites_fit_without_giant_atlases(self):
        names=([f"sky-{i}.png" for i in range(1,5)] +
               [f"glow-{name}.png" for name in SYSTEMS] +
               [f"belt-{name}.png" for name in BELTS] +
               ["galactic-current.png","dust-lane-2.png",
                "rift-deep-space.png","chart-constellation.png"] +
               [f"filament-{name}.png" for name in SYSTEMS] +
               [f"debris-{name}.png" for name in BELTS] +
               [f"cluster-{i}.png" for i in range(1,4)])
        names += ["atlas-halo.png","atlas-belt.png"]
        names += [f"atlas-dust-{i}.png" for i in range(1,4)]
        names += [f"atlas-starfield-{i}.png" for i in range(1,5)]
        self.assertEqual(len(names),42)
        self.assertEqual(
            {f.name for f in ASSET.glob("*.png")},
            set(names) | NON_BACKGROUND_ASSETS,
        )
        for name in names:
            w,h,depth,colour,transparent,size=inspect_png(ASSET/name)
            self.assertLessEqual(max(w,h),1024)
            self.assertIn(colour,(3,4))
            self.assertIn(depth,(2,4,8))
            self.assertTrue(transparent)
            self.assertLess(size,350000)
            if name.startswith("atlas-starfield-"):
                self.assertEqual((w,h,depth,colour),(1024,1024,8,3))
            if name in ("atlas-halo.png","atlas-belt.png"):
                self.assertEqual((w,h,depth,colour),(512,512,8,3))
            if name.startswith("atlas-dust-"):
                self.assertEqual((w,h,depth,colour),(512,512,8,4))
    def test_refined_atlas_uses_full_alpha_gradient(self):
        # Earlier 25-step alpha ramps produced blocky contour bands at
        # large starmap zoom. The indexed halo and belt keep full ramps;
        # dust uses direct 8-bit alpha and is covered by the format contract.
        for name in ("atlas-halo.png","atlas-belt.png"):
            png=(ASSET/name).read_bytes()
            offset=8
            found=False
            while offset<len(png):
                length=int.from_bytes(png[offset:offset+4],"big")
                kind=png[offset+4:offset+8]
                if kind==b"tRNS":
                    self.assertEqual(length,256,name)
                    found=True
                offset+=12+length
            self.assertTrue(found,name)

    def test_art_after_orbit_layout_before_route_highlights(self):
        source=(ROOT/"data-final-fixes.lua").read_text()
        layout='require("prototypes.system.galaxy_layout").data_final_fixes()'
        art='require("prototypes.system.starmap_background").data_final_fixes()'
        routes='require("prototypes.system.route_highlights").data_final_fixes()'
        self.assertLess(source.index(layout),source.index(art))
        self.assertLess(source.index(art),source.index(routes))
    def test_settings_and_prototype_ownership(self):
        settings=(ROOT/"settings.lua").read_text()
        module=(ROOT/"prototypes/system/starmap_background.lua").read_text()
        self.assertIn('allowed_values={"off","subtle","cinematic"}',settings)
        self.assertIn('mods["Better_Starmap_Background"]',module)
        self.assertIn('table.insert(sprite.layers,1,new[i])',module)
        self.assertIn('layout.anchor_position',module)
        self.assertIn('razi-starmap-fine-details',settings)
        self.assertIn('razi-starmap-micro-details',settings)
        self.assertIn('razi-starmap-orbit-density',settings)
        self.assertIn('razi-starmap-soften-bellicos',settings)
        self.assertIn('allowed_values={"clean","balanced","full"}',settings)
        self.assertIn('razi-starmap-cartography',settings)
        self.assertIn('default_value=false',settings)
        for name in ("atlas-halo.png","atlas-belt.png"):
            self.assertIn(name,module)
        self.assertIn('"atlas-dust-"..',module)
        for legacy in ("filament-","galactic-current.png","sky-",
                       "rift-deep-space.png","dust-lane-2.png"):
            self.assertNotIn(legacy,module)
        self.assertIn('local ATMOSPHERE_SIZE=512',module)
        self.assertIn('size={1024,1024},scale=4',module)
        self.assertNotIn('data:extend',module)
        self.assertNotIn('space-connection',module)
if __name__=="__main__":
    unittest.main()
