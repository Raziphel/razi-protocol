"""Keep retired Razi artwork out of shipped mod assets."""
from pathlib import Path
import unittest

from scripts.audit_assets import ACTIVE_STARMAP, RUNTIME_ICON_GROUPS, png_info

ROOT = Path(__file__).resolve().parents[1]
GRAPHICS = ROOT / "graphics"


class GraphicsCleanupTests(unittest.TestCase):
    def test_only_current_starmap_artwork(self):
        actual = {p.name for p in (GRAPHICS / "starmap/razi").glob("*.png")}
        self.assertEqual(actual, ACTIVE_STARMAP)
        self.assertEqual(len(actual), 19)
        self.assertIn("calidus-dyson-stages.png", actual)
        self.assertIn("debris-umbra.png", actual)

    def test_no_fixed_route_guides(self):
        self.assertEqual(list((GRAPHICS / "route-highlights").glob("guide-*.png")), [])
        self.assertFalse((ROOT / "prototypes/system/route_highlight_manifest.lua").exists())
        self.assertTrue((GRAPHICS / "route-highlights/continuous-strokes.png").exists())
        self.assertIn(
            "continuous-strokes.png",
            (ROOT / "prototypes/system/route_highlights.lua").read_text())

    def test_no_obsolete_convergence_placeholder_images(self):
        self.assertFalse(any((GRAPHICS / "convergence").glob("*.png")))
        self.assertEqual(
            len(list((GRAPHICS / "icons/convergence").glob("*.png"))), 5)

    def test_dynamic_icons_survive_cleanup(self):
        for group, names in RUNTIME_ICON_GROUPS.items():
            for name in names:
                path = GRAPHICS / "icons" / group / (name + ".png")
                with self.subTest(name=name):
                    self.assertTrue(path.is_file())
                    self.assertEqual(png_info(path), (64, 64, True))

    def test_active_icon_counts(self):
        self.assertEqual(len(list((GRAPHICS / "icons/navigation").glob("*.png"))), 11)
        self.assertEqual(len(list((GRAPHICS / "icons/routes").glob("*.png"))), 4)


if __name__ == "__main__":
    unittest.main()
