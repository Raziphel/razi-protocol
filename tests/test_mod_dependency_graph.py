"""Offline regression fixtures for Factorio 2.1 Mod Portal dependency closure."""
import importlib.util
import json
import pathlib
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
FILE = ROOT / "scripts" / "audit_mod_dependencies.py"
SPEC = importlib.util.spec_from_file_location("razi_dependency_graph", FILE)
mod = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(mod)


class DependencyGraphTests(unittest.TestCase):
    def make_portal(self, folder, name, releases):
        (folder / (name + ".json")).write_text(
            json.dumps({"releases": releases}), encoding="utf-8")

    def release(self, version, deps, factorio="2.1"):
        return {"version": version, "info_json": {
            "factorio_version": factorio,
            "dependencies": deps
        }}

    def test_classification_parses_versions_and_recommendations(self):
        for value, kind, name, op, version in [
            ("+ Big-Monsters >= 2.2.1", "recommended", "Big-Monsters",
             ">=", "2.2.1"),
            ("? pelagos", "optional", "pelagos", None, None),
            ("(?) hidden", "hidden-optional", "hidden", None, None),
            ("~ decorative", "load-order-independent",
             "decorative", None, None),
            ("! old", "incompatible", "old", None, None),
            ("Nexus-Updated >= 1.4.1", "required", "Nexus-Updated",
             ">=", "1.4.1"),
        ]:
            result = mod.parse(value)
            self.assertEqual((result["kind"], result["name"],
                              result["operator"], result["version"]),
                             (kind, name, op, version))
        self.assertLess(mod.compare_versions("1.1.9", "1.1.10"), 0)
        self.assertTrue(mod.matches_version("2.1.0", ">=", "2.1"))
        with self.assertRaises(ValueError):
            mod.parse("")

    def test_transitive_redundancy_and_stronger_pin(self):
        with tempfile.TemporaryDirectory() as tmp:
            cache = pathlib.Path(tmp)
            # Parent guarantees exactly the minimum for "child".
            self.make_portal(cache, "parent", [
                self.release("3.0.0", ["base", "child >= 1.2.0",
                                       "weaker >= 1.0.0"])
            ])
            self.make_portal(cache, "child", [
                self.release("2.0.0", ["base"])
            ])
            self.make_portal(cache, "weaker", [
                self.release("1.6.0", ["base"])
            ])
            manifest = {"dependencies": [
                "base >= 2.1.20", "parent >= 3.0.0",
                "child >= 1.2.0", "weaker >= 1.5.0",
                "+ Bosses >= 2.0.0", "! broken"
            ]}
            report = mod.audit(manifest, mod.Portal(cache, offline=True))
            self.assertEqual(report["missing_or_incompatible_releases"], [])
            self.assertEqual(report["dependency_violations"], [])
            self.assertEqual(
                [r["mod"] for r in report["redundant_direct_requirements"]],
                ["child"])
            self.assertEqual(
                [r["mod"] for r in
                 report["transitive_with_stronger_direct_version_pins"]],
                ["weaker"])
            self.assertEqual(report["required_direct"], 4)

    def test_non_native_release_and_conflict_are_reported(self):
        with tempfile.TemporaryDirectory() as tmp:
            cache = pathlib.Path(tmp)
            self.make_portal(cache, "root", [
                self.release("1.0.0", ["base", "incompatible"],
                             factorio="2.0"),
                self.release("1.0.1", ["base", "incompatible"],
                             factorio="2.1")
            ])
            self.make_portal(cache, "incompatible", [
                self.release("1.0.0", ["base"], factorio="2.0")
            ])
            report = mod.audit(
                {"dependencies": ["root", "! incompatible"]},
                mod.Portal(cache, offline=True))
            self.assertTrue(report["dependency_violations"])
            self.assertTrue(report["missing_or_incompatible_releases"])

    def test_our_real_declarations_keep_nonredundant_pins(self):
        info = json.loads((ROOT / "info.json").read_text(encoding="utf-8"))
        deps = info["dependencies"]
        self.assertEqual(info["version"], "2.1.73")
        self.assertIn("Nexus-Updated >= 1.4.1", deps)
        self.assertIn("k2-dyson-sphere-rebalance >= 0.1.2", deps)
        self.assertNotIn("Nexus-Threat-Updated >= 1.1.0", deps)
        self.assertNotIn("slp-dyson-sphere-reworked-fork >= 1.0.5", deps)
        for modname, floor in (
            ("planetaris-arig", "1.1.44"),
            ("planetaris-hyarion", "1.3.23"),
            ("planetaris-tellus", "1.1.11"),
            ("Moshine", "1.2.10"),
            ("cubium", "1.0.31"),
        ):
            self.assertIn(modname + " >= " + floor, deps)


if __name__ == "__main__":
    unittest.main()
