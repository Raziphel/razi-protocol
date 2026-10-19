"""Regression: native map stars, journal accents and translated briefings agree."""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PALETTE = {
    "calidus": "#D1B17A",
    "solaris": "#F5A16D",
    "nyxaris": "#80B4FA",
    "vibrant": "#B59AFF",
    "vespera": "#E3D8B9",
    "beetlejuice": "#82D68D",
    "umbra": "#DF9671",
    "deep-space": "#91A9E4",
}

def read(path):
    return (ROOT / path).read_text(encoding="utf-8")

def triples(text):
    return tuple(float(n) for n in re.findall("[0-9]+(?:[.][0-9]+)?", text))

class StarmapIdentityTests(unittest.TestCase):
    def test_system_color_matches_english_and_russian_briefings(self):
        for language in ("en", "ru"):
            names = read(f"locale/{language}/names.cfg")
            routes = read(f"locale/{language}/routes.cfg")
            for system, hex_code in PALETTE.items():
                with self.subTest(locale=language, system=system):
                    self.assertIn(f"{system}=[color={hex_code}]",names)
                    self.assertIn(f"system-{system}=[color={hex_code}]",routes)
            self.assertIn("[razi-location-briefing]",names)

    def test_chapter_accents_resemble_real_system_halos(self):
        themes = read("scripts/razi_journal_themes.lua").splitlines()
        background = read("prototypes/system/starmap_background.lua").splitlines()
        for system in ("solaris","nyxaris","vibrant","vespera","beetlejuice","umbra"):
            name = system + "={primary="
            theme = next((line for line in themes if line.strip().startswith(name)),None)
            glow = next((line for line in background
                         if 'name="' + system + '",art="glow-' + system + '.png"' in line),None)
            self.assertIsNotNone(theme,system)
            self.assertIsNotNone(glow,system)
            if theme and glow:
                main = triples(theme.split("primary={",1)[1].split("}",1)[0])
                halo = triples(glow.split("tint={",1)[1].split("}",1)[0])
                self.assertEqual(len(main),3)
                self.assertEqual(len(halo),3)
                for a,b in zip(main,halo):
                    self.assertLess(abs(a-b),.39,system)

    def test_readable_routes_do_not_duplicate_native_paths_or_change_progression(self):
        intel = read("prototypes/system/route_intel.lua")
        sky = read("prototypes/system/starmap_background.lua")
        self.assertIn('quality_levels.route_range(route',intel)
        self.assertIn('level_text,"[/color]"},218)',intel)
        self.assertLess(intel.index('field("danger",'),intel.index('field("route",'))
        self.assertIn('route.custom_tooltip_fields=fields',intel)
        self.assertNotIn('route.localised_description=',intel)
        self.assertIn('mods["Better_Starmap_Background"]',sky)
        self.assertIn('size={1024,1024},scale=4',sky)

if __name__=="__main__":
    unittest.main()
