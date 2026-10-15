"""Every manifest dependency has an explicit reviewed owner and purpose.

These tests are deliberately offline. A complete Factorio startup is still
required before treating a newly recommended companion as fully verified.
"""
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def manifest():
    return json.loads((ROOT/"info.json").read_text(encoding="utf-8"))


def policy():
    return json.loads(
        (ROOT/"compat/dependency_policy.json").read_text(encoding="utf-8")
    )


def parse(raw):
    parts=raw.split()
    if parts[0] in ("+", "?", "!", "(?)", "~"):
        symbol,name=parts[0],parts[1]
    else:
        symbol,name="",parts[0]
    return name,{
        "":"required","+":"recommended","?":"optional",
        "!":"incompatible","(?)":"hidden-optional",
        "~":"load-order-independent",
    }[symbol]


class DependencyPolicyTests(unittest.TestCase):
    def test_every_dependency_has_one_matching_policy_entry(self):
        actual=manifest()["dependencies"]
        registered=policy()["dependencies"]
        self.assertEqual(len(actual),len(set(actual)))
        self.assertEqual(len(registered),len(actual))
        self.assertEqual(
            {row["declaration"] for row in registered},set(actual)
        )
        names=set()
        for row in registered:
            name,kind=parse(row["declaration"])
            self.assertEqual(row["mod"],name)
            self.assertEqual(row["type"],kind)
            self.assertTrue(row.get("group") and row.get("reason"))
            self.assertNotIn(name,names)
            names.add(name)

    def test_core_k2so_and_curated_planets_remain_required(self):
        dependencies=manifest()["dependencies"]
        for name in (
            "Krastorio2-spaced-out","Krastorio2Assets",
            "k2-dyson-sphere-rebalance",
            "nulls-k2so-tweaks","xy-k2so-enhancements-nulls-fork",
            "planet-muluna","panglia_planet","Nexus-Updated",
            "razi_lib","PlanetsLib","nulla","PlanetAthos",
        ):
            self.assertTrue(any(s.startswith(name+" >=")
                                for s in dependencies),name)

    def test_recommended_companions_not_implicitly_required(self):
        deps=manifest()["dependencies"]
        recommended={
            name for raw in deps if raw.startswith("+ ")
            for name,kind in [parse(raw)]
        }
        self.assertEqual(recommended,{
            "aai-signal-transmission","Imersite-Asteroids",
            "planet-express","upgraded-rocket-turrets",
            "celestial-weather-additions-updated","frozeta-nuclear-winter",
            "Cold_biters","science-tab","Big-Monsters",
            "Various_Cargo_Bays","space-age-railway-expansion",
            "shield-generators","CircuitLaunchableRockets",
            "CargoBayLimitResearch","platform-logistics-overhaul",
            "secretas-orbit-patch","VoidProcessing-Updated",
            "ArmouredBiters21Compat","Explosive_biters",
            "LithiumBattery","rabbasca-underground","skewer_shattered_planet",
            "planet-ferrum",
        })
        for candidate in recommended:
            self.assertFalse(any(raw.startswith(candidate+" ")
                                 for raw in deps),candidate)
        self.assertNotIn("Nexus-Threat-Updated >= 1.1.0",deps)
        self.assertNotIn("slp-dyson-sphere-reworked-fork >= 1.0.5",deps)
        self.assertIn("(?) FluxWorks >= 0.2.12",deps)
        self.assertIn("! outer-rim",deps)
        self.assertIn("! Hephaestus",deps)
        self.assertFalse(any(raw.startswith("+ Hephaestus")
                             for raw in deps))
        self.assertIn("! kry-asteroid-belt",deps)
        self.assertIn("+ celestial-weather-additions-updated >= 1.6.0",deps)
        self.assertIn("+ frozeta-nuclear-winter >= 1.12.1",deps)
        self.assertFalse(any(raw.startswith("+ celestial-weather-updated") for raw in deps))
        self.assertEqual({d for d in deps if d.startswith("? ")},{
            "? shchierbin >= 0.3.19",
                    })
        self.assertFalse(any("moon-eneas" in d or "Solar-Halo" in d for d in deps))
        self.assertIn("PlanetAthos >= 1.1.3",deps)
        self.assertIn("nulla >= 1.0.2",deps)
        for name in ("dea-dia-system","pelagos"):
            self.assertFalse(any(parse(raw)[0]==name for raw in deps),name)
        self.assertIn("+ secretas-orbit-patch >= 1.1.3",deps)
        self.assertNotIn("+ outer-rim",deps)
        self.assertNotIn("+ kry-asteroid-belt",deps)

    def test_science_tab_absence_is_safe_for_razi_owned_cards(self):
        cards=(ROOT/"prototypes/compat/lab_cards.lua").read_text(
            encoding="utf-8")
        self.assertIn('data.raw["item-group"]["science"]',cards)
        self.assertIn('"intermediate-products"',cards)
        self.assertIn('ensure_item_subgroup(system_card_subgroup, group',cards)
        for script in (
            "prototypes/compat/science_tab.lua",
            "prototypes/compat/cold_biters.lua",
            "prototypes/technology/galactic_mod_research.lua",
        ):
            self.assertIn("mods[",(
                ROOT/script).read_text(encoding="utf-8"),script)

    def test_no_automatic_ci_trigger(self):
        workflow=(ROOT/".github/workflows/check.yml").read_text(
            encoding="utf-8")
        self.assertIn("workflow_dispatch:",workflow)
        self.assertNotIn("\n  push:",workflow)
        self.assertNotIn("\n  pull_request:",workflow)


if __name__=="__main__":
    unittest.main()
