"""Regression guards for relocated Razi 3.0 starmap location tooltips.

The primary Aegis descriptions deliberately replace obsolete source-map
geography. Native gameplay descriptions on other worlds stay intact.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]


def source(path):
    return (ROOT / path).read_text(encoding="utf-8")


def locale(path):
    sections = {}
    section = None
    for raw in source(path).splitlines():
        if raw.startswith("[") and raw.endswith("]"):
            section = raw[1:-1]
            sections.setdefault(section, {})
        elif section and raw and not raw.startswith("#") and "=" in raw:
            key, value = raw.split("=", 1)
            sections[section][key] = value
    return sections


class LocationCopy(unittest.TestCase):
    AEGIS = (
        "calidus-bellicos-stargate-calidus",
        "aegis-inner-edge", "aegis-outer-edge",
        "near-bellicos-orbit", "bellicos-near-orbit", "near_bellicos_orbit",
        "point-warden", "aegis-point-warden",
    )
    OTHER = (
        "pulsar", "vibrant", "ribbonia", "alchemy-planet", "khemia",
        "paracelsin", "shchierbin", "asteroid-belt-inner-edge",
        "asteroid-belt-outer-edge", "sye-solaris", "sye-nyxaris",
        "sye-vibrant", "solar-system-edge", "nexus",
        "black-hole-approach", "oort-cloud", "sol",
        "shattered-planet", "skewer_shattered_planet", "skewer_lost_beyond",
    )

    def test_translated_primary_descriptions_and_razi_briefs(self):
        for lang in ("en", "ru"):
            with self.subTest(locale=lang):
                cfg = locale(f"locale/{lang}/names.cfg")
                self.assertIn("aegis", cfg["razi-expedition-heading"])
                self.assertIn("deep-space", cfg["razi-expedition-heading"])
                for name in self.AEGIS:
                    self.assertTrue(cfg["razi-location-primary"].get(name), (lang, name))
                    self.assertTrue(cfg["razi-location-briefing"].get(name), (lang, name))
                for name in self.OTHER:
                    self.assertTrue(cfg["razi-location-briefing"].get(name), (lang, name))
                self.assertNotIn(
                    "calidus-bellicos-stargate-bellicos",
                    cfg["razi-location-briefing"],
                )
                self.assertNotIn(
                    "calidus-bellicos-stargate-bellicos",
                    cfg["razi-location-primary"],
                )

    def test_aegis_not_in_deep_space_section(self):
        code = source("prototypes/system/planet_descriptions.lua")
        section = re.search(
            r'aegis\s*=\s*\{(.*?)\},\s*deep_space\s*=\s*\{(.*?)\}', code, re.S
        )
        self.assertIsNotNone(section)
        self.assertIn('"calidus-bellicos-stargate-calidus"', section[1])
        self.assertIn('"point-warden"', section[1])
        self.assertNotIn("calidus-bellicos-stargate-calidus", section[2])
        self.assertNotIn("calidus-bellicos-stargate-bellicos", section[1] + section[2])
        self.assertIn("relocated_source_briefs", code)
        self.assertIn('{"razi-location-primary." .. name}', code)
        self.assertIn("if prototype.localised_description then", code)

    def test_removed_gate_and_new_khemia_geography(self):
        en = locale("locale/en/names.cfg")
        ru = locale("locale/ru/names.cfg")
        en_gate = locale("locale/en/compat.cfg")
        ru_gate = locale("locale/ru/compat.cfg")
        for cfg in (en_gate, ru_gate):
            gateway = cfg["space-location-description"][
                "calidus-bellicos-stargate-calidus"
            ]
            self.assertTrue(gateway)
            self.assertNotIn("beyond the edge", gateway.lower())
        self.assertNotIn(
            "deeper Bellicos stargate",
            en_gate["space-location-description"]["calidus-bellicos-stargate-calidus"],
        )
        self.assertIn("Point Warden", en["razi-location-briefing"][
            "calidus-bellicos-stargate-calidus"
        ])
        self.assertIn("Ribbonia", en["razi-location-briefing"]["alchemy-planet"])
        self.assertIn("inside", en["razi-location-briefing"]["alchemy-planet"])
        self.assertIn("Риббони", ru["razi-location-briefing"]["alchemy-planet"])
        for lang in ("en", "ru"):
            cfg = locale(f"locale/{lang}/names.cfg")
            self.assertIn(
                "asteroid-belt-inner-edge", cfg["space-location-description"]
            )
            self.assertIn(
                "asteroid-belt-outer-edge", cfg["space-location-description"]
            )
        dossiers = source("prototypes/system/route_dossiers.lua")
        self.assertIn('{"alchemy-planet","ribbonia","alchemy-spur"}', dossiers)
        self.assertNotIn('{"alchemy-planet","paracelsin","alchemy-spur"}', dossiers)

    def test_no_mistaken_deep_space_gate_role(self):
        en = locale("locale/en/compat.cfg")
        self.assertEqual(
            en["space-location-name"]["calidus-bellicos-stargate-calidus"],
            "Aegis Frontier Gate",
        )
        ru = locale("locale/ru/compat.cfg")
        self.assertNotIn(
            "глубоком космосе",
            ru["space-location-name"]["calidus-bellicos-stargate-calidus"].lower(),
        )


if __name__ == "__main__":
    unittest.main()
