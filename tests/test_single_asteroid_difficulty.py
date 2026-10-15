"""Ensure Razi has one visible 1-10 asteroid difficulty, not two scores."""
import re
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]


def read(path):
    return (ROOT/path).read_text(encoding="utf-8")


class UnifiedAsteroidDifficultyTests(unittest.TestCase):
    def test_single_colored_danger_rating(self):
        tooltip=read("prototypes/system/route_intel.lua")
        self.assertEqual(tooltip.count('field("danger",'),1)
        self.assertIn('quality_levels.route_range(route',tooltip)
        self.assertIn('quality_levels.route_color_richtext(hi)',tooltip)
        self.assertIn('localise("quality-stage",tostring(hi))',tooltip)
        self.assertIn('localise("quality-stages",tostring(lo),tostring(hi))',tooltip)
        for retired in (
            'report.tier','field("quality-hazard"', 'field("alert"',
            'field("quality-warning"', 'field("distance"',
            'localise("tier-"', 'localise("alert-"',
        ):
            self.assertNotIn(retired,tooltip)

    def test_largest_asteroid_and_chunks_are_facts_not_ratings(self):
        source=read("prototypes/system/route_hazards.lua")
        self.assertIn('function M.inspect(route)',source)
        self.assertIn('largest=largest',source)
        self.assertIn('chunks=chunk_count',source)
        self.assertNotIn("local tier=",source)
        self.assertNotIn('M.colors=',source)
        self.assertNotIn('function M.color(',source)
        route=read("prototypes/system/route_intel.lua")
        self.assertIn('localise("size-"..report.largest)',route)
        self.assertIn('localise("chunks-present",tostring(report.chunks))',route)

    def test_no_duplicate_warnings_or_distance_values(self):
        tooltip=read("prototypes/system/route_intel.lua")
        self.assertEqual(tooltip.count('field("preparation"'),1)
        self.assertIn('hi>=10 and "prepare-legendary"',tooltip)
        self.assertNotIn('field("distance",',tooltip)
        locale=read("locale/en/routes.cfg")
        self.assertIn('danger=[font=default-bold]Asteroid difficulty[/font]',locale)
        self.assertIn('quality-stage=Level __1__ / 10',locale)
        self.assertIn('prepare-legendary=',locale)
        self.assertNotIn('tier-5=',locale)
        self.assertNotIn('alert-5=',locale)
        self.assertNotIn('quality-warning=',locale)

    def test_one_color_source_across_starmap_and_tooltip(self):
        overlay=read("prototypes/system/route_highlights.lua")
        ribbons=read("prototypes/system/route_ribbons.lua")
        self.assertIn('quality.route_color(M.route_color_level(route))',overlay)
        self.assertIn('ladder.route_color(grade)',ribbons)
        self.assertNotIn('owner.threat_tier',ribbons)
        self.assertNotIn('danger_colors',overlay)
        self.assertNotIn('marker_for_connection',overlay)
        self.assertIn('M.route_colors={',read("scripts/razi_asteroid_difficulty.lua"))


if __name__=="__main__":
    unittest.main()
