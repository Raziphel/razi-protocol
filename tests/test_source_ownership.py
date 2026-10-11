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

    def test_only_integrated_optional_dependencies_are_advertised(self):
        import json
        info = json.loads((ROOT / "info.json").read_text(encoding="utf-8"))
        expected = {
            "Cerys-Moon-of-Fulgora", "moon-eneas", "dea-dia-system",
            "pelagos", "Nexus-Updated", "VoidProcessing-Updated",
            "Arachnids_enemy", "ArmouredBiters21Compat",
            "Electric_flying_enemies", "Explosive_biters",
            "Toxic_biters", "Imersite-Asteroids", "LithiumBattery",
            "PlanetAthos",
            # Eleven inspected 2.1 community mods. Nonstandard locations
            # retain their source mod's surface, station or warp machinery.
            "rabbasca-underground", "skewer_shattered_planet",
            "Solar-Halo", "planet-ferrum", "Velora", "nulla",
            "Hephaestus", "alchemy-khemia", "Arcanyx",
            "biological-machines-planet-wit",
            "biological-machines-planet-balack",
        }
        names = {dep.split()[1] for dep in info["dependencies"]
                 if dep.startswith("? ")}
        self.assertEqual(names, expected)
        # Prevent future decorative optional dependencies without any
        # corresponding Razi content or explicitly preserved source behavior.
        module = (ROOT / "prototypes/system/community_expansions.lua").read_text(
            encoding="utf-8")
        for mod_id in {
            "rabbasca-underground", "skewer_shattered_planet",
            "Solar-Halo", "planet-ferrum", "Velora", "nulla",
            "Hephaestus", "alchemy-khemia", "Arcanyx",
            "biological-machines-planet-wit",
            "biological-machines-planet-balack"
        }:
            self.assertIn(f'mod="{mod_id}"', module)
        fixes = (ROOT / "data-final-fixes.lua").read_text(encoding="utf-8")
        self.assertIn(
            'require("prototypes.system.community_expansions").data_final_fixes()',
            fixes)

if __name__ == "__main__":
    unittest.main()
