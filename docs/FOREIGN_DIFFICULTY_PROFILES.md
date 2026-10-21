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

| Owner | Actual setting ID | Easy | Normal | Hard | Nightmare | Source consumer |
|---|---|---:|---:|---:|---:|---|
| Muluna | `space-science-pack-output` | 4 | 2 | 1 | 1 | data-updates.lua |
| Muluna | `muluna-easy-simple-wood-gasification` | true | false | false | false | data-updates.lua |
| Muluna | `muluna-easy-alternative-battery-recipe` | true | false | false | false | prototypes/recipe/vanilla-alternate-recipes.lua via data-updates.lua |
| Muluna | `muluna-easy-vanilla-advanced-thruster-fuel-costs` | true | false | false | false | data-updates.lua |
| Muluna | `muluna-change-quality-science-pack-drain` | true | true | false | false | data-updates.lua |
| Muluna | `muluna-interstellar-science-pack-dynamic-packs-required` | false | false | false | false | prototypes/mod-data/interstellar-science-pack.lua used in data-updates.lua |
| Muluna | `muluna-interstellar-science-pack-packs-required` | 1 | 2 | 3 | 4 | prototypes/mod-data/interstellar-science-pack.lua used in data-updates.lua |
| Rubia | `rubia-tech-cost-multiplier` | 1 | 1 | 2 | 3 | prototypes/technology-updates.lua via data-updates.lua |
| K2SO | `kr-revert-thruster-fuel-changes` | true | false | false | false | prototypes/updates/base/recipes.lua via data-updates.lua |

The bridge modifies **only existing, type-matching settings** when the
owning mod is enabled. No attempt is made to inject a nonexistent setting
or rewrite prototype definitions. The central Razi difficulty choice
determines this entire table, even if the other mod setting has been
manually changed. Set Razi difficulty to **Custom** to stop this effect.

References:
- Muluna: https://github.com/nicholasgower/planet-muluna
- Rubia: https://github.com/LoupAndSnoop/rubia
- Krastorio 2 Spaced Out: https://github.com/Polka37/Krastorio2-Spaced-Out
- Factorio stages: https://lua-api.factorio.com/latest/auxiliary/data-lifecycle.html

## Verification and limits

1. After changing Razi difficulty, restart Factorio before loading a game.
2. Verify source mod data-updates.lua readers see the effective values and
   that the expected *actual source-owned* recipes/technologies changed.
3. Check Muluna science pack yield, battery alternative, wood gasification, advanced thruster fuel, quality science
   drain, and interstellar science prerequisites.
4. Confirm Rubia source research costs and K2SO thruster ingredients change.
   Rubia's data.lua-based special forage scaling is **not** covered.
5. Confirm Custom behaves exactly as foreign saved startup settings specify.
6. Verify the recorded setting values are restored at the end of data stage
   and multiplayer CRC and save/load remain valid.
7. Exercise all 51 hard-required mods in a real Factorio 2.1 startup. Only
   nine settings are currently claimed as covered; other mods need
   corresponding source-phase verification before being added.

No separate executable, settings-file editor or third-party bridge is needed.
Static Lua tests validate the rule table and snapshot/restore mechanics,
but *do not prove* the Factorio engine allows overriding its data-stage
setting view. If it is immutable, the bridge will skip the unsupported write
rather than crash or falsely claim the setting was applied.
