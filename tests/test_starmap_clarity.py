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
    # Include installed optional Vibrant worlds in belt-crossing clearance.
    for name in ("igrys", "foliax", "ferrum", "alchemy-planet",
                 "obsidiax", "bm-balack", "carna", "arcanyx",
                 "shchierbin"):
        match = re.search(
            rf'\{{name="{name}",star="([^"]+)",radius=([\d.]+),turn=([\d.]+)\}}',
            source)
        if match:
            parent, radius, angle = match.groups()
            result[name] = (parent, float(radius), float(angle))
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

    def test_retired_drift_not_in_live_layout(self):
        self.assertNotIn("razi-calidus-drift",self.anchors)
        self.assertNotIn("razi-calidus-drift",self.coords)
        self.assertFalse(any("razi-calidus-drift" in (start,end)
                             for start,end,_,_ in self.routes))

    def test_calidus_centered_radial_gallery(self):
        centers = {
            "solaris": (52, 104 * math.sqrt(3) / 2),
            "nyxaris": (-52, 104 * math.sqrt(3) / 2),
            "vibrant": (104, 0), "vespera": (-104, 0),
            "beetlejuice": (62, -124 * math.sqrt(3) / 2),
            "umbra": (-62, -124 * math.sqrt(3) / 2),
            "solar-system-edge": (0, -215),
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
            expected_radius=124 if name in ("beetlejuice","umbra") else 104
            self.assertAlmostEqual(self.anchors[name][1], expected_radius, places=4)
        radii = [math.dist(self.coords[name], (0, 0)) for name in STARS]
        self.assertAlmostEqual(max(radii)-min(radii),20,delta=.05,
                               msg="Both outer stars should allow larger optional-world orbits")
        self.assertTrue(all(100 < r < 125 for r in radii))
        for a, b in PAIRS:
            self.assertAlmostEqual(self.coords[a][1], self.coords[b][1], delta=1)
        self.assertLess(self.coords["solar-system-edge"][1], -210,
                        "Deep Space must sit beyond the outer stars")
        self.assertGreater(self.coords["solar-system-edge"][1], -220,
                           "Deep Space drifted too far outside the starmap")

    def test_compact_ring_respects_large_optional_orbits(self):
        # Even with exterior Vibrant worlds, neighboring star art needs a gap.
        # Its neighboring star circles still need a gap.
        from itertools import combinations
        for a, b in combinations(STARS, 2):
            distance = math.dist(self.coords[a], self.coords[b])
            self.assertGreaterEqual(
                distance, 103.5,
                f"Stars {a} and {b} are too close for optional orbit art")
        self.assertLess(
            max(math.dist(self.coords[name], (0, 0)) for name in STARS),
            125, "The outer systems are beyond their planned radial sectors")

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
            self.assertLess(math.dist((hx, hy), (x, y)),
                            65 if star=="vibrant" else 45)

        for a, b, _, _ in self.routes:
            if a not in self.coords or b not in self.coords:
                continue
            for star in STARS:
                gap = segment_clearance(
                    self.coords[star], self.coords[a], self.coords[b])
                # The one legitimate crossing passes between the belt rims.
                tolerance = 15
                self.assertGreaterEqual(
                    gap, tolerance,
                    f"{a}->{b} cuts through {star}: {gap:.1f} units")

    def test_solaris_planets_have_real_orbits_and_a_clean_corridor(self):
        expected = {
            "vulcanus": 17, "hyarion": 21, "arig": 24,
            "castra": 27, "tellus": 29, "corrundum": 33, "igrys": 35,
        }
        for name, radius in expected.items():
            self.assertEqual(self.anchors[name][0], "solaris")
            self.assertAlmostEqual(self.anchors[name][1], radius)
        self.assertAlmostEqual(self.anchors["sye-solaris"][1], 44)
        self.assertAlmostEqual(self.anchors["sye-solaris"][2], .84)
        self.assertAlmostEqual(self.anchors["igrys"][2], .905)
        solaris = set(expected) | {"sye-solaris"}
        actual = {frozenset((a,b)) for a,b,_,_ in self.routes
                  if a in solaris and b in solaris}
        intended = {
            frozenset((a,b)) for a,b in (
                ("sye-solaris","vulcanus"),("sye-solaris","igrys"),
                ("vulcanus","castra"),("castra","arig"),
                ("vulcanus","arig"),("arig","hyarion"),
                ("hyarion","tellus"),("tellus","corrundum"),
                ("hyarion","corrundum"),("corrundum","igrys"),
            )
        }
        self.assertEqual(actual,intended)
        self.assertIn(frozenset(("corrundum","igrys")),actual)
        # Planet orbits remain within 35 units; the gateway is outside the
        # northwest rim and every marker is clear of its neighbors.
        # into each other, even with the crowded Galactic Ops toolbar.
        local_positions=[self.coords[world] for world in solaris]
        for i,first in enumerate(local_positions):
            for second in local_positions[i+1:]:
                self.assertGreaterEqual(math.dist(first,second),12.5)
        for a,b,_,_ in self.routes:
            if a in solaris and b in solaris:
                self.assertGreaterEqual(
                    segment_clearance(self.coords["solaris"],
                                      self.coords[a], self.coords[b]),15,
                    f"Solaris route {a}-{b} intersects the stellar corona")

    def test_solaris_exits_fan_outside_local_ring(self):
        nodes={"sye-solaris","vulcanus","castra","arig","hyarion",
               "tellus","corrundum","igrys"}
        local=[(a,b) for a,b,_,_ in self.routes if a in nodes and b in nodes]
        gateway=self.coords["sye-solaris"]
        for target in ("sye-calidus","sye-nyxaris","sye-vibrant"):
            endpoint=self.coords[target]
            self.assertGreaterEqual(segment_clearance(
                self.coords["solaris"],gateway,endpoint),35)
            for a,b in local:
                if "sye-solaris" not in (a,b):
                    self.assertFalse(cross(gateway,endpoint,
                                           self.coords[a],self.coords[b]),
                        f"Solaris exit to {target} crosses local {a}-{b}")

    def test_nyxaris_biological_crescent(self):
        worlds = ("sye-nyxaris", "gleba", "moshine",
                  "apia-carnova-orbit", "panglia", "foliax")
        for i, name in enumerate(worlds):
            self.assertEqual(self.anchors[name][0], "nyxaris")
            for other in worlds[i + 1:]:
                self.assertGreaterEqual(
                    math.dist(self.coords[name], self.coords[other]), 18,
                    f"Nyxaris labels overlap: {name} / {other}")
        edges = {frozenset((a, b)) for a, b, _, _ in self.routes}
        self.assertIn(frozenset(("gleba", "apia-carnova-orbit")), edges)
        for world in ("gleba", "moshine"):
            self.assertIn(frozenset(("sye-nyxaris", world)), edges)
            self.assertGreaterEqual(
                segment_clearance(self.coords["nyxaris"],
                                  self.coords["sye-nyxaris"],
                                  self.coords[world]), 15,
                f"Nyxaris departure to {world} clips the corona")

    def test_neighbor_networks_have_alternate_paths(self):
        edges={frozenset((a,b)) for a,b,_,_ in self.routes}
        triangles={
            "solaris": (("vulcanus","castra","arig"),
                        ("hyarion","tellus","corrundum")),
            "nyxaris": (("gleba","moshine","apia-carnova-orbit"),),
            "beetlejuice": (("cubium","linox-planet_linox","secretas"),),
        }
        for system,loops in triangles.items():
            for a,b,c in loops:
                for u,v in ((a,b),(b,c),(a,c)):
                    self.assertIn(frozenset((u,v)),edges,
                                  f"{system} should offer a nearby alternative")
                    self.assertGreaterEqual(segment_clearance(
                        self.coords[system],self.coords[u],self.coords[v]),15)
        for a,b in (("sye-vibrant","paracelsin"),
                    ("ribbonia","paracelsin"),("aquilo","rubia"),
                    ("crucible-orbit","vesta")):
            self.assertNotIn(frozenset((a,b)),edges,
                             "Route shortcut bypassed an asteroid belt")

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

    def test_vibrant_outer_planets_sit_near_the_belt(self):
        star=self.coords["vibrant"]
        paracelsin=self.coords["paracelsin"]
        khemia=self.coords["alchemy-planet"]
        outer=self.coords["asteroid-belt-outer-edge"]
        self.assertAlmostEqual(math.dist(star,paracelsin),48,places=3)
        self.assertAlmostEqual(math.dist(star,khemia),52,places=3)
        self.assertGreaterEqual(math.dist(star,paracelsin)-39,9)
        self.assertGreaterEqual(math.dist(star,khemia)-39,13)
        self.assertGreater(math.dist(paracelsin,khemia),15)
        self.assertLess(math.dist(paracelsin,khemia),20)
        shchierbin=self.coords["shchierbin"]
        self.assertGreater(math.dist(star,shchierbin),58)
        self.assertGreater(math.dist(paracelsin,shchierbin),27)
        self.assertGreater(math.dist(self.coords["sye-vibrant"],shchierbin),35)
        self.assertGreaterEqual(segment_clearance(
            star,paracelsin,shchierbin),39,
            "Shchierbin must stay outside Vibrant's physical belt")
        self.assertGreaterEqual(segment_clearance(
            star,outer,paracelsin),38.999)
        self.assertGreaterEqual(segment_clearance(
            star,paracelsin,khemia),47.999)
        source=(ROOT/"prototypes/system/community_expansions.lua").read_text()
        self.assertIn("radius=52, orientation=0.625, km=21000",source)

    def test_vibrant_western_belt_is_the_only_rock_crossing(self):
        star=self.coords["vibrant"]
        slip="sye-vibrant"
        inner="asteroid-belt-inner-edge"
        outer="asteroid-belt-outer-edge"
        edges={frozenset((a,b)) for a,b,_,_ in self.routes}
        for a,b in ((slip,outer),(inner,"ribbonia"),
                    ("ribbonia","fulgora"),(outer,"paracelsin"),
                    (outer,"sye-beetlejuice")):
            self.assertIn(frozenset((a,b)),edges)
        for a,b in ((slip,"ribbonia"),(slip,"fulgora"),
                    ("fulgora",outer),("paracelsin",inner)):
            self.assertNotIn(frozenset((a,b)),edges,
                             "Direct connection bypasses the belt")

        # Both rim markers and the Slip Stream are west of the star.
        for name in (slip,inner,outer):
            self.assertLess(self.coords[name][0],star[0]-25)
        self.assertAlmostEqual(math.dist(star,self.coords[inner]),31,places=3)
        self.assertAlmostEqual(math.dist(star,self.coords[outer]),39,places=3)
        self.assertGreater(math.dist(star,self.coords[slip]),59)
        self.assertLess(math.dist(self.coords[slip],
                                  self.coords[outer]),30)
        self.assertGreater(math.dist(self.coords[inner],
                                     self.coords[outer]),7.8)
        self.assertLess(math.dist(self.coords[inner],
                                  self.coords[outer]),8.5)

        # All real straight routes, including both optional planet branches,
        # must stay entirely on their respective side of the rocky annulus.
        optional_source=(ROOT/"prototypes/system/route_authority.lua").read_text()
        optional={
            ("shchierbin","paracelsin"): '{"shchierbin","paracelsin",21000',
            ("alchemy-planet","paracelsin"):
                '{"alchemy-planet","paracelsin",21000',
        }
        for pair,text in optional.items():
            self.assertIn(text,optional_source)
            self.assertTrue(all(name in self.coords for name in pair))

        exterior=(( "sye-solaris",slip),(slip,outer),
                  (outer,"sye-beetlejuice"),(outer,"paracelsin"),
                  ("shchierbin","paracelsin"),("alchemy-planet","paracelsin"))
        interior=((inner,"ribbonia"),("ribbonia","fulgora"))
        for a,b in exterior:
            self.assertGreaterEqual(segment_clearance(
                star,self.coords[a],self.coords[b]),38.999,
                f"Illegal line crosses the rocky belt: {a}-{b}")
        for a,b in interior:
            self.assertLessEqual(max(
                math.dist(star,self.coords[a]),
                math.dist(star,self.coords[b])),31.001,
                f"Inner-world route crosses the rocks: {a}-{b}")

        # Catch any current curated route cutting through Vibrant's rocks,
        # including a later route that was not listed in the local network.
        # The actual one allowed crossing is a native route, not in this list.
        for a,b,_,_ in self.routes:
            if a not in self.coords or b not in self.coords:
                continue
            if max(math.dist(star,self.coords[a]),
                   math.dist(star,self.coords[b]))>31.001:
                self.assertGreaterEqual(segment_clearance(
                    star,self.coords[a],self.coords[b]),38.999,
                    f"{a}-{b} cuts through Vibrant's asteroid belt")

        actual=list(exterior+interior)
        for i,(a,b) in enumerate(actual):
            for c,d in actual[i+1:]:
                if len({a,b,c,d})==4:
                    self.assertFalse(cross(self.coords[a],self.coords[b],
                                           self.coords[c],self.coords[d]),
                                     f"Routes cross each other: {a}-{b}, {c}-{d}")
        # Marker labels should not sit on another lane.
        for a,b in actual:
            for name in (slip,inner,outer,"ribbonia","fulgora",
                         "paracelsin","shchierbin","alchemy-planet"):
                if name not in (a,b):
                    self.assertGreaterEqual(segment_clearance(
                        self.coords[name],self.coords[a],self.coords[b]),
                        8, f"{a}-{b} obscures {name}")

        source=(ROOT/"prototypes/system/asteroid_belt_integration.lua").read_text()
        self.assertIn('{"asteroid-belt-inner-edge",31,0.77}',source)
        self.assertIn('{"asteroid-belt-outer-edge",39,0.775}',source)
        routes=(ROOT/"prototypes/system/route_reconcile.lua").read_text()
        self.assertNotIn('vibrant_exterior_arc',routes)
        self.assertIn('{"sye-vibrant", "asteroid-belt-outer-edge", 36000',routes)
        crossing=(ROOT/"prototypes/system/asteroid_belts.lua").read_text()
        self.assertIn('name="asteroid-belt-inner-edge-asteroid-belt-outer-edge"',
                      crossing)
        self.assertIn('length=5000,shape="line"',crossing)

        # Without that one native connection the inner network is isolated.
        graph=defaultdict(set)
        for a,b,_,_ in self.routes:
            graph[a].add(b)
            graph[b].add(a)
        reached={slip}
        queue=deque([slip])
        while queue:
            for nxt in graph[queue.popleft()]-reached:
                reached.add(nxt)
                queue.append(nxt)
        self.assertNotIn("ribbonia",reached)
        self.assertNotIn("fulgora",reached)

    def test_neighbor_links_are_short_non_crossing_and_belt_safe(self):
        neighbors = (
            ("vulcanus","castra",17500),
            ("vulcanus","arig",21000),
            ("hyarion","corrundum",29500),
            ("gleba","apia-carnova-orbit",26000),
            ("ribbonia","asteroid-belt-inner-edge",24000),
            ("arig","hyarion",12000),
            ("hyarion","tellus",16500),
            ("tellus","corrundum",18000),
            ("corrundum","igrys",32000),
            ("gleba","moshine",17000),
            ("moshine","apia-carnova-orbit",12000),
            ("moshine","panglia",25000),
            ("apia-carnova-orbit","panglia",21000),
            ("asteroid-belt-outer-edge","paracelsin",14000),
            ("linox-planet_linox","secretas",22000),
            ("tenebris","crucible-orbit",20000),
        )
        routes = {(frozenset((a,b))):(km,kind)
                  for a,b,km,kind in self.routes}
        families = {
            "solaris": ("sye-solaris","vulcanus","castra","arig","hyarion",
                        "tellus","corrundum","igrys"),
            "nyxaris": ("sye-nyxaris","gleba","moshine",
                        "apia-carnova-orbit","panglia"),
            "vibrant": ("sye-vibrant","fulgora","ribbonia",
                        "asteroid-belt-inner-edge","asteroid-belt-outer-edge",
                        "paracelsin"),
            "beetlejuice": ("sye-beetlejuice","cubium",
                           "linox-planet_linox","secretas"),
            "umbra": ("sye-umbra","tenebris","crucible-orbit",
                      "razi-umbra-belt-inner","razi-umbra-belt-outer","vesta"),
        }
        for a,b,km in neighbors:
            self.assertEqual(routes[frozenset((a,b))][0],km)
            system=next(s for s,nodes in families.items() if a in nodes and b in nodes)
            ax,bx=self.coords[a],self.coords[b]
            self.assertLess(math.dist(ax,bx),45,
                f"{a}-{b} is not a sensible neighboring-world connection")
            self.assertGreaterEqual(
                segment_clearance(self.coords[system],ax,bx),15,
                f"{a}-{b} passes through the system's sun")
            for other in families[system]:
                if other not in (a,b):
                    self.assertGreaterEqual(
                        segment_clearance(self.coords[other],ax,bx),8,
                        f"{a}-{b} obscures {other}'s map marker")
            for u,v,_,_ in self.routes:
                if u in families[system] and v in families[system] and len(
                    {a,b,u,v})==4:
                    self.assertFalse(cross(ax,bx,self.coords[u],self.coords[v]),
                        f"{a}-{b} crosses {u}-{v}")
        # Outer-side links are fine; inner-to-outer planet bypasses are not.
        for a,b,_,_ in self.routes:
            self.assertNotIn(frozenset((a,b)), {
                frozenset(("ribbonia","paracelsin")),
                                frozenset(("sye-vibrant","paracelsin"))
            })

    def test_local_world_labels_have_breathing_room(self):
        for star in STARS:
            family = [n for n, (parent, _, _) in self.anchors.items()
                      if parent == star and "-belt-" not in n]
            for i, a in enumerate(family):
                for b in family[i + 1:]:
                    self.assertGreaterEqual(math.dist(self.coords[a],
                                                       self.coords[b]), 10,
                                            f"{a} overlaps {b}")

    def test_two_branch_constellation_and_native_belt(self):
        edges = {tuple(sorted((a, b))) for a, b, _, _ in self.routes}
        required = {
            ("sye-calidus", "sye-solaris"),
            ("sye-calidus", "sye-nyxaris"),
            ("sye-solaris", "sye-nyxaris"),
            ("sye-solaris", "sye-vibrant"),
            ("sye-nyxaris", "sye-vespera"),
            ("sye-vespera", "sye-umbra"),
            ("sye-beetlejuice", "sye-umbra"),
        }
        actual = {
            (a, b) for a, b, _, _ in self.routes
            if a.startswith("sye-") and b.startswith("sye-")
        }
        self.assertEqual(
            {tuple(sorted(pair)) for pair in actual},
            {tuple(sorted(pair)) for pair in required},
            "Seven direct routes plus the native belt bridge are required")
        self.assertEqual(
            sum("sye-calidus" in (a, b) for a, b in actual), 2,
            "Calidus should have only the two early departure routes")
        for a, b in (("maraxsis", "asteroid-belt-inner-edge"),
                     ("asteroid-belt-outer-edge", "sye-umbra")):
            self.assertNotIn(tuple(sorted((a, b))), edges)
        for a, b in (("sye-vibrant","asteroid-belt-outer-edge"),
                     ("ribbonia", "asteroid-belt-inner-edge"),
                     ("asteroid-belt-outer-edge", "paracelsin"),
                     ("asteroid-belt-outer-edge", "sye-beetlejuice")):
            self.assertIn(tuple(sorted((a, b))), edges)
        for side, radius in (("inner", 31), ("outer", 39)):
            self.assertAlmostEqual(
                math.dist(self.coords[f"asteroid-belt-{side}-edge"],
                          self.coords["vibrant"]), radius, places=3)
        self.assertNotIn(
            tuple(sorted(("asteroid-belt-inner-edge",
                          "asteroid-belt-outer-edge"))), edges)

    def test_calidus_departure_hub_is_close_but_clear(self):
        # The source Nauvis orbit is not in Razi's layout fixture, so do
        # not pretend the fixture contains it. Verify the known hub position
        # and its safe distance from the central star graphic instead.
        x, y = self.coords["sye-calidus"]
        self.assertAlmostEqual(x, 0, places=2)
        self.assertAlmostEqual(y, 20, places=2)
        self.assertGreater(math.dist((x, y), (0, 0)), 15)

    def test_vespera_has_no_astroid_belt_waypoints(self):
        radius=lambda name:self.anchors[name][1]
        self.assertEqual(sorted(("muria","rubia",
                                 "maraxsis","aquilo"),key=radius),
                         ["muria","rubia","maraxsis","aquilo"])
        self.assertAlmostEqual(self.anchors["rubia"][2],.70)
        self.assertEqual(radius("aquilo"),57)
        self.assertFalse(any("razi-vespera-belt" in n for n in self.coords))
        edges={frozenset((a,b)) for a,b,_,_ in self.routes}
        for a,b in (("sye-vespera","muria"),("muria","rubia"),
                    ("rubia","maraxsis"),("rubia","aquilo")):
            self.assertIn(frozenset((a,b)),edges)
            self.assertGreaterEqual(segment_clearance(
                self.coords["vespera"],self.coords[a],self.coords[b]),15)
        self.assertNotIn("razi-vespera-belt",
            (ROOT/"prototypes/system/asteroid_belts.lua").read_text())
        self.assertNotIn("razi-vespera-belt-survey",
            (ROOT/"prototypes/technology/asteroid_belts.lua").read_text())
        gates=(ROOT/"prototypes/technology/seven_system_gates.lua").read_text()
        self.assertIn('{"planet-discovery-muria"}',gates)
        self.assertIn('{"planet-discovery-rubia"}',gates)

    def test_umbra_belt_is_real_and_outer_world_is_outside(self):
        # This catches both reversed rim radii and the old overlapping
        # 'In/Out' markers seen in the player's October screenshot.
        radius=lambda name:self.anchors[name][1]
        self.assertEqual(radius("razi-umbra-belt-inner"),31)
        self.assertEqual(radius("razi-umbra-belt-outer"),39)
        self.assertEqual(radius("vesta"),56)
        for name in ("tenebris","crucible-orbit","carna","arcanyx"):
            self.assertLess(radius(name),31)
        self.assertEqual(radius("sye-umbra"),54)
        self.assertGreater(radius("sye-umbra"),radius("razi-umbra-belt-outer"))
        self.assertGreaterEqual(math.dist(
            self.coords["razi-umbra-belt-inner"],
            self.coords["razi-umbra-belt-outer"]),8)
        edges={frozenset((a,b)) for a,b,_,_ in self.routes}
        for a,b in (("sye-umbra","razi-umbra-belt-outer"),
                    ("razi-umbra-belt-outer","razi-umbra-belt-inner"),
                    ("razi-umbra-belt-inner","tenebris"),
                    ("tenebris","crucible-orbit"),
                    ("razi-umbra-belt-outer","vesta")):
            self.assertIn(frozenset((a,b)),edges)
            self.assertGreaterEqual(segment_clearance(
                self.coords["umbra"],self.coords[a],self.coords[b]),15)
        for a,b in (("sye-umbra","crucible-orbit"),
                    ("sye-umbra","tenebris"),
                    ("crucible-orbit","razi-umbra-belt-inner")):
            self.assertNotIn(frozenset((a,b)),edges)
        self.assertGreaterEqual(segment_clearance(
            self.coords["umbra"],self.coords["razi-umbra-belt-outer"],
            self.coords["vesta"]),38.999)
        self.assertGreater(radius("vesta")-radius("razi-umbra-belt-outer"),16)
        # Both external arrivals stay outside the rocks; a user can reach
        # the Outer Rim without taking another accidental belt route.
        star=self.coords["umbra"]
        for a,b in (("sye-vespera","sye-umbra"),
                    ("sye-beetlejuice","sye-umbra"),
                    ("sye-umbra","razi-umbra-belt-outer")):
            self.assertGreaterEqual(segment_clearance(
                star,self.coords[a],self.coords[b]),38.999)
        self.assertGreaterEqual(math.dist(
            self.coords["razi-umbra-belt-outer"],
            self.coords["razi-umbra-belt-inner"]),10)
        source=(ROOT/"prototypes/system/route_reconcile.lua").read_text()
        self.assertIn('local selected_umbra_curves={',source)
        self.assertIn('selected_curve(from,to) and "arc"',source)
        self.assertIn('route_reconcile.selected_curve=selected_curve',source)
        authority=(ROOT/"prototypes/system/route_authority.lua").read_text()
        self.assertIn('reconcile.selected_curve(route.from,route.to)',authority)
        survey=(ROOT/"prototypes/technology/asteroid_belts.lua").read_text()
        self.assertIn('prerequisites={"umbra-discovery"}',survey)
        gates=(ROOT/"prototypes/technology/seven_system_gates.lua").read_text()
        self.assertIn('{"umbra-discovery", "razi-umbra-belt-survey"}',gates)

    def test_hot_cold_orbits_and_native_belt_divide(self):
        radius = lambda n: self.anchors[n][1]
        for hot, cooler in (
            ("vulcanus", "castra"), ("hyarion", "castra"),
            ("arig", "castra"), ("moshine", "gleba"),
            ("muria", "aquilo"), ("crucible-orbit", "vesta")
        ):
            self.assertLess(radius(hot), radius(cooler))
        for inner in ("fulgora", "ribbonia"):
            self.assertLess(radius(inner), 31)
        for outer in ("paracelsin",):
            self.assertGreater(radius(outer), 39)
        self.assertGreater(radius("maraxsis"), radius("rubia"))

    def test_pulsar_glare_does_not_change_map_geometry(self):
        source = (ROOT / "prototypes/system/bellicos.lua").read_text()
        self.assertIn('local function soften_pulsar_art()', source)
        self.assertIn('layer.planetslib_orbit_name=="pulsar"', source)
        self.assertIn('razi-starmap-soften-bellicos', source)
        self.assertNotIn('layer.scale=', source)
        self.assertNotIn('layer.shift=', source)

    def test_bellicos_annex_tracks_actual_visible_orbit(self):
        source = (ROOT / "prototypes/system/bellicos.lua").read_text()
        self.assertIn('110,0.12', source)
        self.assertIn('28,0.10,true', source)
        self.assertIn('place(near,pulsar,3,0.25)', source)
        self.assertEqual(source.count("position_expedition()"), 3)


if __name__ == "__main__":
    unittest.main()
