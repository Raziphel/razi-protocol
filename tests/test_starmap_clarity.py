"""Geometry regressions for Factorio compass bearings and circular star systems."""
import math
import re
import unittest
from collections import defaultdict, deque
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STARS = ("solaris", "nyxaris", "vibrant", "vespera", "beetlejuice", "umbra")
PAIRS = (("solaris", "nyxaris"), ("vibrant", "vespera"),
         ("beetlejuice", "umbra"))


def parse_layout():
    source = (ROOT / "prototypes/system/galaxy_layout.lua").read_text()
    pattern = r'\{"(?:planet|space-location)","([^"]+)","([^"]+)",([.\d]+),([.\d]+)\}'
    result = {n: (p, float(r), float(a))
              for n, p, r, a in re.findall(pattern, source)}
    belt_source = (ROOT / "prototypes/system/asteroid_belt_integration.lua").read_text()
    for name, distance, orientation in re.findall(
            r'\{"(asteroid-belt-(?:inner|outer)-edge)",([.\d]+),([.\d]+)\}',
            belt_source):
        star_r, star_t = result["vibrant"][1:]
        x = star_r * math.sin(math.tau * star_t) + float(distance) * math.sin(math.tau * float(orientation))
        y = -star_r * math.cos(math.tau * star_t) - float(distance) * math.cos(math.tau * float(orientation))
        result[name] = ("star", math.hypot(x, y),
                        math.atan2(x, -y) / math.tau % 1)
    return result


def parse_routes():
    text = (ROOT / "prototypes/system/route_reconcile.lua").read_text()
    section = text.split("local route_specifications = {", 1)[1]
    section = section.split("-- Paths replaced by", 1)[0]
    pattern = r'\{"([^"]+)", "([^"]+)", (\d+), "([^"]+)"\}'
    return [(a, b, int(km), kind)
            for a, b, km, kind in re.findall(pattern, section)]


def positions(anchors):
    cache = {"star": (0.0, 0.0)}

    def pos(name):
        if name not in cache:
            parent, radius, turn = anchors[name]
            px, py = pos(parent)
            cache[name] = (px + radius * math.sin(math.tau * turn),
                           py - radius * math.cos(math.tau * turn))
        return cache[name]

    for name in anchors:
        pos(name)
    return cache


def segment_clearance(p, a, b):
    dx, dy = b[0] - a[0], b[1] - a[1]
    norm = dx * dx + dy * dy
    t = max(0, min(1, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy)
                        / norm)) if norm else 0
    return math.dist(p, (a[0] + dx * t, a[1] + dy * t))


def cross(a, b, c, d):
    def side(x, y, z):
        return ((y[0] - x[0]) * (z[1] - x[1])
                - (y[1] - x[1]) * (z[0] - x[0]))
    return side(a, b, c) * side(a, b, d) < 0 and (
        side(c, d, a) * side(c, d, b) < 0)


class ConstellationTests(unittest.TestCase):
    def setUp(self):
        self.anchors = parse_layout()
        self.coords = positions(self.anchors)
        self.routes = parse_routes()

    def test_calidus_centered_radial_gallery(self):
        centers = {
            "solaris": (52, 104 * math.sqrt(3) / 2),
            "nyxaris": (-52, 104 * math.sqrt(3) / 2),
            "vibrant": (104, 0), "vespera": (-104, 0),
            "beetlejuice": (52, -104 * math.sqrt(3) / 2),
            "umbra": (-52, -104 * math.sqrt(3) / 2),
            "solar-system-edge": (0, -190),
        }
        for name, xy in centers.items():
            self.assertLess(math.dist(self.coords[name], xy), 1.0,
                            f"{name} moved from its radial sector")
        expected_bearings = {
            "solaris": 5 / 12, "nyxaris": 7 / 12,
            "vibrant": 1 / 4, "vespera": 3 / 4,
            "beetlejuice": 1 / 12, "umbra": 11 / 12
        }
        for name, bearing in expected_bearings.items():
            self.assertAlmostEqual(self.anchors[name][2], bearing, places=5)
            self.assertAlmostEqual(self.anchors[name][1], 104, places=4)
        radii = [math.dist(self.coords[name], (0, 0)) for name in STARS]
        self.assertLess(max(radii) - min(radii), 3.0,
                        "Major stars must share one circular orbit radius")
        self.assertTrue(all(100 < r < 108 for r in radii))
        for a, b in PAIRS:
            self.assertAlmostEqual(self.coords[a][1], self.coords[b][1], delta=1)
        self.assertLess(self.coords["solar-system-edge"][1], -185,
                        "Deep Space must be north, not south of the galaxy")
        self.assertGreater(self.coords["solar-system-edge"][1], -200,
                           "Deep Space drifted too far outside compact view")

    def test_compact_ring_respects_large_optional_orbits(self):
        # Athos (~49.5) and Ferrum (~51.4) have the largest supported
        # non-moon orbital tracks. Their neighboring star circles need a gap.
        from itertools import combinations
        for a, b in combinations(STARS, 2):
            distance = math.dist(self.coords[a], self.coords[b])
            self.assertGreaterEqual(
                distance, 103.5,
                f"Stars {a} and {b} are too close for optional orbit art")
        self.assertLess(
            max(math.dist(self.coords[name], (0, 0)) for name in STARS),
            108, "Galaxy no longer fits the compact six-star circle")

    def test_long_campaign_routes_do_not_cross_each_other(self):
        major = [(a, b) for a, b, _, profile in self.routes
                 if "crossing" in profile or "crosslink" in profile
                 or profile == "deep_edge"]
        for i, (a, b) in enumerate(major):
            if a not in self.coords or b not in self.coords:
                continue
            for c, d in major[i + 1:]:
                if c not in self.coords or d not in self.coords:
                    continue
                if len({a, b, c, d}) != 4:
                    continue
                self.assertFalse(
                    cross(self.coords[a], self.coords[b],
                          self.coords[c], self.coords[d]),
                    f"Campaign route lines cross: {a}-{b} and {c}-{d}")

    def test_factorio_compass_cardinal_directions(self):
        # The exact PlanetsLib get_rectangular_position_from_polar equation.
        bearings = ((0, 0, -10), (.25, 10, 0),
                    (.5, 0, 10), (.75, -10, 0))
        for turn, ex, ey in bearings:
            x = 10 * math.sin(math.tau * turn)
            y = -10 * math.cos(math.tau * turn)
            self.assertAlmostEqual(x, ex, places=5)
            self.assertAlmostEqual(y, ey, places=5)

    def test_natural_planet_crescents_and_clear_stellar_art(self):
        for star in STARS:
            x, y = self.coords[star]
            hx, hy = self.coords["sye-" + star]
            self.assertGreater(math.dist((hx, hy), (x, y)), 25)
            self.assertLess(math.dist((hx, hy), (x, y)), 45)

        for a, b, _, _ in self.routes:
            if a not in self.coords or b not in self.coords:
                continue
            for star in STARS:
                gap = segment_clearance(
                    self.coords[star], self.coords[a], self.coords[b])
                # Sun-belt arrival deliberately ends 14 units from Vibrant.
                tolerance = 13.5 if {a,b} == {
                    "shchierbin", "asteroid-belt-inner-edge"
                } and star=="vibrant" else 15
                self.assertGreaterEqual(
                    gap, tolerance,
                    f"{a}->{b} cuts through {star}: {gap:.1f} units")

    def test_local_routes_have_no_geometric_crossovers(self):
        for star in STARS:
            family = {"sye-" + star}
            family.update(n for n, (p, _, _) in self.anchors.items() if p == star)
            edges = [(a, b) for a, b, _, _ in self.routes
                     if a in family and b in family]
            for i, (a, b) in enumerate(edges):
                for c, d in edges[i + 1:]:
                    if len({a, b, c, d}) < 4:
                        continue
                    self.assertFalse(cross(self.coords[a], self.coords[b],
                                           self.coords[c], self.coords[d]),
                                     f"{star}: {a}-{b} crosses {c}-{d}")

    def test_local_world_labels_have_breathing_room(self):
        for star in STARS:
            family = [n for n, (parent, _, _) in self.anchors.items()
                      if parent == star and "-belt-" not in n]
            for i, a in enumerate(family):
                for b in family[i + 1:]:
                    self.assertGreaterEqual(math.dist(self.coords[a],
                                                       self.coords[b]), 10,
                                            f"{a} overlaps {b}")

    def test_homeward_spokes_and_native_belt(self):
        edges = {tuple(sorted((a,b))) for a,b,_,_ in self.routes}
        for star in STARS:
            self.assertIn(tuple(sorted(("sye-calidus","sye-"+star))), edges)
        for a,b in (("maraxsis","asteroid-belt-inner-edge"),
                    ("asteroid-belt-outer-edge","sye-umbra"),
                    ("sye-solaris","sye-vibrant"),
                    ("sye-nyxaris","sye-vespera")):
            self.assertNotIn(tuple(sorted((a,b))),edges)
        for a,b in (("shchierbin","asteroid-belt-inner-edge"),
                    ("asteroid-belt-outer-edge","sye-beetlejuice")):
            self.assertIn(tuple(sorted((a,b))),edges)
        for side,r in (("inner",14),("outer",20)):
            self.assertAlmostEqual(
                math.dist(self.coords[f"asteroid-belt-{side}-edge"],
                          self.coords["vibrant"]),r,places=3)
        self.assertNotIn(tuple(sorted(("asteroid-belt-inner-edge",
                                      "asteroid-belt-outer-edge"))),edges)

    def test_vibrant_sun_belt_clearance(self):
        for n,(parent,_,_) in self.anchors.items():
            if parent=="vibrant":
                self.assertGreater(math.dist(self.coords[n],
                                             self.coords["vibrant"]),22)

    def test_bellicos_annex_tracks_actual_visible_orbit(self):
        source = (ROOT / "prototypes/system/bellicos.lua").read_text()
        self.assertIn('110,0.12', source)
        self.assertIn('28,0.10,true', source)
        self.assertIn('place(near,pulsar,3,0.25)', source)
        self.assertEqual(source.count("position_expedition()"), 3)


if __name__ == "__main__":
    unittest.main()
