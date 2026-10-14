"""Static six-system geometry rules, no full Factorio runtime necessary."""
import importlib.util
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "starmap_geom", ROOT / "scripts/audit_starmap_readability.py")
geom = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(geom)

class StarmapReadabilityTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.anchors, cls.routes = geom.load()
        cls.report = geom.report(cls.anchors, cls.routes)

    def test_distinct_orbits(self):
        lookup = {entry["name"]: entry for entry in self.anchors}
        self.assertGreaterEqual(abs(lookup["vulcanus"]["radius"] -
                                    lookup["hyarion"]["radius"]), 4)
        self.assertGreaterEqual(abs(lookup["gleba"]["radius"] -
                                    lookup["apia-carnova-orbit"]["radius"]), 6)

    def test_no_new_solaris_chord_crossing(self):
        self.assertEqual(self.report["solaris"]["crossing_chords"], [])
        self.assertFalse(any(r["source"] == "vulcanus" and
                             r["destination"] == "arig" for r in self.routes))
        self.assertTrue(any(r["source"] == "vulcanus" and
                            r["destination"] == "hyarion" for r in self.routes))

    def test_belt_entrances_keep_visual_and_real_gates(self):
        gaps = self.report["belt_separation"]
        self.assertGreater(gaps["razi-vespera-belt"], 8)
        self.assertGreater(gaps["razi-umbra-belt"], 8)
        routes = {(r["source"], r["destination"]) for r in self.routes}
        for system in ("vespera", "umbra"):
            self.assertIn((f"razi-{system}-belt-inner",
                           f"razi-{system}-belt-outer"), routes)
        layout = (ROOT / "prototypes/system/galaxy_layout.lua").read_text()
        self.assertIn('["razi-vespera-belt-inner"]=0.25', layout)
        self.assertIn('["razi-vespera-belt-outer"]=0.75', layout)

    def test_vespera_crescent_has_no_crossing_or_obstructed_routes(self):
        # Include the optional worlds that final route authority attaches.
        names = ("sye-vespera", "muria", "aquilo",
                 "razi-vespera-belt-inner", "razi-vespera-belt-outer",
                 "rubia", "maraxsis", "obsidiax", "bm-balack")
        points = geom.positions(self.anchors)
        local = [(r["source"], r["destination"]) for r in self.routes
                 if r["source"] in names and r["destination"] in names]
        local.extend((("obsidiax", "sye-vespera"),
                      ("bm-balack", "aquilo")))
        for i, (a, b) in enumerate(local):
            self.assertGreaterEqual(
                geom.chord_clearance((points["vespera"][0], points["vespera"][1]),
                                     points[a], points[b]), 15,
                (a, b, "star clearance"))
            for other in names:
                if other not in (a, b):
                    self.assertGreaterEqual(
                        geom.chord_clearance(points[other],
                                             points[a], points[b]), 7,
                        (a, b, other, "marker clearance"))
            for c, d in local[i + 1:]:
                if len({a, b, c, d}) == 4:
                    self.assertFalse(geom.segments_cross(
                        points[a], points[b], points[c], points[d]),
                        (a, b, c, d))
        anchors = {a["name"]: a for a in self.anchors}
        planets = ("muria", "aquilo", "rubia", "maraxsis",
                   "obsidiax", "bm-balack")
        for i, a in enumerate(planets):
            for b in planets[i + 1:]:
                self.assertGreaterEqual(
                    abs(anchors[a]["radius"] - anchors[b]["radius"]), 3.5,
                    (a, b, "native orbit ring gap"))
        self.assertGreater(
            geom.distance(points["razi-vespera-belt-inner"],
                          points["razi-vespera-belt-outer"]), 14)

    def test_vespera_local_routes_use_straight_rendering(self):
        reconcile = (ROOT / "prototypes/system/route_reconcile.lua").read_text()
        authority = (ROOT / "prototypes/system/route_authority.lua").read_text()
        self.assertIn('membership[from]=="vespera"', reconcile)
        self.assertIn('or a=="vespera"', authority)
        self.assertIn('pair("obsidiax","sye-vespera")', authority)
        self.assertIn('pair("bm-balack","aquilo")', authority)
        routes = {(r["source"], r["destination"]) for r in self.routes}
        self.assertIn(("razi-vespera-belt-inner",
                       "razi-vespera-belt-outer"), routes)
        self.assertNotIn(("aquilo", "rubia"), routes)

    def test_no_save_game_or_tick_work(self):
        for name in ("scripts/audit_starmap_readability.py",
                     "prototypes/system/galaxy_layout.lua"):
            source = (ROOT / name).read_text()
            self.assertNotIn("on_nth_tick", source)
            self.assertNotIn("create_surface(", source)

if __name__ == "__main__":
    unittest.main()
