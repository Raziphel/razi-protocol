"""Regression checks for Paracelsin's readable Vibrant outer-rim placement.

The final map is owned by galaxy_layout.lua, not the earlier vibrant.lua
prototype override. These checks intentionally guard BOTH locations.
"""
import math
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def polar(radius, orientation):
    angle = math.tau * orientation
    return radius * math.sin(angle), -radius * math.cos(angle)


def pair_distance(a, b):
    return math.hypot(a[0] - b[0], a[1] - b[1])


class ParacelsinStarmapTests(unittest.TestCase):
    def test_final_and_early_orbits_agree(self):
        layout = (ROOT / "prototypes/system/galaxy_layout.lua").read_text()
        preliminary = (ROOT / "prototypes/system/vibrant.lua").read_text()
        final = re.search(
            r'\{"planet","paracelsin","vibrant",([\d.]+),([\d.]+)\}',
            layout,
        )
        early = re.search(
            r'name\s*=\s*"paracelsin",.*?distance\s*=\s*([\d.]+),'
            r'\s*orientation\s*=\s*([\d.]+)',
            preliminary,
            re.DOTALL,
        )
        self.assertIsNotNone(final)
        self.assertIsNotNone(early)
        radius, bearing = map(float, final.groups())
        self.assertEqual((radius, bearing), tuple(map(float, early.groups())))

        # Outer-rim markers are the ACTUAL placement values in the final
        # asteroid-belt integration, not historical coordinates in old tests.
        belt = (ROOT / "prototypes/system/asteroid_belt_integration.lua").read_text()
        rim = re.search(
            r'\{"asteroid-belt-outer-edge",([\d.]+),([\d.]+)\}',
            belt,
        )
        self.assertIsNotNone(rim)
        rim_radius, rim_bearing = map(float, rim.groups())
        paracelsin = polar(radius, bearing)
        outer = polar(rim_radius, rim_bearing)

        # The old 0.70 bearing had a one-unit vertical gap and its label
        # overlapped the Outer Rim. Keep the caption on a different baseline.
        self.assertGreater(paracelsin[1] - outer[1], 12)
        self.assertGreater(radius - rim_radius, 10)
        self.assertGreater(pair_distance(paracelsin, outer), 14)

        shchierbin = re.search(
            r'\{name="shchierbin",star="vibrant",radius=([\d.]+),turn=([\d.]+)\}',
            layout,
        )
        self.assertIsNotNone(shchierbin)
        self.assertGreater(
            pair_distance(paracelsin, polar(*map(float, shchierbin.groups()))),
            18,
        )


if __name__ == "__main__":
    unittest.main()
