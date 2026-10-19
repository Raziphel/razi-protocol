#!/usr/bin/env python3
"""Package the opt-in early startup-settings companion for Factorio 2.1.

The companion imports live definitions from Razi Protocol at settings stage.
No generated mirror or duplicate translations are needed.
"""
import json
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
NAME = "00-razi-protocol-settings"
SOURCE = ROOT / "companion" / NAME
INFO = json.loads((SOURCE / "info.json").read_text(encoding="utf-8"))
assert INFO["name"] == NAME
assert INFO["factorio_version"] == "2.1"
root_settings = (ROOT / "settings.lua").read_text(encoding="utf-8")
companion_settings = (SOURCE / "settings.lua").read_text(encoding="utf-8")
assert "local definitions = {" in root_settings
assert 'if exporting then return definitions end' in root_settings
assert 'entry.setting_type == "startup"' in companion_settings
assert 'require, "__razi-protocol__/settings"' in companion_settings

version = INFO["version"]
out = ROOT / "companion" / "dist" / f"{NAME}_{version}.zip"
out.parent.mkdir(parents=True, exist_ok=True)
files = (
    "info.json", "settings.lua",
    "locale/en/settings.cfg", "locale/ru/settings.cfg",
)
with zipfile.ZipFile(out, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as zip_file:
    for file in files:
        zip_file.write(SOURCE / file, f"{NAME}_{version}/{file}")
print(f"Built {out.relative_to(ROOT)}")
