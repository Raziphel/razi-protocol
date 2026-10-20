"""Regression coverage for the external, real Factorio mod-setting synchronizer.

Run: python3 -m unittest discover -s tests -p 'test_razi_settings_sync.py'
Only tempfile fixtures are touched; never the user's actual Factorio install.
"""
import importlib.util
import json
import struct
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]
MODULE = ROOT / "tools" / "razi_settings_sync.py"
SPEC = importlib.util.spec_from_file_location("razi_settings_sync", MODULE)
assert SPEC and SPEC.loader
mod = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)
N = mod.Node


def make_file(mods: Path, difficulty="nightmare"):
    config = json.loads((ROOT / "tools" / "razi_difficulty_setting_manifest.json").read_text())
    owners = sorted({row["mod"] for row in config["entries"]})
    (mods / "mod-list.json").write_text(json.dumps({"mods": [
        {"name": "razi-protocol", "enabled": True},
        *({"name": owner, "enabled": True} for owner in owners)
    ]}), encoding="utf-8")
    for owner in owners:
        names = [row["name"] for row in config["entries"] if row["mod"] == owner]
        with ZipFile(mods / (owner + "_1.0.0.zip"), "w") as archive:
            archive.writestr(owner + "_1.0.0/settings.lua",
                             "-- fixture only\n" + "\n".join('name="' + name + '"' for name in names))
    startup = N(5, 0, {
        "razi-difficulty-preset": N(5, 0, {"value": N(3, 0, difficulty)}),
        "unknown-mod-setting": N(5, 0, {"value": N(1, 0, True)}),
        "space-science-pack-output": N(5, 0, {"value": N(2, 0, 9.0)}),
    })
    root = N(5, 0, {
        "startup": startup,
        "runtime-global": N(5, 0, {"unrelated": N(5, 0, {"value": N(3, 0, "stay")})}),
        "runtime-per-user": N(5, 0, {})
    })
    header = struct.pack("<4H", 2, 1, 22, 0) + b"\x00"
    file = mods / "mod-settings.dat"
    file.write_bytes(mod.encode(header, root))
    return file, config


class RealModSettingsTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.mods = Path(self.temp.name)
        self.file, self.manifest = make_file(self.mods)

    def read(self):
        return mod.decode(self.file.read_bytes())[1]

    def run_tool(self, *args):
        return subprocess.run(
            [sys.executable, str(MODULE), "--mods-dir", str(self.mods), *args],
            check=False, text=True, capture_output=True,
        )

    def test_byte_exact_roundtrip_with_unchanged_tree(self):
        raw = self.file.read_bytes()
        header, node = mod.decode(raw)
        self.assertEqual(mod.encode(header, node), raw)
        self.assertEqual(mod.setting_value(node.value["startup"],
                                           "razi-difficulty-preset").value, "nightmare")

    def test_preview_never_writes_and_apply_overrides_real_values(self):
        before = self.file.read_bytes()
        preview = self.run_tool()
        self.assertEqual(preview.returncode, 0, preview.stderr)
        self.assertIn("=>", preview.stdout)
        self.assertEqual(self.file.read_bytes(), before)
        self.assertEqual(list(self.mods.glob("*.razi-backup-*")), [])
        apply = self.run_tool("--apply")
        self.assertEqual(apply.returncode, 0, apply.stderr)
        root = self.read()
        startup = root.value["startup"]
        self.assertEqual(mod.setting_value(startup, "space-science-pack-output").value, 1.0)
        self.assertEqual(mod.setting_value(startup, "unknown-mod-setting").value, True)
        self.assertEqual(mod.setting_value(startup, "tenebris-giant-centipede-length").value,
                         84.0)
        self.assertEqual(mod.setting_value(startup, "rubia-tech-cost-multiplier").value, 3.0)
        self.assertEqual(mod.setting_value(startup, "kr-revert-thruster-fuel-changes").value,
                         False)
        self.assertEqual(mod.setting_value(root.value["runtime-global"], "unrelated").value,
                         "stay")
        self.assertIsNone(mod.setting_value(root.value["runtime-global"], "rubia-difficulty-setting"))
        self.assertEqual(len(list(self.mods.glob("*.razi-backup-*"))), 1)
        repeat = self.run_tool("--apply")
        self.assertEqual(repeat.returncode, 0, repeat.stderr)
        self.assertIn("Changes: 0", repeat.stdout)
        self.assertEqual(len(list(self.mods.glob("*.razi-backup-*"))), 1)

    def test_optional_runtime_changes_only_with_explicit_opt_in(self):
        result = self.run_tool("--apply", "--include-runtime-global")
        self.assertEqual(result.returncode, 0, result.stderr)
        value = mod.setting_value(self.read().value["runtime-global"],
                                  "rubia-difficulty-setting")
        self.assertEqual(value.value, "very-very-hard")
        self.assertEqual(mod.setting_value(self.read().value["runtime-global"],
                         "cerys-solar-wind-spawn-rate-percentage").value, 175.0)

    def test_custom_no_cross_mod_writes(self):
        root = self.read()
        mod.setting_value(root.value["startup"], "razi-difficulty-preset").value = "custom"
        self.file.write_bytes(mod.encode(struct.pack("<4H", 2, 1, 22, 0) + b"\x00", root))
        original = self.file.read_bytes()
        result = self.run_tool("--apply")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.file.read_bytes(), original)
        self.assertEqual(list(self.mods.glob("*.razi-backup-*")), [])

    def test_unknown_source_setting_is_not_created(self):
        archive = self.mods / "tenebris-prime_1.0.0.zip"
        archive.unlink()
        result = self.run_tool("--apply")
        self.assertEqual(result.returncode, 0, result.stderr)
        root = self.read()
        self.assertIsNone(mod.setting_value(root.value["startup"],
                                          "tenebris-small-centipede-length"))

    def test_rejects_bad_format_without_touching_original(self):
        self.file.write_bytes(b"not a mod-settings.dat")
        initial = self.file.read_bytes()
        result = self.run_tool("--apply")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(initial, self.file.read_bytes())
        self.assertEqual(list(self.mods.glob("*.razi-backup-*")), [])


if __name__ == "__main__":
    unittest.main()
