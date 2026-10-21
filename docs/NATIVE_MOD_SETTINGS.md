# Native Lua Mod Settings Integration

Factorio has two incompatible mod settings stages. The settings prototype stage lets mods modify the defaults/definitions of other mods' settings. However, the user's saved difficulty selection is not available until that stage has finished. Therefore settings-updates.lua or settings-final-fixes.lua CANNOT dynamically set other mods' defaults based on the current Razi difficulty.

At runtime, a Lua mod can read the Razi startup difficulty and change its OWN runtime-global Map settings. It cannot write another mod's saved runtime settings or any startup settings. Source mod cooperation is required for real changes shown in another mod's Mod Settings menu.

## Working Lua-only integration

Razi Rocket Reusability 1.1.8+ reads the Razi difficulty in its own runtime/razi-protocol-settings.lua and uses the Factorio LuaSettings API to write FIVE source-owned Map settings on Hard/Nightmare: recovery chance, wreck spawn distance, maximum active wrecks, side arrivals and side-arrival chance. The bridge records previous preferences per save, enforces the prescribed values once per second, and restores each original value on Easy, Normal, Custom or standalone. The legacy 1.1.7 side-arrivals-only snapshot is migrated. It does not write settings belonging to any different mod.

Official engine references:
- https://lua-api.factorio.com/latest/auxiliary/data-lifecycle.html
- https://lua-api.factorio.com/latest/classes/LuaSettings.html

## Extending to required mods

The owner of each source mod must provide an opt-in adapter in its own control.lua that reads settings.startup['razi-difficulty-preset'] and writes only settings.global entries that belong to THAT mod. It should guard missing settings, validate allowed values, avoid per-tick work, preserve Custom choices, and keep multiplayer determinism. No separate executables or file editors are required.

Razi Protocol now also has a separate [prototype-stage, effective foreign startup setting bridge](FOREIGN_DIFFICULTY_PROFILES.md) for nine source options read only in later prototype passes. It restores the saved Lua setting view before startup completes and does not change their actual Mod Settings UI values.

Source-mod startup settings cannot be automatically rewritten according to Razi difficulty by any Factorio mod. If an owner adapts its own data.lua to read the Razi difficulty and change gameplay, that changes EFFECTIVE balance, not the saved setting shown in the GUI. This distinction must be stated accurately.

## Release and tests

Razi Rocket Reusability 1.1.8+ must be published and installed for all five Map-setting updates; 1.1.7 changes only the side-arrivals checkbox and 1.1.6 changes effective behaviour only. After changing difficulty, restart Factorio, load or create a map, wait one second, and inspect the rocket mod's Map checkbox. Test restoring all five manual selections, changes during Hard/Nightmare, old 1.1.7 saves, saved games and multiplayer. The standalone Lua test is tests/protocol-settings.lua in the Rocket Reusability repository.

This project intentionally does NOT ship Python, executables, mod-settings.dat editors or launcher wrappers.
