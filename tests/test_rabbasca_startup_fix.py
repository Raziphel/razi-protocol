"""Offline tests of the Rabbasca early-loading ZIP repair helper."""
import importlib.util
import json
import tempfile
import unittest
import zipfile
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "tools/fix_rabbasca_startup.py"
spec = importlib.util.spec_from_file_location("rabbasca_fix", SCRIPT)
fixer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(fixer)


class RabbascaRepairTests(unittest.TestCase):
    def test_safe_guard_and_repeated_application(self):
        first, changed = fixer.patch("local test = 1\n" + fixer.OLD + "\n")
        self.assertTrue(changed)
        self.assertIn("rabbasca_lava_water.image_textures[1]", first)
        self.assertIn("rabbasca_lava_water.textures[2]", first)
        self.assertIn("rabbasca_lava_image.filename", first)
        self.assertFalse(fixer.patch(first)[1])

    def test_repair_previously_guarded_builds(self):
        fixed, changed = fixer.patch(fixer.LEGACY + "\n")
        self.assertTrue(changed)
        self.assertIn("rabbasca_lava_water.image_textures[1]", fixed)
        self.assertNotIn("if lava_effect.water and type(", fixed)
        self.assertFalse(fixer.patch(fixed)[1])

    def test_crlf_and_original_recolor_path(self):
        fixed, changed = fixer.patch(fixer.OLD + "\r\n")
        self.assertTrue(changed)
        self.assertIn("\r\n", fixed)
        self.assertNotIn("\n", fixed.replace("\r\n", ""))
        self.assertIn('__rabbasca-assets__/graphics/recolor/textures/lava.png', fixed)

    def test_unknown_source_not_modified(self):
        with self.assertRaisesRegex(ValueError, "Unknown Rabbasca"):
            fixer.patch("local some_completely_different_tile_effect = true")

    def test_zip_repair_preserves_assets_and_backup(self):
        with tempfile.TemporaryDirectory() as d:
            zip_path = Path(d) / "planet-rabbasca_0.22.4.zip"
            root = "planet-rabbasca_0.22.4/"
            with zipfile.ZipFile(zip_path, "w") as z:
                z.writestr(root + "info.json", json.dumps(
                    {"name": "planet-rabbasca", "version": "0.22.4"}))
                z.writestr(root + "prototypes/tiles.lua", fixer.OLD + "\n")
                z.writestr(root + "graphics/keep.png", b"PNG-not-modified")
            original = zip_path.read_bytes()
            changed, backup = fixer.fix(zip_path)
            self.assertTrue(changed)
            self.assertEqual(backup.read_bytes(), original)
            with zipfile.ZipFile(zip_path) as z:
                self.assertIsNone(z.testzip())
                self.assertEqual(z.read(root + "graphics/keep.png"), b"PNG-not-modified")
                self.assertIn(fixer.MARK, z.read(root + "prototypes/tiles.lua").decode())
            self.assertFalse(fixer.fix(zip_path)[0])


if __name__ == "__main__":
    unittest.main()
