"""Check route km against Razi's projected starmap and tier progression."""
import importlib.util
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location(
    "route_distances", ROOT / "scripts" / "audit_route_distances.py")
routes_audit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(routes_audit)

def route_manifest():
    source = (ROOT / "prototypes/system/route_reconcile.lua").read_text()
    section = source.split("local route_specifications = {", 1)[1]
    section = section.split("-- Paths replaced by", 1)[0]
    pattern = r'\{"([^"]+)",\s*"([^"]+)",\s*(\d+),\s*"([^"]+)"\}'
    return [(a, b, int(length), kind)
            for a, b, length, kind in re.findall(pattern, section)]

def world():
    star = {"name": "star"}
    raw = {
        "space-location": {"star": star},
        "planet": {},
        "space-connection": {}
    }
    # The actual core star-map anchors from galaxy_layout.lua.
    stars = {
        "sye-calidus": ("star", 32, .25),
        "solaris": ("star", 140, .173),
        "nyxaris": ("star", 140, .327),
        "vibrant": ("star", 251, .208),
        "vespera": ("star", 251, .292),
        "beetlejuice": ("star", 369, .222),
        "umbra": ("star", 369, .278),
        "solar-system-edge": ("star", 485, .25),
        "sye-solaris": ("solaris", 50, .82),
        "sye-nyxaris": ("nyxaris", 50, .82),
        "sye-vibrant": ("vibrant", 50, .82),
        "sye-vespera": ("vespera", 50, .82),
        "sye-beetlejuice": ("beetlejuice", 50, .82),
        "sye-umbra": ("umbra", 50, .82),
        "secretas": ("beetlejuice", 34, .50),
    }
    for name, (parent, distance, angle) in stars.items():
        raw["space-location"][name] = {
            "orbit": {"parent": {"name": parent}, "distance": distance,
                      "orientation": angle}}
    raw["planet"]["vesta"] = {
        "orbit": {"parent": {"name": "umbra"}, "distance": 37,
                  "orientation": .37}}
    for a, b, length, kind in route_manifest():
        raw["space-connection"][f"link-{a}-{b}"] = {
            "from": a, "to": b, "length": length}
    return raw

class RouteTests(unittest.TestCase):
    def test_real_razi_manifest_matches_final_star_map_and_gameplay(self):
        raw = world()
        self.assertEqual(routes_audit.audit(raw), [])

    def test_old_underpriced_paired_stars_are_detected(self):
        raw = world()
        for pair, old_length in (
            (("sye-solaris", "sye-nyxaris"), 32000),
            (("sye-vibrant", "sye-vespera"), 38000),
            (("sye-beetlejuice", "sye-umbra"), 45000)):
            modified = dict(raw["space-connection"])
            match = next(k for k, v in modified.items()
                         if routes_audit.key(v["from"], v["to"]) ==
                         routes_audit.key(*pair))
            original = modified[match]
            modified[match] = {**original, "length": old_length}
            self.assertTrue(any("Too-short interstellar route" in message
                                for message in routes_audit.audit({
                                    **raw, "space-connection": modified})))

    def test_an_out_of_order_deep_space_shortcut_is_detected(self):
        raw = world()
        raw["space-connection"]["old-outer-shortcut"] = {
            "from": "vesta", "to": "secretas", "length": 23000}
        self.assertTrue(any("Unsafe belt bypass" in issue
                            for issue in routes_audit.audit(raw)))

    def test_outer_star_to_deep_space_too_short(self):
        raw = world()
        for route in raw["space-connection"].values():
            if routes_audit.key(route["from"], route["to"]) == (
                    "secretas", "solar-system-edge"):
                route["length"] = 75000
        self.assertTrue(any("Too-short interstellar route" in issue
                            for issue in routes_audit.audit(raw)))

    def test_independent_mod_locations_are_not_rewritten_or_required(self):
        raw = world()
        raw["space-location"]["native-dea-dia"] = {}
        raw["space-connection"]["native-dea-dia-bridge"] = {
            "from": "native-dea-dia", "to": "solaris", "length": 2500}
        self.assertEqual(routes_audit.audit(raw), [])
        del raw["space-location"]["secretas"]
        self.assertEqual(routes_audit.audit(raw), [])

    def test_geometric_angle_sign_and_parent_position(self):
        raw = world()
        coords = routes_audit.positions(raw)
        self.assertLess(coords["sye-solaris"][1], 0)
        self.assertGreater(coords["sye-nyxaris"][1], 0)
        self.assertLess(coords["sye-solaris"][0], coords["sye-vibrant"][0])
        self.assertLess(coords["sye-vibrant"][0], coords["sye-beetlejuice"][0])

if __name__ == "__main__":
    unittest.main()
