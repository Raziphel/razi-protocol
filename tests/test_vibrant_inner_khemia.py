"""Vibrant: the real 31-39 asteroid ring must gate the exterior worlds.

Tests only repo-authored chart geometry and planned links, without requiring
Factorio or copying any third-party Khemia prototypes.
"""
import math
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(name):
    return (ROOT / name).read_text(encoding="utf-8")


def anchors():
    layout = read("prototypes/system/galaxy_layout.lua")
    belt = read("prototypes/system/asteroid_belt_integration.lua")
    result = {"star": (None, 0., 0.)}
    for n, parent, radius, turn in re.findall(
        r'\{"(?:planet|space-location)","([^"]+)","([^"]+)",([\d.]+),([\d.]+)\}',
        layout,
    ):
        result[n] = (parent, float(radius), float(turn))
    for n, parent, radius, turn in re.findall(
        r'\{name="([^"]+)",star="([^"]+)",radius=([\d.]+),turn=([\d.]+)\}',
        layout,
    ):
        result[n] = (parent, float(radius), float(turn))
    for n, radius, turn in re.findall(
        r'\{"(asteroid-belt-(?:inner|outer)-edge)",([\d.]+),([\d.]+)\}',
        belt,
    ):
        result[n] = ("vibrant", float(radius), float(turn))
    return result


def xy(name, data, cache=None):
    if cache is None:
        cache = {"star": (0., 0.)}
    if name not in cache:
        parent, radius, turn = data[name]
        x, y = xy(parent, data, cache)
        cache[name] = (
            x + radius * math.sin(2 * math.pi * turn),
            y - radius * math.cos(2 * math.pi * turn),
        )
    return cache[name]


def intersects(a, b, c, d):
    def area(p, q, r):
        return (q[0] - p[0]) * (r[1] - p[1]) - (q[1] - p[1]) * (r[0] - p[0])
    return (area(a, b, c) * area(a, b, d) < -1e-7
            and area(c, d, a) * area(c, d, b) < -1e-7)


class VibrantInterior(unittest.TestCase):
    def test_rims_touch_the_actual_band(self):
        data = anchors()
        vibrant = xy("vibrant", data)
        inn = xy("asteroid-belt-inner-edge", data)
        out = xy("asteroid-belt-outer-edge", data)
        r = lambda point: math.dist(vibrant, point)
        self.assertAlmostEqual(r(inn), 30., places=2)
        self.assertAlmostEqual(r(out), 40., places=2)
        self.assertLess(r(inn), 31.)
        self.assertGreater(r(out), 39.)
        self.assertLess(math.dist(inn, out), 12.)
        self.assertGreater(math.dist(inn, out), 10.)
        self.assertLess(abs(inn[1] - out[1]), 2.)
        self.assertLess(math.dist(inn, xy("ribbonia", data)), 6.)
        self.assertLess(math.dist(out, xy("paracelsin", data)), 12.)
        self.assertLess(math.dist(out, xy("sye-vibrant", data)), 27.)
        layout = read("prototypes/system/galaxy_layout.lua")
        self.assertIn('["asteroid-belt-inner-edge"]=0.5', layout)
        self.assertIn('["asteroid-belt-outer-edge"]=0.75', layout)

    def test_khemia_is_inhabited_inside_not_reached_across_the_ring(self):
        data = anchors()
        center = xy("vibrant", data)
        for name in ("ribbonia", "fulgora", "alchemy-planet"):
            self.assertLess(math.dist(xy(name, data), center), 30.)
        for name in ("paracelsin", "shchierbin", "sye-vibrant"):
            self.assertGreater(math.dist(xy(name, data), center), 40.)
        self.assertAlmostEqual(data["alchemy-planet"][1], 22.)
        self.assertAlmostEqual(data["alchemy-planet"][2], .81)
        routes = read("prototypes/system/route_reconcile.lua")
        authority = read("prototypes/system/route_authority.lua")
        self.assertIn('{"ribbonia", "alchemy-planet", 18000, "chemistry"}', routes)
        self.assertIn('{"alchemy-planet","ribbonia",18000,"chemistry"}', authority)
        self.assertNotIn('{"alchemy-planet","paracelsin",21000', authority)
        self.assertIn('["alchemy-planet"]=true,["asteroid-belt-inner-edge"]=true', routes)
        self.assertIn('migrating_khemia=route_pair==key_for("alchemy-planet","paracelsin")', routes)
        self.assertIn("profiles.preserve_custom(target,route)", authority)
        pacing = read("prototypes/compat/planet_arrival_pacing.lua")
        for expectation in (
            'remove_parent(name, "planet-discovery-paracelsin")',
            'remove_parent(name, "space-discovery-asteroid-belt")',
            'gate(name, "planet-discovery-ribbonia")',
        ):
            self.assertIn(expectation, pacing)

    def test_all_authored_vibrant_corridors_avoid_crossing(self):
        data = anchors()
        wanted = [
            ("sye-vibrant", "asteroid-belt-outer-edge"),
            ("asteroid-belt-outer-edge", "asteroid-belt-inner-edge"),
            ("asteroid-belt-outer-edge", "paracelsin"),
            ("asteroid-belt-inner-edge", "ribbonia"),
            ("ribbonia", "alchemy-planet"),
            ("fulgora", "ribbonia"),
        ]
        reconciled = re.findall(
            r'\{\s*"([^"]+)"\s*,\s*"([^"]+)"\s*,\s*\d+\s*,\s*"[\w_]+"\s*\}',
            read("prototypes/system/route_reconcile.lua"),
        )
        other = [
            (a, b) for a, b in reconciled
            if a in data and b in data and "alchemy-planet" not in (a, b)
            and "asteroid-belt-inner-edge" not in (a, b)
            and "asteroid-belt-outer-edge" not in (a, b)
        ]
        for i, (a, b) in enumerate(wanted):
            for c, d in other + wanted[i + 1:]:
                if len({a, b, c, d}) != 4:
                    continue
                self.assertFalse(
                    intersects(xy(a, data), xy(b, data), xy(c, data), xy(d, data)),
                    f"New Vibrant route {a}->{b} intersects {c}->{d}",
                )


if __name__ == "__main__":
    unittest.main()
