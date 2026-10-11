"""Geometric regressions for the seven-system Factorio starmap.

These checks consume the authoritative Lua manifests rather than a hand-drawn
mock screenshot. Distances here are *starmap* units, not game travel km.
"""
import math
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LAYOUT = ROOT / "prototypes/system/galaxy_layout.lua"
ROUTES = ROOT / "prototypes/system/route_reconcile.lua"
STARS = ("solaris", "nyxaris", "vibrant", "vespera", "beetlejuice", "umbra")
PAIRS = (("solaris", "nyxaris"), ("vibrant", "vespera"),
         ("beetlejuice", "umbra"))
DIAGONALS = (("sye-solaris", "sye-vespera"),
             ("sye-nyxaris", "sye-vibrant"),
             ("sye-vibrant", "sye-umbra"),
             ("sye-vespera", "sye-beetlejuice"))


def parse_layout():
    text = LAYOUT.read_text(encoding="utf8")
    pattern = r'\{"(?:planet|space-location)","([^"]+)","([^"]+)",(\d+),([.\d]+)\}'
    anchors = {}
    for name, parent, radius, angle in re.findall(pattern, text):
        anchors[name] = (parent, float(radius), float(angle))
    return anchors


def parse_routes():
    text = ROUTES.read_text(encoding="utf8")
    section = text.split("local route_specifications = {", 1)[1]
    section = section.split("-- Paths replaced by", 1)[0]
    pattern = r'\{"([^"]+)", "([^"]+)", (\d+), "([^"]+)"\}'
    return [(a, b, int(km), profile)
            for a, b, km, profile in re.findall(pattern, section)]


def coordinates(anchors):
    cache = {"star": (0.0, 0.0)}

    def position(name):
        if name in cache:
            return cache[name]
        parent, radius, orientation = anchors[name]
        x, y = position(parent)
        angle = math.tau * orientation
        cache[name] = (x + radius * math.sin(angle),
                       y - radius * math.cos(angle))
        return cache[name]

    for name in anchors:
        position(name)
    return cache


def point_to_segment(p, a, b):
    dx, dy = b[0] - a[0], b[1] - a[1]
    denominator = dx * dx + dy * dy
    t = max(0.0, min(1.0, ((p[0] - a[0]) * dx +
                             (p[1] - a[1]) * dy) / denominator)) if denominator else 0
    return math.dist(p, (a[0] + dx * t, a[1] + dy * t))


class VisualStarmapTests(unittest.TestCase):
    def setUp(self):
        self.anchors = parse_layout()
        self.coords = coordinates(self.anchors)
        self.routes = parse_routes()

    def test_system_columns_and_deep_space_are_separated(self):
        previous_x = 0
        for upper, lower in PAIRS:
            x1, y1 = self.coords[upper]
            x2, y2 = self.coords[lower]
            self.assertGreater(x1 - previous_x, 72)
            self.assertLess(abs(x1 - x2), 4)
            self.assertLess(y1, -38)
            self.assertGreater(y2, 38)
            previous_x = x1
        self.assertGreater(self.coords["solar-system-edge"][0], previous_x + 90)
        self.assertLess(self.coords["solar-system-edge"][0], 370)

    def test_hubs_stay_left_and_routes_do_not_cut_through_stars(self):
        for name in STARS:
            sx, sy = self.coords[name]
            hx, hy = self.coords["sye-" + name]
            self.assertLess(hx, sx - 22)
            self.assertLess(hy, sy - 15)

        for a, b, _, _ in self.routes:
            if a not in self.coords or b not in self.coords:
                continue  # Conditional planet and external source location
            for star in STARS:
                clearance = point_to_segment(
                    self.coords[star], self.coords[a], self.coords[b])
                self.assertGreaterEqual(
                    clearance, 15,
                    f"{a} -> {b} cuts through {star} ({clearance:.1f})")

    def test_planetary_route_crescents_have_no_internal_crossings(self):
        # Local links must not turn an otherwise compact system into a knot.
        def side(a, b, p):
            return ((b[0] - a[0]) * (p[1] - a[1])
                    - (b[1] - a[1]) * (p[0] - a[0]))

        def crossed(a, b, c, d):
            return (side(a, b, c) * side(a, b, d) < 0
                    and side(c, d, a) * side(c, d, b) < 0)

        for star in STARS:
            family = {"sye-" + star}
            family.update(
                name for name, (parent, _, _) in self.anchors.items()
                if parent == star
            )
            links = [(a, b) for a, b, _, _ in self.routes
                     if a in family and b in family]
            for i, (a, b) in enumerate(links):
                for c, d in links[i + 1:]:
                    if len({a, b, c, d}) < 4:
                        continue  # Shared endpoints are intentional junctions.
                    self.assertFalse(
                        crossed(self.coords[a], self.coords[b],
                                self.coords[c], self.coords[d]),
                        f"{star}: {a}-{b} crosses {c}-{d}")

    def test_compact_planets_have_readable_node_spacing(self):
        for star in STARS:
            family = [
                name for name, (parent, _, _) in self.anchors.items()
                if parent == star and "-belt-" not in name
            ]
            for i, first in enumerate(family):
                for second in family[i + 1:]:
                    self.assertGreaterEqual(
                        math.dist(self.coords[first], self.coords[second]), 10,
                        f"{star}: {first} and {second} overlap")

    def test_tier_lanes_replace_four_crossing_diagonals(self):
        edges = {tuple(sorted((a, b))) for a, b, _, _ in self.routes}
        for a, b in DIAGONALS:
            self.assertNotIn(tuple(sorted((a, b))), edges)
        for a, b in (("sye-calidus", "sye-solaris"),
                     ("sye-calidus", "sye-nyxaris"),
                     ("sye-solaris", "sye-nyxaris"),
                     ("sye-solaris", "sye-vibrant"),
                     ("sye-nyxaris", "sye-vespera"),
                     ("sye-vibrant", "sye-vespera"),
                     ("sye-vibrant", "sye-beetlejuice"),
                     ("sye-vespera", "sye-umbra"),
                     ("sye-beetlejuice", "sye-umbra")):
            self.assertIn(tuple(sorted((a, b))), edges)

    def test_bellicos_pulsar_is_a_right_side_annex(self):
        source = (ROOT / "prototypes/system/bellicos.lua").read_text(encoding="utf8")
        self.assertIn('name = "pulsar"', source)
        self.assertIn('110, 0.25, false', source)
        self.assertIn('24, 0.25, true', source)
        self.assertIn('40, 0.75, true', source)
        self.assertEqual(source.count("position_expedition()"), 3)


if __name__ == "__main__":
    unittest.main()
