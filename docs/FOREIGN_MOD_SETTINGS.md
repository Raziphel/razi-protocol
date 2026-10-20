# Synchronizing actual third-party Mod Settings with Razi difficulty

This is a **real external setting-value editor**, not a prototype multiplier.
It writes Factorio's **mod-settings.dat** file, which holds the settings
shown under Settings > Mod settings, using Razi Protocol's already-saved
`razi-difficulty-preset` as the selection. It supports Easy, Normal, Hard,
Nightmare and explicit Custom (Custom does **not** override other mods).

**Factorio cannot do this automatically from a mod's native settings GUI.**
The settings-definition phase cannot read saved values of the Razi difficulty
selector, and the runtime API prevents mods from writing other mods' settings.
The companion script must run **outside Factorio, after closing it and before
the next launch**. If you change difficulty but do not run the tool, the
source mods' actual saved settings remain as they were.

## Instructions

Install and enable Razi Protocol and your required mods as usual.

1. In Factorio, select your preferred **Razi difficulty** in Settings > Mod
   settings. Save it, then **close Factorio fully**.
2. From the Razi Protocol source checkout, run a **preview** (no file writes):

   ```bash
   python3 tools/razi_settings_sync.py --mods-dir "$HOME/.factorio/mods"
   ```

   On Windows, use `py` instead of `python3` and pass
   `--mods-dir "%APPDATA%\\Factorio\\mods"` from Command Prompt.
   Point to the **actual** mods directory that contains `mod-settings.dat`,
   `mod-list.json` and mod zips; a Steam or portable install may differ.
3. Check every actual source-setting name and old/new value printed. Then
   explicitly authorize the edit with:

   ```bash
   python3 tools/razi_settings_sync.py --mods-dir "$HOME/.factorio/mods" --apply
   ```

4. The script writes a timestamped **mod-settings.dat.razi-backup-...** before
   atomically replacing the settings file. Start Factorio and inspect the
   other mods' individual settings under the *Startup* tab. A full restart is
   required whenever startup values change.

For **new saves only**, you can also synchronize the Map/runtime-global
defaults (Rubia and Cerys), using
`--include-runtime-global` on the preview and apply commands. This does NOT
rewrite current runtime-global settings stored inside an existing save game.
It does NOT change per-player settings.

## Current verified mappings

These IDs come from the owners' actual settings.lua definitions. They are
validated against the installed source mod's `settings.lua` before any write.
Missing mods, absent or renamed settings, and disabled mods are skipped.
The same value written by this tool will replace a player's previous
selection **only for the listed settings**. No other settings change.

| Required mod | Actual setting ID | Easy | Normal | Hard | Nightmare | Type |
| --- | --- | --- | --- | --- | --- | --- |
| Muluna | `space-science-pack-output` | 4 | 2 | 2 | 1 | Startup |
| Muluna | `space-science-pack-energy` | 5 | 7 | 9 | 12 | Startup |
| Muluna | `muluna-balance-exploration-science-data-cost` | 6 | 10 | 14 | 20 | Startup |
| Muluna | `platform-power-consumption` | 70 | 100 | 130 | 160 | Startup |
| Muluna | `muluna-balance-fulgoran-cargo-drop-item-multiplier` | 1.30 | 1.00 | 0.80 | 0.65 | Startup |
| Tenebris Prime | `tenebris-small-centipede-length` | 9 | 12 | 15 | 18 | Startup |
| Tenebris Prime | `tenebris-medium-centipede-length` | 12 | 16 | 20 | 24 | Startup |
| Tenebris Prime | `tenebris-large-centipede-length` | 24 | 32 | 40 | 48 | Startup |
| Tenebris Prime | `tenebris-giant-centipede-length` | 45 | 60 | 72 | 84 | Startup |
| Rubia | `rubia-tech-cost-multiplier` | 1 | 1 | 2 | 3 | Startup |
| Rocket Reusability | `enable-incomplete-rocket-parts-productivity` | On | Off | Off | Off | Startup |
| K2SO | `kr-revert-thruster-fuel-changes` | On | Off | Off | Off | Startup |
| Rubia | `rubia-difficulty-setting` | easy | normal | hard | very-very-hard | New saves (Map) |
| Cerys | `cerys-solar-wind-spawn-rate-percentage` | 65 | 100 | 130 | 175 | New saves (Map) |
| Cerys | `cerys-plutonium-generation-rate-multiplier` | 1.30 | 1.00 | 0.85 | 0.70 | New saves (Map) |

Source links (verify against installed version, which can change):
[Muluna](https://github.com/nicholasgower/planet-muluna/blob/main/settings.lua),
[Tenebris Prime](https://github.com/nicholasgower/tenebris-prime/blob/main/settings.lua),
[Rubia](https://github.com/LoupAndSnoop/rubia/blob/main/settings.lua),
[K2SO](https://github.com/Polka37/Krastorio2-Spaced-Out/blob/main/settings.lua),
[Cerys](https://github.com/danielmartin0/Cerys-Moon-of-Fulgora/blob/main/settings.lua),
[Razi Rocket Reusability](https://github.com/Raziphel/razi-rocket-reusability/blob/main/settings.lua).

### Safety

- **Dry-run by default.** `--apply` is required to save changes.
- **No Lua execution** of installed source mod files. Only looks for the exact
  setting IDs in the installed `settings.lua` file.
- Verifies the enabled mod list and real installed source archive/directory.
- Preserves unknown PropertyTree fields and file version; refuses corrupt
  files and files that do not round-trip exactly.
- Checks stored numeric types and configured value ranges.
- Never edits actual Factorio settings if Custom was selected.
- Refuses to apply while Factorio is detected running. Close it first.
- Creates a timestamped backup, then writes an atomically replaced file.
- `mod-settings.dat` is local. Changes must be applied on every computer
  or dedicated server that needs the same startup settings. For multiplayer,
  the host's server startup configuration remains authoritative.
- Do not add arbitrary settings to the manifest without checking the owning
  mod's permitted values and campaign progression. Some required mods have
  **no settings**, and several expose only visual, accessibility, hidden or
  gameplay-breaking toggles that should never be forced by a difficulty tier.

**This is the first curated verified batch, NOT every setting in all 51 required
mods.** New integrations should be added to
`tools/razi_difficulty_setting_manifest.json` with a source check and
test coverage. It is preferable to skip an unknown setting than invent a
name or overwrite an unrelated user preference.

## Tests

```bash
python3 -m unittest discover -s tests -p 'test_razi_settings_sync.py'
```

This uses temporary mock source mods and binary settings files. It verifies
preview, atomic application, backups, overrides, Custom, missing mods and
no-op behavior. A Factorio 2.1 game load with the user's installed exact mod
versions is still required before calling a synchronized combination proven.
