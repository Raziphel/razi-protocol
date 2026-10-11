# K2SO integrations across the seven-system expedition

This is a cross-mod integration pass, not a replacement for the original
authors' mechanics. Razi uses **Krastorio 2 Spaced Out (K2SO)** as a research
and production backbone, while keeping each world recognizably its own.

## Planetary research-data deliveries

These existing K2SO items are now ingredients in existing Razi System Tech
Cards. They represent genuine logistics and science deliveries from worlds
already accessible by the time each card is needed. The change is applied only
if K2SO, the destination planet, the card item/recipe, and an actual K2SO
research-data production recipe all exist.

| System card | Original K2SO research data | Producer origin |
| --- | --- | --- |
| Solaris | `kr-metallurgic-research-data` | Vulcanus |
| Nyxaris | `kr-agricultural-research-data` | Gleba |
| Vibrant | `kr-electromagnetic-research-data` | Fulgora |
| Vespera | `kr-cryogenic-research-data` | Aquilo |
| Beetlejuice | `kr-matter-research-data` | Aquilo's matter research chain |
| Umbra | `kr-matter-research-data` | Aquilo's matter research chain |
| Deep Space | `kr-promethium-research-data` | Space near the Shattered Planet |

Calidus remains a standalone starting chapter: no off-world-only K2SO
research data should prevent opening Solaris or Nyxaris. The next chapter
does not demand a resource from the planet it unlocks.

These dependencies complement, rather than replace, native Planetaris,
Moshine, Castra, Paracelsin, Muria, Rubia, Crucible, and other science that
already feeds into the cards. The `campaign_weave.lua` research graph is
still responsible for planet-by-planet discovery requirements.

## K2SO material standardization across *all* planets

K2SO's upstream `enforce-k2-items.lua` standardizes oxygen, hydrogen,
chlorine, sand, glass, silicon, lithium, and ammonia. Since some independent
planet-mod compatibility passes run after that file, Razi checks the **final**
recipe ingredients/results, resource/minable output and liquid tiles.

Razi switches a stale original name to the K2SO name **only** when the
original item/fluid is hidden and the corresponding K2SO prototype is
present and visible. This avoids overwriting the common fluids deliberately
restored by Null's K2SO Tweaks. Unrecognized planet-specific resources,
machine categories, custom recipe properties and native source effects are
left alone.

## Validation and remaining work

Lua fixtures prove the name reconciliation, presence guards, compatibility
with Null's chosen common gases, no forced K2SO-on behavior, and repeat-run
safety. CI runs the compatibility/prototype audits as before.

Full `--dump-data-raw` and game validation remain essential. In particular,
check that every K2SO research-data recipe is **actually unlockable,
craftable on a reachable surface, and collectible** in the correct chapter,
and that Razi's system-card crafting category can assemble it. The repo's
tests cannot confirm these complete modpack interactions.

The integration applies to all enabled planet mods at the prototype level,
but that does **not** imply we have individually playtested every planet or
finished integrating every unique native mechanic. Source-owner changes
should remain upstream where practical.

## References

- K2SO upstream: https://github.com/Polka37/Krastorio2-spaced-out
- K2SO enforced names:
  `prototypes/final-fixes/enforce-k2-items.lua` in the upstream repository
- Integration: `prototypes/compat/k2so_planet_integration.lua`
- Fixture: `tests/lua/test_k2so_planets.lua`

## K2SO machinery and production continuity

Razi's late-stage **machine capability parity** now covers three carefully
matched K2SO upgrades. The rule applies to recipes originating on **any
enabled planet**, but only when their normal base-machine category already
exists. It never copies the full catalog of planet-specific recipes.

| Advanced K2SO machine | Compared against | Shared standard capability |
| --- | --- | --- |
| `kr-advanced-assembling-machine` | Assembling Machine 3 | Normal advanced crafting and fluid crafting |
| `kr-advanced-chemical-plant` | Chemical Plant | Normal chemistry including shared chemistry-or-cryogenics |
| `kr-advanced-furnace` | Foundry | Metallurgy only; no special casting categories added |

The machine must already support its own baseline crafting category and have
at least the base machine's fluid input/output interfaces. For example, K2SO's
advanced chemical plant can continue running chemistry that another planet
patch moved from `chemistry` into `chemistry-or-cryogenics`, without being
granted cryogenic-plant-only chemistry or Paracelsin, Rubia, Maraxsis,
Crucible and other exclusive crafting categories. Original recipe surface
conditions, resource restrictions, pollution, energy cost and machine effects
are untouched. The K2SO machines remain meaningful upgrades on any world
where construction is permitted.

### Planet-linked K2SO machine research

The following already-existing K2SO technologies explicitly inherit the
discovery of their native source world:

| K2SO technology | Source world |
| --- | --- |
| Advanced Furnace / Geothermal | Vulcanus, Solaris |
| Advanced Chemical Plant | Gleba, Nyxaris |
| Energy Storage | Fulgora, Vibrant |
| Quantum Computer / Matter Tech Card | Aquilo, Vespera |

These are additive prerequisites only: native K2SO unlocks, triggers,
science, existing prerequisite technologies and recipe outputs are retained.
If the full modpack already contains a prerequisite path, nothing is added.
If the source-mod graph could create a cycle, the crosslink is skipped.
Bootstrap machines like the K2 Research Server and Atmospheric Condenser are
deliberately *not* made dependent on a later planet, as that could strand an
earlier landing.

**Not automatically homogenized:** biochambers, electrolysis plants,
planet-specific foundries, underwater pressure domes, recycling machinery
and unusual high-pressure/biochemical recipe categories remain exclusive.
A later full-engine prototype audit can identify genuine gaps worth addressing
with smaller per-mod compatibility rules.

Test: `tests/lua/test_k2so_machines.lua`. Module:
`prototypes/compat/k2so_planet_machines.lua`. This is a final-stage prototype
patch only and adds no new content or dependencies.

## Detecting regressions across future planet mod updates

The post-load compatibility audit (`scripts/audit_compatibility.py`) now
also checks standard K2SO machine category parity and whether existing K2SO
research data reaches its intended System Tech Card. It warns when the
research-data category has no compatible assembling machine/furnace, or when
the home planet's declared surface properties contradict its production
recipe's surface restrictions.

Run this on a **real post-load Factorio 2.1 data dump**. It is advisory,
not an automatic permission to remove planet-specific restrictions or
rewrite unique recipes. Such restrictions are intentional until a matching
machine, technology and material path is verified.

## Repairing late planet science triggers and mining outputs

An early research-trigger migration can correctly retain `oxygen` or another
K2SO predecessor while some planet recipe still produces it. If a later
compatibility pass remaps that recipe output to `kr-oxygen`, the trigger then
becomes unachievable. Razi now re-runs the **craft-item / craft-fluid research
trigger migration after the final material reconciliation**. The second pass
only changes a target if no recipe still crafts the original and a recipe
actually makes the replacement.

The same guarded material conversion now covers mineable `tree`, `fish`
and `simple-entity-with-owner` entity drops, alongside resources and simple
scenery. It never invents output prototypes or renames unknown modded items.
The post-load compatibility auditor warns when old hidden K2SO aliases
remain in recipe inputs, results or mineable scenery so upstream changes
cannot silently reintroduce them.

### Verify machine placement against source planets

The post-load audit additionally compares every K2SO research-data recipe's
crafting category and fluid requirements with actual assembling machines and
furnaces. If a planet declares the relevant surface properties, the audit
flags cases where **all otherwise compatible machines are forbidden on the
source planet**. It checks explicit numeric surface conditions rather than
guessing unreported planet properties. A valid machine category elsewhere
in the universe is no longer treated as sufficient evidence that the K2SO
research data can be made locally. These remain warnings until verified
against the full game and modpack.

## Cross-mod lab and fluid-port regressions

The compatibility audit now reviews **all enabled research technologies**
whose science ingredients come from multiple mods. If no actual laboratory
accepts the *entire* ingredient combination, it emits an advisory warning
with the technology name and science packs. A set of separate labs each
accepting half the ingredients is insufficient. Hidden/disabled research
nodes are excluded to avoid irrelevant findings.

For K2SO research data, the same audit checks that at least one machine
has enough distinct fluid input/output interfaces to run the science-data
recipe. Neither finding blindly expands lab inputs or machine capability:
the right fix should be chosen once the full modpack's prototypes confirm
the producing world, machine and technology progression.

## Production exchange pass: early, middle and late factories

Razi now introduces three **optional, higher-throughput alternate recipes**
based directly on K2SO's real, source-mod-owned production chains. The native
recipes, unlocking technologies, and planet-specific machines remain intact.
These are not new science-pack ingredients or mandatory research for system
discovery. The recipe and technology only exist when every source material,
original recipe, compatible machine, native recipe unlock, source-world
discovery and appropriate existing lab are present.

| Exchange technology | Where it makes sense | Native recipe reused | Added imported cost | Benefit |
| --- | --- | --- | --- | --- |
| Bio-assisted rare-metal casting | Vulcanus foundry, after Gleba | `kr-casting-rare-metals` | 2 bioflux from Gleba per four batches | Five rare metals from four native batches, preserving original molten metal/water use and byproducts |
| Electrobiological components | Fulgora's electromagnetic plants | `kr-electronic-components` | Bioflux from Gleba, holmium from Fulgora | Seven components instead of four, using all original silicon/glass/plastic inputs |
| Cryo-stabilized energy-control units | Aquilo cryogenic machinery | `kr-energy-control-unit` | Supercapacitors from Fulgora, carbon fiber from Gleba, fluoroketone from Aquilo | Two control units instead of one, retaining all expensive native components |

**Why imports are interesting:** Gleba's output earns a premium in Solaris
and Vibrant; Fulgora supplies later Aquilo industry; and Vulcanus's original
K2SO rare metals become attractive to process even after the first frontier.
You can still choose independent native production if interplanetary shipping
is inconvenient, unreliable, or too expensive.

**Unlock safety:** Each exchange has an independent technology requiring
the source-world discoveries and the *original recipe's actual unlock
technology*. If the real K2SO unlock is unavailable, beyond the intended
chapter, or cannot be identified, the exchange is skipped, rather than
bypassing its original research. The three technologies require Calidus,
Solaris/Nyxaris, and Solaris/Nyxaris Tech Cards respectively, so they
don't consume their own products or need late systems' cards to bootstrap.

**Production safety:** Fulgora's recipe inherits the K2SO electromagnetic
research-data magnetic-field condition; Aquilo's inherits K2SO's native
cryogenic pressure condition. Source machine crafting categories are checked.
No extra machine is granted another planet's special capabilities.
The original recipe ingredients, recipe effects and fluid byproducts are
copied rather than redefined, then extra imported ingredients are added.
Auto-recycling and productivity are disabled on the bonus variants to prevent
multiplying their exchange premium through repeated loops. Native recipes
retain their original productivity settings.

The new recipes show their native item icons with a small imported-material
overlay, with explicit unlock descriptions in `locale/en/production.cfg`.
Isolated Lua regression fixtures check alternative yields, prerequisites,
source-missing guards, surface restrictions, native recipe preservation,
repeat-run safety, and late-technology compatibility.

The exact complete-modpack Factorio 2.1 load still needs testing.
If upstream changes a recipe category or a technology unlock, the guarded
integration deliberately fails closed until reviewed.
