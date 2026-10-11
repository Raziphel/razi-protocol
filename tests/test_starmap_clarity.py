"""Geometry regressions for the branching seven-system Factorio constellation."""
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
        result[name] = ("star", float(distance), float(orientation))
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
            "solaris": (150, -115), "nyxaris": (145, 92),
            "vibrant": (20, 180), "vespera": (-142, 138),
            "beetlejuice": (-180, -25), "umbra": (-102, -151),
            "solar-system-edge": (-292, -155),
        }
        for name, xy in centers.items():
            self.assertLess(math.dist(self.coords[name], xy), 1.0,
                            f"{name} moved from its radial sector")
        for star in STARS:
            self.assertGreater(math.dist(self.coords[star], (0, 0)), 135)

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
                self.assertGreaterEqual(
                    gap, 15,
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

    def test_original_mod_belt_is_the_middle_to_outer_bridge(self):
        edges = {tuple(sorted((a, b))) for a, b, _, _ in self.routes}
        forbidden = (
            ("sye-vibrant", "sye-beetlejuice"),
            ("sye-vespera", "sye-umbra"),
            ("sye-beetlejuice", "sye-umbra"),
            ("sye-solaris", "sye-vespera"),
            ("sye-nyxaris", "sye-vibrant")
        )
        for a, b in forbidden:
            self.assertNotIn(tuple(sorted((a, b))), edges)
        for a, b in (
            ("shchierbin", "asteroid-belt-inner-edge"),
            ("maraxsis", "asteroid-belt-inner-edge"),
            ("asteroid-belt-outer-edge", "sye-beetlejuice"),
            ("asteroid-belt-outer-edge", "sye-umbra")
        ):
            self.assertIn(tuple(sorted((a, b))), edges)

        # The crossing itself belongs to AsteroidBelt, not Razi Protocol.
        neighbors = defaultdict(set)
        for a, b, _, _ in self.routes:
            neighbors[a].add(b)
            neighbors[b].add(a)
        native = ("asteroid-belt-inner-edge", "asteroid-belt-outer-edge")
        neighbors[native[0]].add(native[1])
        neighbors[native[1]].add(native[0])
        reachable = {"sye-calidus"}
        queue = deque(reachable)
        while queue:
            for n in neighbors[queue.popleft()]:
                if n not in reachable:
                    reachable.add(n)
                    queue.append(n)
        self.assertTrue({"sye-beetlejuice", "sye-umbra",
                         "solar-system-edge"}.issubset(reachable))
        self.assertLess(math.dist(self.coords[native[0]], (-96, 86)), 1)
        self.assertLess(math.dist(self.coords[native[1]], (-118, 67)), 1)

    def test_bellicos_annex_tracks_actual_visible_orbit(self):
        source = (ROOT / "prototypes/system/bellicos.lua").read_text()
        self.assertIn('198,0.817', source)
        self.assertIn('34,0.84,true', source)
        self.assertIn('place(near,pulsar,3,0.25)', source)
        self.assertEqual(source.count("position_expedition()"), 3)


if __name__ == "__main__":
    unittest.main()
