# Code health and repository cleanup

**Reviewed:** 12 October 2026 (Razi Protocol 2.1.7)

## Audit scope

Checked the GitHub repository tree (145 files/directory entries before cleanup), Factorio entry points, runtime Chronicle modules, route layout, compatibility directories, localization structure, asset references, changelog and manual workflow triggers.

## Changes made

- Consolidated five Chronicle Lua modules under `scripts/chronicle/`, with one runtime entry point.
- Removed `prototypes/system/routes.lua`, an unused file containing only commented-out legacy route experiments.
- Removed `graphics/orbits/` sprite files. The current data-stage source no longer references them, and the pack relies on Factorio and PlanetsLib orbit rendering. The graphics were retained in Git history.
- Removed empty `.codex` and desktop-specific `.directory` metadata.
- Added a read-only, standard-library-only Python maintenance audit and linked documentation from the README.
- Preserved existing system routes, science packs, enemy routing, optional compatibility modules, lore and storage keys.

## Important design decisions

Many compatibility files look repetitive because they target **different mods or different data-stage timing**. Do not merge/remove them without tests for their exact optional-mod combinations.

`prototypes/compat/progression_polish.lua` and `prototypes/compat/prototype_sanity.lua` are large but contain many interdependent third-party fixes; this pass did **not** perform risky logic rewrites.

The old orbit images were not loaded by any of the mod's current Lua files. If an external mod refers directly to the old file paths, it would require an update; no external consumers were identified in this audit.

## Remaining manual checks

- Start the full intended Factorio 2.1 + K2SO stack. No in-engine mod-load test was available in the linked GitHub tooling.
- Validate all seven Chronicle tabs, factorio GUI style names and platform events with actual game runtime.
- Test fresh and pre-existing saves, multiplayer forces, optional Dea Dia/Pelagos/Nexus and first platform completion.
- Verify starmap connections, progression feasibility and third-party lab/card recipes in a playable modpack.
- Review very large compatibility helpers before attempting internal modularization.

These are **not** claimed as passed. The offline audit checks structure, file references and metadata, not in-game physics or modpack compatibility.
