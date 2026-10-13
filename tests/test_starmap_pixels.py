"""Keep Razi's starfield textures pin-sized, valid, and cheap to load."""
from pathlib import Path
import struct
import unittest
import zlib

ROOT=Path(__file__).resolve().parents[1]
TEXTURES=ROOT/"graphics/starmap/razi"

def parse_png(path):
    data=path.read_bytes()
    if data[:8]!=b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"{path.name}: invalid PNG header")
    pos=8
    chunks={}
    while pos<len(data):
        size=struct.unpack_from(">I",data,pos)[0]
        kind=data[pos+4:pos+8]
        payload=data[pos+8:pos+8+size]
        crc=struct.unpack_from(">I",data,pos+8+size)[0]
        if zlib.crc32(kind+payload)!=crc:
            raise ValueError(f"{path.name}: corrupt {kind!r} chunk")
        chunks.setdefault(kind,[]).append(payload)
        pos+=12+size
        if kind==b"IEND":
            break
    width,height,depth,color,_,_,_=struct.unpack(
        ">IIBBBBB",chunks[b"IHDR"][0])
    raw=zlib.decompress(b"".join(chunks[b"IDAT"]))
    if len(raw)!=height*(width+1):
        raise ValueError(f"{path.name}: invalid starfield scanline count")
    if any(raw[row*(width+1)] for row in range(height)):
        raise ValueError(f"{path.name}: only unfiltered indexed rows expected")
    indices=b"".join(raw[row*(width+1)+1:(row+1)*(width+1)]
                     for row in range(height))
    return (width,height,depth,color),indices,chunks


class TinyStarfieldTests(unittest.TestCase):
    def test_four_distinct_true_pinpoint_tiles(self):
        images=[]
        for number in range(1,5):
            path=TEXTURES/f"atlas-starfield-{number}.png"
            self.assertTrue(path.exists(),str(path))
            self.assertLess(path.stat().st_size,20000,
                            "Stars must not become a large startup texture")
            header,pixels,chunks=parse_png(path)
            self.assertEqual(header,(1024,1024,8,3))
            self.assertIn(b"PLTE",chunks)
            self.assertIn(b"tRNS",chunks)
            nonzero=sum(bool(value) for value in pixels)
            self.assertGreater(nonzero,275,"Sky is missing pinpoint stars")
            self.assertLess(nonzero,750,
                            "Sky density has returned to large bright clouds")
            self.assertIn(8,pixels,
                          "Each sheet needs occasional tiny sparkling stars")
            images.append(pixels)
        self.assertEqual(len(set(images)),4,
                         "Tiles should not repeat identical stellar patterns")


if __name__=="__main__":
    unittest.main()
