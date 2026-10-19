"""Startup log parser regression fixtures for documented stage timings."""
import unittest
from tools.factorio_startup_report import parse_log, compare

def log(markers):
    return "\n".join(f"{moment:.3f} 2026-10-19 {phrase}"
                     for moment, phrase in markers)

PHASES=[
    "Loading mod settings",
    "Loading mod prototypes",
    "Building prototypes",
    "Loading sprites",
    "Loading sounds",
    "Factorio initialised",
]

class StartupReportTests(unittest.TestCase):
    def test_complete_log_and_comparison(self):
        before=parse_log(log(zip([0, 10, 35, 60, 90, 100], PHASES)))
        after=parse_log(log(zip([0, 8, 26, 46, 77, 90], PHASES)))
        result=compare(before, after)
        self.assertEqual(result["phases"]["mod_settings"]["delta_s"], -2)
        self.assertEqual(result["phases"]["mod_prototypes"]["delta_s"], -7)
        self.assertEqual(result["total"]["delta_s"], -10)
        self.assertEqual(after["observed_startup_window"], 90)

    def test_missing_stage_does_not_invent_duration(self):
        partial=parse_log(log(zip([0, 10, 50],
            [PHASES[0], PHASES[1], PHASES[-1]])))
        self.assertEqual(partial["durations"]["mod_settings"], 10)
        self.assertNotIn("mod_prototypes", partial["durations"])
        self.assertIsNone(compare(partial, partial)["phases"]["sprites"]["delta_s"])

    def test_unordered_markers_do_not_produce_negative_duration(self):
        bad=parse_log(log([(9,PHASES[0]), (5,PHASES[1]),
                          (15,PHASES[2]), (20,PHASES[-1])]))
        self.assertNotIn("mod_settings", bad["durations"])

    def test_english_variants_and_duplicate_markers(self):
        data=parse_log(log([(1,PHASES[0]),(2,PHASES[0]),(3,PHASES[1]),
                            (7,PHASES[2]),(9,PHASES[3]),(12,PHASES[4]),
                            (15,"Factorio initialized")]))
        self.assertEqual(data["durations"]["mod_settings"],2)
        self.assertEqual(data["observed_startup_window"],14)

    def test_empty_log(self):
        data=parse_log("not a timestamp\\nother source")
        self.assertIsNone(data["observed_startup_window"])
        self.assertEqual(len(data["missing"]),6)

if __name__ == "__main__":
    unittest.main()
