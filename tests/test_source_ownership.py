"""Ensure the seven-system ownership boundary cannot regress to old Muria logic."""
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]

class TestSourceOwnership(unittest.TestCase):
    def test_muria_is_owned_by_final_route_pass(self):
        data = (ROOT / "data.lua").read_text(encoding="utf-8")
        fixes = (ROOT / "data-final-fixes.lua").read_text(encoding="utf-8")
        self.assertNotIn('require "prototypes.system.muria"', data)
        self.assertNotIn('deleteRoutesBetween("sye-vibrant", "muria")', fixes)
        self.assertNotIn('name ~= "muria-aquilo"', fixes)
        self.assertFalse((ROOT / "prototypes/system/muria.lua").exists())
        self.assertIn('require("prototypes.system.route_reconcile")', fixes)
        self.assertIn('"sye-vespera", "muria"', (
            ROOT / "prototypes/system/route_reconcile.lua").read_text(encoding="utf-8"))

    def test_recommended_mods_are_curated_and_nonmandatory(self):
        import json
        deps=json.loads((ROOT / "info.json").read_text(encoding="utf-8"))["dependencies"]
        recommended={d.split()[1] for d in deps if d.startswith("+ ")}
        self.assertEqual(len(recommended),24)
        self.assertTrue({"Big-Monsters","secretas-orbit-patch","planet-ferrum",
                         "VoidProcessing-Updated","Solar-Halo"}.issubset(recommended))
        self.assertEqual({d for d in deps if d.startswith("? ")},
                         {"? moon-eneas >= 1.0.10","? shchierbin >= 0.3.19"})
        self.assertIn("(?) FluxWorks >= 0.2.12",deps)
        self.assertIn("! outer-rim",deps)
        self.assertIn("! Hephaestus",deps)
        normalised=[]
        for dep in deps:
            words=dep.split()
            name=words[1] if words[0] in ("+", "?", "(?)", "~", "!") else words[0]
            normalised.append(name)
        self.assertEqual(len(normalised),len(set(normalised)),
                         "A mod may only have one dependency declaration")

    def test_only_integrated_optional_dependencies_are_advertised(self):
        import json
        info = json.loads((ROOT / "info.json").read_text(encoding="utf-8"))
        expected = {
            "Cerys-Moon-of-Fulgora", "dea-dia-system",
            "pelagos", "Nexus-Updated", "VoidProcessing-Updated",
            "Arachnids_enemy", "ArmouredBiters21Compat",
            "Electric_flying_enemies", "Explosive_biters",
            "Toxic_biters", "Imersite-Asteroids", "LithiumBattery",
            # Eleven inspected 2.1 community mods. Nonstandard locations
            # retain their source mod's surface, station or warp machinery.
            "rabbasca-underground", "skewer_shattered_planet",
            "Solar-Halo", "planet-ferrum", "Velora",
            "alchemy-khemia", "Arcanyx",
            "biological-machines-planet-balack",
        }
        names = {dep.split()[1] for dep in info["dependencies"]
                 if dep.startswith(("+ ", "? ", "(?) "))}
        self.assertTrue({"planet-ferrum", "Solar-Halo"}.issubset(names))
        self.assertNotIn("Hephaestus",names)
        self.assertNotIn("dea-dia-system", names)
        self.assertNotIn("pelagos", names)
        self.assertNotIn("biological-machines-planet-wit", names)
        self.assertIn("! PlanetAthos", info["dependencies"])
        self.assertIn("! nulla", info["dependencies"])
        self.assertIn("! biological-machines-planet-wit", info["dependencies"])
        self.assertIn("? moon-eneas >= 1.0.10", info["dependencies"])
        self.assertIn("? shchierbin >= 0.3.19", info["dependencies"])
        self.assertIn("moon-eneas", names)
        self.assertIn("shchierbin", names)
        self.assertFalse((ROOT / "prototypes/system/eneas.lua").exists())
        self.assertNotIn("prototypes.system.eneas", (
            ROOT / "data.lua").read_text(encoding="utf-8"))
        # Prevent future decorative optional dependencies without any
        # corresponding Razi content or explicitly preserved source behavior.
        module = (ROOT / "prototypes/system/community_expansions.lua").read_text(
            encoding="utf-8")
        for mod_id in {
            "rabbasca-underground", "skewer_shattered_planet",
            "Solar-Halo", "planet-ferrum", "Velora",
            "alchemy-khemia", "Arcanyx",
            "biological-machines-planet-balack"
        }:
            self.assertIn(f'mod="{mod_id}"', module)
        routes = (ROOT / "prototypes/system/route_authority.lua").read_text(encoding="utf-8")
        self.assertIn('{"eneas","nauvis",9000,"starter"}',routes)
        self.assertIn('{"shchierbin","paracelsin",21000,"chemistry_deep"}',routes)
        fixes = (ROOT / "data-final-fixes.lua").read_text(encoding="utf-8")
        self.assertIn(
            'require("prototypes.system.community_expansions").data_final_fixes()',
            fixes)

if __name__ == "__main__":
    unittest.main()
