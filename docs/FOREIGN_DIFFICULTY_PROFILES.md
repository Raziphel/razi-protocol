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
| Muluna | `space-science-pack-output` (science output count) | 4 | Unchanged | 1 | 1 | `data-updates.lua` |
| Muluna | `muluna-interstellar-science-pack-packs-required` (research requirement count) | 1 | Unchanged | 3 | 4 | `prototypes/mod-data/interstellar-science-pack.lua` called in `data-updates.lua` |
| Muluna | `muluna-interstellar-science-pack-dynamic-packs-required-percentage-required` (dynamic requirement %) | 25% | Unchanged | 65% | 85% | `prototypes/mod-data/interstellar-science-pack.lua` called in `data-updates.lua` |
| Rubia | `rubia-tech-cost-multiplier` (research multiplier) | 1× | Unchanged | 2× | 3× | `prototypes/technology-updates.lua` called in `data-updates.lua` |

**Only numeric costs, requirements, percentages and output quantities are
controlled.** Razi does **not** alter K2SO's `kr-revert-thruster-fuel-changes`
or any binary recipe-choice, technology-unlock, progression, cosmetic, or
feature switch. Only Easy, Hard and Nightmare apply numeric changes. **Normal and Custom
are strictly hands-off**, even if the player customized other mods' settings.

Both Muluna interstellar requirement modes are supported: its existing
settings checkbox chooses between a fixed number and a percentage of installed
planetary science packs. Razi controls the relevant numeric parameter in
both modes without changing that checkbox.

The bridge modifies **only existing, type-matching settings** when the
owning mod is enabled. No attempt is made to inject a nonexistent setting
or rewrite prototype definitions. Easy, Hard and Nightmare can override numeric source controls. **Normal and
Custom make zero source-setting writes or numeric prototype corrections.**

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
5. Confirm Normal and Custom leave all source settings unchanged and the previous
   numeric values are restored after the prototype-loading process.
6. Load the actual modpack in Factorio 2.1. A mock Lua test alone cannot
   prove the engine permits overwriting the data-stage settings view.

This is a deliberately small verified numeric-only integration. Additional
multiplier-type options will be added only after identifying a real source
setting and a reachable source consumer. No external tools are needed.

## Numeric source settings consumed earlier in data.lua

These genuine settings are handled by a separate, source-specific **late
prototype reconciliation**, because their owning mods read them before
Razi Protocol's data.lua is reached. This targets the same setting-owned
recipe/research quantities, **not** generic factories or technology trees.

| Mod | Source numeric setting | Easy | Normal | Hard | Nightmare | Actual effect |
|---|---|---:|---:|---:|---:|---|
| Muluna | `space-science-pack-energy` | 5 | Unchanged | 9 | 12 | `space-science-pack` craft time, relative to Muluna's own saved setting |
| Muluna | `muluna-balance-exploration-science-data-cost` | 6 | Unchanged | 14 | 20 | `muluna-astronomical-data` fluid amount for native interstellar science recipe |
| Cerys | `cerys-undo-marathon-multiplier` | 1.5× | Unchanged | 0.8× | 0.6× | Relative scaling of the 16 research counts/triggers created using Cerys's `correct(n)` helper |

Cerys source reads the saved value in `prototypes/technology.lua` and
constructs research counts with `ceil(base / saved)`. Razi takes the final
source values and applies `saved / target` to only the 16 named Cerys
technologies confirmed in that file. This preserves upstream compatibility
modifications multiplicatively, subject to ordinary integer rounding.
Muluna is similarly adjusted using `target / saved` on two specific
recipe properties.

**Scope constraints:** No source settings in the player's Mod Settings
are rewritten; Normal and Custom do not change anything. These passes require both
the source mod and its named recipe or technology to be present. They
preserve ingredients unrelated to the named source numeric option.
Scientific progression or other setting-dependent Lua paths not represented
by these exact prototype fields remain source-owned. No other mod's
runtime-global settings can be rewritten by Razi.

The local Lua tests use mocked Factorio tables and cover changing difficulty
and source values; full in-game loading is still needed to validate the
actual source prototype layouts and interactions with all modpack compat mods.

## Other required-mod settings assessed

The required-mod audit distinguishes numerical gameplay controls from
settings that merely look adjustable. The following real source settings
were checked against public settings definitions. This list is *not* a
claim that every released build has the same options; installed versions
must be verified during in-game compatibility testing.

| Required mod | Candidate native setting | Disposition |
| --- | --- | --- |
| **Castra Prime** | `castra-prime-research-rate-multiplier` | Real runtime-global rate modifier; **not** safe to rewrite from RP's prototype stage. Requires source-owner runtime support or an explicitly verified equivalent API |
| **Cerys** | `cerys-solar-wind-spawn-rate-percentage`, `cerys-plutonium-generation-rate-multiplier` | Real runtime-global numerical gameplay settings; source scripts read live values, so not covered by prototype reconciliation |
| **Muluna** | `platform-power-consumption` | Startup numeric, but its source generates nav-beacon energy fields, mod-data, and matching descriptions in different phases. All parts must be reconciled together before adding |
| **Muluna** | `muluna-balance-fulgoran-cargo-drop-item-multiplier` | Numeric startup setting used by a runtime cargo-drop script, not safely overwritten by the prototype-stage bridge |
| **Tenebris Prime** | `tenebris-small-centipede-length` and related sizes | Actual numeric settings exist, but the inspected enemy creation calls consuming them are commented out. No verified active gameplay effect to scale |
| **Maraxsis** | `maraxsis-water-opacity` | Numeric but graphical only, not a difficulty control |
| **Planetaris Tellus** | `tellus-bugs-particle-amount`, `tellus-bugs-particle-speed` | Cosmetic particle effects, deliberately excluded |
| **Planetaris Hyarion / Arig** | Dust/lights/sand particle-speed settings | Cosmetic environmental particles, excluded |
| **K2SO Spaced Out** | `kr-revert-thruster-fuel-changes` | Binary recipe rules, explicitly excluded at user request |
| **Rubia** | `rubia-tech-cost-multiplier` | Already integrated through the source's later technology-updates pass; earlier data.lua consumers are outside the bridge |

The guiding rule is **quantitative source controls only**, not arbitrary
checkboxes or a generic buff/nerf applied to all entities. Future
extensions must identify a real source setting, its unit/range, whether it
runs during data.lua/data-updates/control, and the exact outcome being
adjusted. A setting is not marked integrated until the implementation is
present, and only a full Factorio load can verify it in the complete modpack.
