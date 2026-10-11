"""Regression tests for the static Razi-owned asset audit."""

import importlib.util
import shutil
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "audit_assets.py"
SPEC = importlib.util.spec_from_file_location("razi_asset_audit", SCRIPT)
AUDIT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(AUDIT)


class TestAssetAudit(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)

    def tearDown(self):
        self.temp.cleanup()

    def test_png_header_reader_checks_dimensions_and_alpha(self):
        source = Path(__file__).resolve().parents[1] / "graphics/icons/routes/planetary-route.png"
        target = self.root / "route.png"
        shutil.copyfile(source, target)
        self.assertEqual(AUDIT.png_info(target), (64, 64, True))

    def test_invalid_png_is_rejected(self):
        target = self.root / "broken.png"
        target.write_bytes(b"not a png")
        with self.assertRaises(ValueError):
            AUDIT.png_info(target)

    def test_missing_reference_has_precise_source_line(self):
        source = self.root / "example.lua"
        source.write_text(
            "-- first line\nicon = \"__razi-protocol__/graphics/missing.png\"\n",
            encoding="utf-8")
        references = AUDIT.discover_references(self.root)
        self.assertEqual(len(references), 1)
        self.assertEqual(references[0].source, Path("example.lua"))
        self.assertEqual(references[0].line, 2)

    def test_repository_asset_contract(self):
        root = Path(__file__).resolve().parents[1]
        self.assertEqual(AUDIT.audit_repository(root), [])


if __name__ == "__main__":
    unittest.main()
