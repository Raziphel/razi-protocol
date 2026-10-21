# Effective foreign mod settings by Razi difficulty (native Lua only)

This feature changes the **effective value read by later source mod prototype
passes** for selected **real, verified foreign Mod Settings IDs**. It does not
modify or persist saved third-party setting values in the main menu.

After all `data.lua` files, Factorio runs `data-updates.lua` for every mod
and then every `data-final-fixes.lua`. Razi Protocol's `data.lua` runs
after its required dependencies' `data.lua`, but BEFORE their
`data-updates.lua` files. The bridge temporarily assigns the chosen
difficulty's values to existing entries in the *shared prototype-stage*
`settings.startup` Lua table. The original values are restored at the end
of Razi's `data-final-fixes.lua`, avoiding permanent changes to the menu
or mod-settings.dat.

**This is not a universal solution.** A source mod that already consumed
a setting in its earlier `data.lua` does NOT automatically recalculate its
existing prototypes. Such settings are deliberately excluded unless a
verified later consumer also exists. Likewise, the source mod's runtime
scripts can still see its saved setting value rather than the effective
prototype-stage selection.

## Curated upstream setting IDs

| Owner | Real numeric setting | Easy | Normal | Hard | Nightmare | Consumer |
|---|---|---:|---:|---:|---:|---|
| Muluna | `space-science-pack-output` (science output count) | 4 | 2 | 1 | 1 | `data-updates.lua` |
| Muluna | `muluna-interstellar-science-pack-packs-required` (research requirement count) | 1 | 2 | 3 | 4 | `prototypes/mod-data/interstellar-science-pack.lua` called in `data-updates.lua` |
| Muluna | `muluna-interstellar-science-pack-dynamic-packs-required-percentage-required` (dynamic requirement %) | 25% | 50% | 65% | 85% | `prototypes/mod-data/interstellar-science-pack.lua` called in `data-updates.lua` |
| Rubia | `rubia-tech-cost-multiplier` (research multiplier) | 1× | 1× | 2× | 3× | `prototypes/technology-updates.lua` called in `data-updates.lua` |

**Only numeric costs, requirements, percentages and output quantities are
controlled.** Razi does **not** alter K2SO's `kr-revert-thruster-fuel-changes`
or any binary recipe-choice, technology-unlock, progression, cosmetic, or
feature switch. All four named modes use numeric scaling; Custom defers
entirely to the source mod's saved values.

Both Muluna interstellar requirement modes are supported: its existing
settings checkbox chooses between a fixed number and a percentage of installed
planetary science packs. Razi controls the relevant numeric parameter in
both modes without changing that checkbox.

The bridge modifies **only existing, type-matching settings** when the
owning mod is enabled. No attempt is made to inject a nonexistent setting
or rewrite prototype definitions. The central Razi difficulty choice
determines this entire table, even if the other mod setting has been
manually changed. Set Razi difficulty to **Custom** to stop this effect.

References:
- Muluna: https://github.com/nicholasgower/planet-muluna
- Rubia: https://github.com/LoupAndSnoop/rubia
- Factorio stages: https://lua-api.factorio.com/latest/auxiliary/data-lifecycle.html

## Verification and limits

1. Restart Factorio after changing difficulty.
2. Verify Muluna space-science output and interstellar science requirements (fixed and dynamic percentage)
   follow the selected quantities, rather than recipe or unlock toggles.
3. Verify Rubia research-trigger costs use the selected multiplier in the
   source's `data-updates.lua` stage. Rubia also consumes this setting in
   its earlier `data.lua`, which is outside this bridge's reach.
4. Check K2SO thruster fuel recipes, Muluna alternate battery/wood-gas
   options, and other boolean settings are **never** modified.
5. Confirm Custom leaves all source settings unchanged and the previous
   numeric values are restored after the prototype-loading process.
6. Load the actual modpack in Factorio 2.1. A mock Lua test alone cannot
   prove the engine permits overwriting the data-stage settings view.

This is a deliberately small verified numeric-only integration. Additional
multiplier-type options will be added only after identifying a real source
setting and a reachable source consumer. No external tools are needed.
