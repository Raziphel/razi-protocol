# Big Monsters: source-aligned numerical difficulty

Razi Protocol includes Big Monsters as a **recommended** dependency
(`+ Big-Monsters >= 2.2.1`). The public Factorio mod portal lists
2.2.1 as the latest release. A public mirror of Big Monsters 2.1.2 was
used to verify its original setting IDs and source prototype names.
Because the exact 2.2.1 source isn't public in that mirror, this
adapter requires a full installed-game compatibility test.

## Integrated: Big Monsters giant-health multiplier

Big Monsters owns the real startup setting
`bm-big-enemy-hp-multiplier` (native range 0.2–10, default 1).
It creates enormous HP values in its early `data.lua` pass; Razi
reconciles those **already-defined boss prototypes** after all mods
have finished loading, using `target / saved Big-Monsters multiplier`.
The settings menu and other mods' saved values are unchanged.

| Razi difficulty | Effective giant-boss HP multiplier |
| --- | ---: |
| Easy | 0.80× |
| Normal | Unchanged |
| Hard | 1.20× |
| Nightmare | 1.50× |
| Custom | Unchanged |

The only eligible prototypes are the source's explicitly recognized
`biterzilla1*`, `biterzilla2*`, `biterzilla3*`,
`bm-motherbiterzilla*`, `maf-giant-fire-spitter*`,
`maf-giant-acid-spitter*`, `bm-spidertron_*`, the four
Big Monsters worm-boss turrets, and `bm-volcano`. Exact name
matches and a `Big-Monsters` mod presence guard prevent changes
to vanilla biters/spiders, unrelated modded enemies, recipes, or
building/belt speeds. If prototypes are missing in a newer version,
they are simply skipped.

Unlike rewriting a source startup setting, this affects the effective
health of *newly created threats*. Changing difficulty requires a
Factorio restart and reload; it does not instantly heal/damage
already spawned monsters.

## Further settings confirmed for review, not integrated

The source has genuine numerical controls, but most are Map/runtime
settings owned by Big Monsters. Razi is not allowed to overwrite those
saved values, and its control.lua snapshots them into private storage.

| Big Monsters setting | Actual purpose | Stage | Status |
| --- | --- | --- | --- |
| `bm-enemy-damage-multiplier` | Boss and projectile damage | Startup, 0.5–10 | Not integrated: direct attacks, projectiles and area damage must be audited together |
| `bm-big-enemy-hp-variant` | Tier-by-tier giant health variance | Startup, 0.2–4 | Not integrated: nonlinear health curve, risky early-game |
| `bm-worm-enemy-hp-multiplier` | Worm HP option | Startup | Not integrated: source mirror does not show a live consumer |
| `bm-difficulty-level` | Invasion size, waves and boss health | Runtime-global, 1–10 | Cannot write source setting from Razi |
| `bm-event-days` | Interval between events; zero disables | Runtime-global, 0–20 | Cannot rewrite source scheduling without a supported owner API |
| `bm-invasion-chance`, `bm-worms-chance`, `bm-biterzilla-chance`, etc. | Individual disaster probabilities | Runtime-global | Cannot write source settings from Razi |
| `bm-biterzilla-min_evo`, `bm-worms-min_evo`, etc. | Minimum evolution thresholds | Runtime-global | Not changed to prevent early boss surprises |
| `bm-spawn_on_sa_planets` | Enable events on extra Space Age planets | Runtime-global boolean | Not changed: feature toggle, not a multiplier |

Big Monsters exposes a **remote interface** for creating events and
including/excluding planets, not for changing its numeric runtime
difficulty, interval or chance settings. Calling extra events would
not be equivalent to its own event-frequency option, and risks
unfair back-to-back disasters. The current Razi integration does not
do that.

The source already scales challenge with evolution and player count,
so these boss-HP adjustments are deliberately moderate.

## Validation

- Load with **Big Monsters 2.2.1** and without it.
- Inspect the exact source prototype names and max_health at all four
  named modes plus Custom with source multiplier 1 and a manually
  customized multiplier.
- Verify saved `bm-big-enemy-hp-multiplier` never changes in Mod Settings;
  Normal and Custom must preserve any manual value.
- Check vanilla enemies and players' normal spidertron, as well as
  modded enemies from other mods, remain unchanged.
- Test actual boss spawns and evolution on multiple Space Age planets;
  the source runtime event scheduler remains untouched.
- Compare against the **2.2.1 installed zip**, which may differ from
  the publicly mirrored 2.1.2 source. Test multiplayer consistency.
- Run `texlua tests/test_big_monsters_difficulty.lua`; the mocked
  prototype test does not replace a live Factorio startup test.

Source evidence:
- [Factorio mod portal](https://mods.factorio.com/mod/Big-Monsters)
- [2.1.2 Big Monsters source mirror](https://github.com/FactorioParanoidal/ParanoidalModpack/tree/master/mods/Big-Monsters)
- [Mirror settings.lua](https://github.com/FactorioParanoidal/ParanoidalModpack/blob/master/mods/Big-Monsters/settings.lua)
- [Mirror boss entities.lua](https://github.com/FactorioParanoidal/ParanoidalModpack/blob/master/mods/Big-Monsters/prototypes/entities.lua)
