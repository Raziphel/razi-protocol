"""Guard the native Mod Settings difficulty-reference tooltips against drift.

Run from the repository root: python3 tests/test_difficulty_setting_tooltips.py
Uses only the standard library; does not require a running Factorio client.
"""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
preset_source = (root / "scripts" / "razi_difficulty_presets.lua").read_text()
locale_source = (root / "locale" / "en" / "settings.cfg").read_text()
modes = ("easy", "normal", "hard", "nightmare")
managed = re.findall(
    r'"(razi-[^"]+)"',
    preset_source.split("M.managed={", 1)[1].split("M.presets={", 1)[0],
)
definitions = preset_source.split("M.presets={", 1)[1].split("\nlocal legacy=", 1)[0]
values = {}
for i, mode in enumerate(modes):
    fragment = definitions.split("\n " + mode + "={", 1)[1]
    if i + 1 < len(modes):
        fragment = fragment.split("\n " + modes[i + 1] + "={", 1)[0]
    values[mode] = dict(
        (key, raw.strip('"')) for key, raw in re.findall(
            r'\["(razi-[^"]+)"\]\s*=\s*("[^"]*"|true|false)',
            fragment,
        )
    )
all_descriptions = locale_source.split("[mod-setting-description]", 1)[1].split(
    "\n[", 1
)[0]
description_map = dict(
    line.split("=", 1) for line in all_descriptions.splitlines() if "=" in line
)
settings_names = locale_source.split("[string-mod-setting]", 1)[1].split(
    "\n[", 1
)[0]
setting_labels = dict(
    line.split("=", 1) for line in settings_names.splitlines() if "=" in line
)


def label(setting, value):
    if value in ("true", "false"):
        return "On" if value == "true" else "Off"
    name = setting_labels.get(setting + "-" + value)
    return name if name is not None else value.replace("-", " ").capitalize()


for name in managed:
    expected = "Preset values (Easy / Normal / Hard / Nightmare): " + " / ".join(
        label(name, values[mode][name]) for mode in modes
    ) + "."
    actual = description_map.get(name, "")
    assert expected in actual, (
        f"{name}: preset tooltip outdated; expected {expected!r}"
    )
assert len(managed) == len(set(managed)) == 31
assert "does not automatically change the individual setting dropdowns" in description_map[
    "razi-difficulty-preset"
]
print(f"OK: checked all {len(managed)} managed Razi mod-setting tooltips.")
