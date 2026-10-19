# Razi Protocol: early settings companion

Factorio sorts mod settings by mod load order (primarily dependency depth),
not by the visible title or individual setting order keys. This optional
lightweight companion has a minimal dependency chain and the internal ID
`00-razi-protocol-settings`, giving Razi's startup settings a chance to
appear near the beginning of **Settings → Mod settings → Startup**. The exact
placement is controlled by Factorio and must be checked in-game.

## What it owns

- **Startup only:** All of Razi Protocol's current startup settings, unchanged.
- **NOT runtime:** The main `razi-protocol` mod retains map-wide and
  per-player settings so that runtime writes and ownership keep working.
- **No duplicated definitions:** The companion imports Razi Protocol's
  current setting prototypes during the settings stage, avoiding stale
  mirrored settings and removing manual translation synchronization.
- **Optional:** If absent, Razi Protocol defines ALL its settings itself.

## Install

Use the `00-razi-protocol-settings_1.1.0.zip` archive (build it with
`python3 tools/build_settings_companion.py` from the repo root, or use a
release archive containing version 1.1.0). Place the ZIP unextracted in
Factorio's `mods` folder, enable it, and restart the game. Do not install
or reuse the outdated 1.0.0 companion ZIP.

The main mod's optional dependency specifies version 1.1.0 or newer.
This helper does not rename Razi Protocol or touch world/progression content.
Uninstall it at any time to return startup settings to Razi Protocol's
ordinary section; the setting IDs and user choices are unchanged.

## Maintenance

The root `settings.lua` is the single source of truth. Never add a
hard-coded setting mirror to this companion. Run the builder only when
publishing a new helper archive. It packages four tiny files:
`info.json`, `settings.lua`, and the two section-title locales.
Razi's main locales provide all individual settings names/descriptions.
