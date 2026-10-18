"""Narrative field notes preserve source worlds and route tooltips."""
import re
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]

def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

def section(text,name):
    m=re.search(r"^\["+re.escape(name)+r"\]\n(.*?)(?=^\[|\Z)",text,re.M|re.S)
    return dict(re.findall(r"^([a-z0-9-_]+)=(.*)$",m.group(1),re.M)) if m else {}

class ExpeditionCopyTests(unittest.TestCase):
    def test_all_briefings_localized_and_have_unique_prose(self):
        en=section(read("locale/en/names.cfg"),"razi-location-briefing")
        ru=section(read("locale/ru/names.cfg"),"razi-location-briefing")
        self.assertGreaterEqual(len(en),80)
        self.assertEqual(set(en),set(ru))
        self.assertEqual(len(set(en.values())),len(en))
        self.assertTrue(all(45<=len(v)<=300 for v in en.values()))
        for key in ("nauvis","muluna","panglia","rubia","athos",
                    "razi-umbra-belt-outer","asteroid-belt-inner-edge",
                    "asteroid-belt-outer-edge","shchierbin","planet-ferrum",
                    "nulla","razi-deep-space-edge"):
            self.assertIn(key,en)
            self.assertIn(key,ru)

    def test_planet_descriptions_keep_source_locale_and_optional_guard(self):
        source=read("prototypes/system/planet_descriptions.lua")
        for text in ("original_description(location, name)",
                     "if location and not configured[location]",
                     "razi-enable-expedition-briefings",
                     'for _, kind in ipairs({"planet", "space-location"})'):
            self.assertIn(text,source)
        self.assertNotIn("data:extend",source)
        rows=re.findall(r'^  (?:calidus|solaris|nyxaris|vibrant|vespera|beetlejuice|umbra|deep_space) = \{([^\n]+)\}',source,re.M)
        mapped=set(re.findall(r'"([^"]+)"',"\n".join(rows)))
        self.assertTrue(mapped)
        for language in ("en","ru"):
            localized=section(read(f"locale/{language}/names.cfg"),"razi-location-briefing")
            self.assertTrue(mapped.issubset(localized),mapped-set(localized))
        self.assertIn('"sol", "razi-deep-space-edge"',source)

    def test_route_notes_are_native_tooltip_only(self):
        notes=read("prototypes/system/route_dossiers.lua")
        intel=read("prototypes/system/route_intel.lua")
        en=section(read("locale/en/routes.cfg"),"razi-route-intel")
        ru=section(read("locale/ru/routes.cfg"),"razi-route-intel")
        ids=re.findall(r'\{"[^"]+","[^"]+","([a-z0-9-]+)"\}',notes)
        self.assertGreaterEqual(len(ids),55)
        self.assertEqual(len(ids),len(set(ids)))
        self.assertEqual(set(en),set(ru))
        for key in ids:
            self.assertIn("dispatch-"+key,en)
            self.assertIn("dispatch-"+key,ru)
        self.assertIn('dossiers.note_for(route)',intel)
        self.assertIn('field("dispatch",localise("dispatch-"..dossier),231)',intel)
        self.assertIn("custom_tooltip_fields",intel)
        self.assertNotIn("route.localised_description=",intel)
        self.assertNotIn("data:extend",notes)
        self.assertNotIn("data:extend",intel)
        self.assertNotIn("script.on_tick",intel)
        self.assertNotIn("Convergence",read("locale/en/routes.cfg"))

if __name__=="__main__":
    unittest.main()
