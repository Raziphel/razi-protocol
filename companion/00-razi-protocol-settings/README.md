# Razi Protocol: First Settings companion

This is an optional, lightweight Factorio 2.1 mod with internal name `00-razi-protocol-settings`.
It intentionally has only the base-game dependency so it loads *before* Razi Protocol's required planets. The native settings GUI groups settings by the mod that registered them, so this companion can bring the entire Protocol settings section near the beginning of the list.

## Install

1. Download [00-razi-protocol-settings_1.0.0.zip](../dist/00-razi-protocol-settings_1.0.0.zip) from `companion/dist/` (use GitHub's **Download raw file** action).
2. Copy the ZIP **without extracting it** into Factorio's `mods` directory, alongside Razi Protocol.
3. Restart Factorio and open **Settings → Mod settings → Startup**.

Razi Protocol still works **without** this companion: its original `settings.lua` registers the settings when the companion is absent. When both are present, Razi Protocol skips its copies and the companion registers *the same* settings IDs, types and defaults once. This avoids duplicate prototypes and keeps existing setting values identified by their original keys.

The companion does not change Razi Protocol's internal mod name, planets, dependencies, technologies or gameplay. The group is displayed as **Razi Protocol**. Its position is based on Factorio's mod ordering; we cannot guarantee it comes before every installed mod without checking the actual game UI.

## Development

The root `settings.lua` is the source of truth. Run `python3 tools/build_settings_companion.py` from repository root after changing the Protocol's settings or translations. Commit the regenerated companion and ZIP **together** with changes to root settings. Do not manually edit generated copies. Keep the companion's version and ZIP name in sync if making a separate released revision.

**Caveat:** Factorio restricts runtime *programmatic writes* to settings owned by that mod. Existing Razi Protocol code should continue reading these settings by ID; if a future Razi feature programmatically changes them, that feature will require an ownership-aware design. GUI changes remain supported.
