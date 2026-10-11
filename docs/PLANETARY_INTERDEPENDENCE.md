# Planetary Interdependence: modes, economy and progression

This document describes Razi-authored optional **integration**, not an
unverified claim of in-game playtesting. Existing source-mod mechanics remain
intact and the campaign's seven core system gates always remain active.

## Startup modes

| Mode | Research weave | K2SO research-data cards | Razi alternatives | Deep alternatives |
| --- | --- | --- | --- | --- |
| Off | No | No | No | No |
| Balanced (default) | Yes | Yes | Existing catalogs | No |
| Deep | Yes | Yes | Existing catalogs | Nine additional guarded recipes |

The original two toggles for K2SO and modded planet exchanges are still
independent within Balanced and Deep. Off overrides both. Data-stage K2SO
alias repair and standard machine capability parity are *not* shut down by
Off because those are compatibility repairs, not interplanetary demands.

Changing a startup mode on an existing campaign can remove Razi recipes or
change research prerequisites. **Back up the save** before switching, ideally
test on a copied save, and avoid switching modes mid-research.

## Deep interstellar trade

All Deep recipes are optional specialisations. Their requirements always
include the native destination discovery and native recipe technology; when
a supplier's actual recipe is locked, its unlock research is additionally
required. They never become mandatory ingredients for system cards.

| Factory | Imported from | Native recipe | Research cost (each listed system card) |
| --- | --- | --- | --- |
| Vulcanus | Paracelsin zinc plate | K2SO rare-metal casting | 850, Solaris + Nyxaris |
| Fulgora | Moshine optical cable | K2SO electronic components | 900, Solaris + Nyxaris |
| Aquilo | Moshine optics, Fulgora holmium, Aquilo coolant | K2SO energy control units | 1250, Vibrant + Vespera |
| Moshine | Fulgora holmium plate | Silicon cells | 650, Solaris + Nyxaris |
| Rubia | Linox rare-earth powder | Long-stack inserters | 1400, Vibrant + Vespera |
| Tenebris | Paracelsin zinc rivets, Moshine optical cable | Chitosan | 1300, Vibrant + Vespera |
| Vesta | Secretas/Cubium gold plates | Supermagnets | 1550, Vibrant + Vespera |
| Linox | Rubia craptonite frame | Rare-earth refining | 1450, Vibrant + Vespera |
| Ferrum | Paracelsin zinc plate | Rare-earth magnets | 1350, Vibrant + Vespera |

These are **late alternate recipes**, not direct changes to native production.
Every recipe still consumes the original ingredients, produces the original
byproducts at their original proportions, and adds imported goods. A recipe
only appears if all its relevant source mods, prototype IDs, research,
ingredients, specialist machines and applicable surface conditions exist.

Deep-mode production rules must yield at most **30% additional deterministic
target product** above the unchanged native batches. This is enforced
against actual final native results, rather than trusting hard-coded output
amounts from a potentially updated planet mod. If an upstream mod changes
its output and breaks this budget, the alternative safely disappears. Bonus
recipes have no productivity and no automatic recycling to prevent stacking
free items. Native recipe research never unlocks early.

## Progression and balance principles

1. **The player can start Solaris and Nyxaris independently.** No imports
   from an undiscovered later world should block the opening expedition.
2. **The core worlds must bootstrap themselves.** An optional trade incentive
   must not replace the only way to make an essential early product.
3. **Imported goods create ongoing markets.** They should make older factories
   relevant after reaching outer systems without making every optional world
   mandatory.
4. **Native specialty machines and environments stay relevant.** Razi does not
   use cross-world exchanges to evade pressure, magnetism, undersea requirements
   or unique crafting categories.
5. **Higher efficiency is a reward, not an infinite yield exploit.** Deep
   recipes must import real goods, are deliberately batched, and have a
   hard upper bound on added deterministic output.
6. **Optional means optional.** The first successful voyage, every required
   science production chain and completion of the seven-system campaign must
   remain viable without these recipes and without every optional planet.
7. **Research accessibility is separate from physical accessibility.** The
   implementation checks final recipes, technologies, labs and machines at
   data stage; full material availability and economics still need actual
   Factorio 2.1 testing.

## Release validation matrix

- Required mods: fresh start and all seven system-gate milestones in Off,
  Balanced and Deep, including both independent early expedition choices.
- Required + K2SO: check that native production remains intact in all modes.
- Required + every supported optional source mod: confirm native unlock
  precedes Razi research, all imported items physically deliver, actual
  specialist machines craft the recipe, and rewards are worth hauling.
- Whole community modpack: run `--dump-data-raw`, then
  `scripts/audit_prototypes.py`, `scripts/audit_compatibility.py`
  and `scripts/audit_supply_chains.py`; investigate warnings and smoke-test.
- Save migration: research/recipe visibility before and after switching modes,
  on *backed-up* existing saves only.

Lua fixture tests protect the mode switch and source structure. They do
**not** replace the full Factorio 2.1 binary/modpack smoke tests.
