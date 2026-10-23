"""Geometry, hazards and source-art contracts for the southern Aegis frontier.

Runs offline against source Lua; no Factorio environment or third-party mod
assets are copied. The native runtime fixture covers source prototype types.
"""
import math
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path):
    return (ROOT / path).read_text(encoding="utf-8")


def anchors():
    layout = read("prototypes/system/galaxy_layout.lua")
    belt = read("prototypes/system/asteroid_belt_integration.lua")
    result = {}
    for name, parent, radius, turn in re.findall(
        r'\{"(?:planet|space-location)","([^"]+)","([^"]+)",([\d.]+),([\d.]+)\}',
        layout,
    ):
        result[name] = (parent, float(radius), float(turn))
    for name, parent, radius, turn in re.findall(
        r'\{name="([^"]+)",star="([^"]+)",radius=([\d.]+),turn=([\d.]+)\}',
        layout,
    ):
        result[name] = (parent, float(radius), float(turn))
    for name, radius, turn in re.findall(
        r'\{"(asteroid-belt-(?:inner|outer)-edge)",([\d.]+),([\d.]+)\}',
        belt,
    ):
        result[name] = ("vibrant", float(radius), float(turn))
    return result


def point(name, data, cache=None):
    if cache is None:
        cache = {"star": (0., 0.)}
    if name not in cache:
        parent, radius, turn = data[name]
        x, y = point(parent, data, cache)
        cache[name] = (
            x + radius * math.sin(2 * math.pi * turn),
            y - radius * math.cos(2 * math.pi * turn),
        )
    return cache[name]


def crossed(a, b, c, d):
    def area(p, q, r):
        return (q[0] - p[0]) * (r[1] - p[1]) - (q[1] - p[1]) * (r[0] - p[0])
    return (
        area(a, b, c) * area(a, b, d) < -1e-7
        and area(c, d, a) * area(c, d, b) < -1e-7
    )


class SouthernAegis(unittest.TestCase):
    def test_dual_approaches_and_southward_position(self):
        layout = anchors()
        root = point("sye-calidus", layout)
        sx, sy = point("solaris", layout)
        nx, ny = point("nyxaris", layout)
        bel = read("prototypes/system/bellicos.lua")
        approved = read("prototypes/system/route_authority.lua")
        self.assertIn('root_parent = "sye-calidus"', bel)
        self.assertIn("pulsar_radius, pulsar_turn = 190, .5", bel)
        self.assertIn("entry_radius, entry_turn = 153, .469", bel)
        self.assertAlmostEqual(sx, -nx, places=3)
        self.assertAlmostEqual(sy, ny, places=3)
        cx, cy = (root[0], root[1] + 190)
        self.assertAlmostEqual(cx, (sx + nx) / 2, places=3)
        self.assertGreater(cy, sy + 95)
        gate = (
            root[0] + 153 * math.sin(2 * math.pi * .469),
            root[1] - 153 * math.cos(2 * math.pi * .469),
        )
        self.assertGreater(gate[0], 20)
        self.assertGreater(gate[1], sy + 50)
        self.assertLess(gate[1], cy)
        self.assertIn(
            '{"sye-solaris","calidus-bellicos-stargate-calidus",112000,"aegis_approach"}',
            approved,
        )
        self.assertIn(
            '{"sye-nyxaris","calidus-bellicos-stargate-calidus",118000,"aegis_approach"}',
            approved,
        )
        self.assertFalse(crossed(point("sye-solaris", layout), gate,
                                 point("sye-nyxaris", layout), gate))
        self.assertNotIn('{"sye-vespera","calidus-bellicos-stargate-calidus"}', approved)

    def test_native_art_halo_has_one_authoritative_anchor(self):
        bel = read("prototypes/system/bellicos.lua")
        bg = read("prototypes/system/starmap_background.lua")
        self.assertIn("function bellicos.pulsar_position()", bel)
        self.assertIn('require("prototypes.system.bellicos").pulsar_position()', bg)
        self.assertNotIn("x+170*math.sin", bg)
        self.assertIn("layer.planetslib_orbit_shift", bel)
        self.assertIn("bellicos.reconcile_final_positions()", bel)

    def test_vibrant_outside_worlds_and_one_physical_crossing(self):
        data = anchors()
        vx, vy = point("vibrant", data)
        def radius(n):
            x, y = point(n, data)
            return math.hypot(x - vx, y - vy)
        for n in ("ribbonia", "fulgora"):
            self.assertLess(radius(n), 31)
        for n in ("paracelsin", "shchierbin", "alchemy-planet", "sye-vibrant"):
            self.assertGreater(radius(n), 39)
        self.assertAlmostEqual(radius("asteroid-belt-inner-edge"), 31, places=3)
        self.assertAlmostEqual(radius("asteroid-belt-outer-edge"), 39, places=3)
        inner = point("asteroid-belt-inner-edge", data)
        outer = point("asteroid-belt-outer-edge", data)
        self.assertGreater(math.dist(inner, outer), 14)
        self.assertLess(math.dist(inner, outer), 22)
        self.assertLess(math.dist(outer, point("paracelsin", data)), 15)
        routes = read("prototypes/system/route_reconcile.lua")
        self.assertIn('{"ribbonia", "asteroid-belt-inner-edge",', routes)
        self.assertIn('{"asteroid-belt-outer-edge", "paracelsin",', routes)

    def test_aegis_route_spine_has_no_shortcut_chords(self):
        source = read("prototypes/system/bellicos.lua")
        self.assertIn('connect(entry_gate,"aegis-outer-edge",56000', source)
        self.assertIn('connect("aegis-outer-edge","aegis-inner-edge",45000', source)
        self.assertIn('connect("aegis-inner-edge",first,38000', source)
        self.assertIn('connect(first,bellicos_gate,47000', source)
        self.assertNotIn('connect(entry_gate,bellicos_gate', source)
        self.assertIn('routes[old.name]=nil', source)
        self.assertIn('asteroid.preserve_custom(candidate,old.route)', source)
        self.assertIn('route.shape="line"', source)

    def test_risk_and_research_have_the_right_tiers(self):
        profile = read("prototypes/system/asteroid_profiles.lua")
        bel = read("prototypes/system/bellicos.lua")
        level = read("scripts/razi_asteroid_difficulty.lua")
        tech = read("prototypes/compat/planet_arrival_pacing.lua")
        self.assertIn('aegis_approach={"aquilo_solar_system_edge",1.65', profile)
        self.assertIn('aegis_depths={big=0.014,huge=0.0021}', profile)
        self.assertIn('asteroid.apply_field(route,spec.profile=="aegis_approach"', bel)
        self.assertIn('["calidus-bellicos-stargate-calidus"]=8', level)
        self.assertIn('["calidus-bellicos-stargate-bellicos"]=10', level)
        self.assertIn('gate("discovery-aegis-outer", "solaris-discovery")', tech)
        self.assertIn('gate("discovery-aegis-outer", "nyxaris-discovery")', tech)

    def test_deep_space_fills_freed_northern_sector(self):
        data = anchors()
        edge = point("solar-system-edge", data)
        self.assertAlmostEqual(edge[1], -250, places=2)
        black = point("black-hole", data)
        nexus = point("nexus", data)
        sol = point("sol", data)
        self.assertLess(black[0], -130)
        self.assertGreater(nexus[0], 80)
        self.assertGreater(sol[0], 235)
        self.assertLess(sol[1], -400)


if __name__ == "__main__":
    unittest.main()
