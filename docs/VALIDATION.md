## Native lab removal and Deep Space gateway (2.1.55)

Load a 2.1.54 save with placed/stored Razi lab items. Confirm that JSON
prototype migration converts each of the four removed labs to a
regular Lab and that the inventory of science packs, wires and research
progress behaves acceptably. Back up saves first. The cost of the old
lab upgrade materials is not refunded.

In a fresh game confirm that original K2SO Advanced, Moshine
Thermodynamics, K2SO Singularity, Pressure and Nexus Omega labs accept
their listed Razi cards while retaining unrelated science packs. Review
the installed *actual lab recipes*: freight additions must occur only
when every supplier's research is an ancestor of the original lab unlock.

Build and fully activate the actual K2SO transceiver after completing
the two outer frontiers. Confirm its signal research gates the Solar
System Edge, without requiring Promethium, Nexus, Shattered Planet or
science produced beyond the edge. Confirm K2SO's native victory is
suppressed if its supported `set_no_victory` remote interface exists. Verify existing saves with an already
activated transceiver, and test older/disabled mod combinations.

Manual regression:
```bash
python3 -m unittest discover -s tests -p 'test_system_card_progression.py'
lua tests/lua/test_system_card_laboratories.lua
lua tests/lua/test_deep_space_arrival.lua
```

# Razi Protocol validation

## Manual checks without automatic GitHub Actions

The GitHub Check workflow is available through Actions > Check > Run
workflow. It includes the Lua fixtures, syntax checks and Python auditors.
It's intentionally manual to avoid burning through Actions minutes.

## Safe cheat research for very large modpacks

Factorio's built-in `/cheat` calls a synchronous all-technology research
operation. With many large planet mods, all research and any responding mod
events run before the simulation can continue. A frozen window may end with
an external SIGTERM rather than a Lua stack trace.

Use these commands **in a disposable testing save** with the development mod
installed, rather than `/cheat` or `/c game.player.force.research_all_technologies()`:

- `/razi-cheat` (or `/razi-cheat start`) enables free crafting for the admin
  who ran it and incrementally researches eligible, not-yet-researched
  technologies for that player's force.
- `/razi-cheat status` shows the number of technologies processed.
- `/razi-cheat cancel` stops future changes, but does **not** undo research
  that was already granted. Reload a backup if you need to revert it.

Research is visited in prerequisite order, with only one technology changed
every six game ticks. This intentionally omits the extra starting inventory,
teleportation and other side effects of the built-in cheat. Disabled or hidden
source prototypes remain untouched. Each technology change still applies its
normal research effects, while the Codex waits for the bulk work to finish.
The job persists across saves and can resume after reloading; status and
cancel are scoped to the player's force. On a multiplayer server, only admins
can use the command.

Admins also receive a one-time reminder when joining a save.
When a player enters `/cheat`, the mod listens for Factorio's
`on_console_command` event and, if the game is still responsive,
prints a warning recommending `/razi-cheat`. Repeated attempts are
rate-limited to one reminder per player per ten seconds.
The harmless `/cheat off` form is ignored. Regular players never receive
the admin join reminder. These messages do not replace the built-in
command or run research.

This is a **safer alternate testing workflow**, not an interception or repair
of the engine's built-in `/cheat`. Third-party mod research hooks or very
expensive individual technologies can still cause issues. For an actual
freeze, keep the latest Factorio log, system memory diagnostics and a backup
save; static fixtures alone do not establish a successful full-pack playtest.

## Validate the actual modpack in Factorio

Static checks cannot know the final prototype state after every dependency
has run its data stages. For each supported configuration:

1. Enable the exact mod combination you want to release with.
2. Run Factorio with --dump-data-raw, which writes
   script-output/data-raw-dump.json into the Factorio write-data directory.
3. In this repository run:

       python3 scripts/audit_prototypes.py /path/to/script-output/data-raw-dump.json

The auditor checks:

- missing and cyclic technology prerequisites
- whether one lab accepts every science ingredient for each Razi campaign tech
- all eight system cards and their recipe unlocks
- space-connection endpoints
- physical routes from Nauvis to the seven major system hubs

To check specific optional planets, pass --required-location planet-name,
repeating the flag for additional planets. For an experimental map with
different hub semantics, pass --no-campaign-route-checks to disable only the
hard-coded campaign reachability requirement; route endpoint validation remains.

Suggested smoke-test configurations:

- Required-only Factorio 2.1 pack (the release baseline)
- Required pack with all seven system gates unlocked and Outer Frontier Mastery completed
- Required pack + Nexus-Updated
- Required pack + supported optional planets such as Cerys
- Required pack + each optional enemy family
- All compatible optional integrations together, where releases exist

The auditor cannot prove that an in-game resource chain is economically
craftable or that activation events will fire. Still test a fresh game, an
existing save migration, and the singularity transceiver in-game. In
particular, checking the technology graph alone does not prove every recipe
has producible materials.

These full-engine modpack tests are manual until a Factorio binary and legal
dependency staging are available to CI.

For the new progression, explicitly test two independent first-tier entry choices,
both second-tier branches, both third-tier branches, the Muria/Aquilo and
Tenebris/Crucible travel paths, and an unmodified Aegis/Bellicos expedition.
The new Lua fixtures verify structural intent only: they cannot prove resource
craftability or that parent star coordinates render cleanly in Factorio.

The interwoven progression fixture additionally checks science technology
prerequisites, complete-lab compatibility, cyclic and absent dependencies,
and repeat-pass stability. The full pack must still be tested in-game.

## Recipe-unlock and source-planet reachability audit

The post-load prototype auditor now checks a second dependency graph that
research prerequisite checks alone miss: **which technology unlocks the
recipes that produce each mandatory System Tech Card ingredient**. If every
source recipe is locked behind the very research consuming that card, it
reports a hard science-supply deadlock. The audit also finds card recipe
ingredient cycles and checks known source-planet science against the
consumer's transitive planet-discovery prerequisites.

The interwoven science module now declines to add an optional science-pack
cost when every available recipe producing that pack unlocks only at or
after the consuming discovery technology. It retains the normal predecessor
research milestone, avoiding an artificial lock on the actual ingredient.

This only establishes *logical availability*. It cannot establish fuel,
electricity, resources, special crafting events, surface placement or input
transport without a complete enabled-modpack Factorio dump and a gameplay
smoke test.

## Linox hard-mode integration with the outer system

Linox's optional `linox-settings_hard-mode_enable-science-pack_aquilo`
setting can insert `linox-item_linox-science-pack` into pre-Linox
Aquilo-era technologies. Linox itself moved into Beetlejuice, and cannot
supply that pack until its discovery and native production are unlocked.
Razi now strips that ingredient only from the prerequisite ancestry of
`beetlejuice-discovery`, `umbra-discovery` and Linox's own landing
discovery. This keeps all required entrances feasible while leaving later
Linox hard-mode recipes and technologies untouched.

The source-planet ancestry assertion is restricted to **Razi campaign
milestones**. Independent K2SO/third-party technologies can legitimately
consume imported System Tech Cards without having every source-world
planet discovery as a direct prerequisite. Such use is not a deadlock.

## Late-world exclusive-science bootstrap

Crucible is originally designed to be visitable before Aquilo and can modify
Aquilo-tier research. Razi now places Crucible in Umbra. The guarded
`outer_science_arrival_guard.lua` removes Crucible's own science/tech-card
cost only from the prerequisite chain that unlocks Crucible, and similarly
prevents Vesta's gas science from blocking Vesta discovery. Native post-arrival
research keeps these exclusive science requirements. The guard runs only
with the relevant world and K2SO enabled, and avoids an empty tech-cost
prototype by using an already-valid early science fallback when available.
A live full-modpack prototype dump must still verify all native revisions.

## Aquilo, Linox, Crucible and Vesta supply-chain report

A separate nested producer-chain report now examines the installed
post-load modpack for the four most sensitive worlds and the Outer Frontier:

    python3 scripts/audit_supply_chains.py /path/to/script-output/data-raw-dump.json
    python3 scripts/audit_supply_chains.py /path/to/script-output/data-raw-dump.json --json

The report checks **before** each discovery whether its research science has
a recipe path whose producer recipes are unlocked by prior technologies, and
**after** arrival whether important native/K2SO products have a traceable
recipe ingredient chain. It resolves multiple producer recipes, mined inputs,
technology-unlock effects, recipe surface conditions and machine categories.
The JSON includes the chosen recipe, its nested dependencies and blockers,
so a precise compatibility rule can be written instead of globally changing
a planet's resources.

Interpreting status:

- `traceable`: an apparent recipe path exists, not a gameplay guarantee
- `natural-source-unverified`: some mineable prototype produces the material,
  but **its presence on the current world has not been established**
- `blocked`: no path within the research and machine snapshot under the
  stated assumptions; review the nested unlock/surface/machine reason
- `unresolved`/`unverified`/`depth-limit`: insufficient proof, not a hard error

The report is intentionally advisory and does not make a green GitHub
Actions fixture run stand in for a real Factorio game load. Source mods can
grant material through starting inventory, script events, asteroid routing,
spoiling or remote supply. In particular, researching an independent branch
outside a tech's formal prerequisites is possible, so a recipe listed as
locked in its strict ancestor snapshot is **not necessarily** impossible.
A real data dump and targeted in-game playtest determine which alerts need
patches.

### Specific source interaction

Crucible's upstream author documents that its mod changes some Aquilo-era
technologies and supports K2SO natively. Razi places Crucible after Aquilo,
so `outer_science_arrival_guard.lua` ensures Crucible science cannot appear
in research needed to reach Aquilo, Umbra or Crucible. Vesta's gas science is
treated similarly. Only late-world-exclusive science is removed from those
pre-arrival milestones; native science needed after arrival remains in place.
See `tests/lua/test_outer_science_arrival_guard.lua`.

The recipe-chain tracer explicitly distinguishes recipes locked *behind*
the destination (`future-unlock`, a likely deadlock) from recipes unlocked by
independent technologies outside the snapshot's prerequisite ancestry
(`independent-research`, not enough evidence to call impossible).

## Route distances and native travel behavior

Compare final route length values to the final parent-orbit starmap:

    python3 scripts/audit_route_distances.py /path/to/script-output/data-raw-dump.json

This checks the post-load hub-to-hub and outer Deep Space km-per-map-unit
ranges, travel tiers, duplicate routes and direct shortcuts across surveyed
belts. It intentionally excludes native planet moon orbits, long-range
stargates, the optional Nexus endgame and original source internal links.
In particular, the native route length is respected within the Razi local
travel envelope and native modded asteroid entries are not replaced.
See `tests/test_route_distances.py` and `tests/lua/test_galaxy.lua`.

## Startup settings and localized grouping

The FluxWorks-style Razi startup settings are checked by
`lua5.2 tests/lua/test_settings_presentation.lua` for stable prototype
names, startup types, default values, deterministic category ordering,
colored rich-text labels, and English/Russian descriptions. The existing
enemy routing and redundant assembler defaults are preserved.

Additional production and planet-description fixture cases now verify the
new optional switches: off means no Razi-owned alternate recipe/briefing;
the native recipes, technology and planet description are not removed.
Factorio's built-in settings UI controls the layout; the sections are
localized prefixes, not fabricated headings or custom interface panels.

## Community expansion post-load checks

The added optional-world fixture runs with
`lua5.2 tests/lua/test_community_expansions.lua` and tests:
repeated pass idempotence; guarded startup when mods/planets/gates are
missing; technology-cycle avoidance; keeping native solar flare,
Balack, Ferrum and Wit connections; no Rabbasca Underground platform route;
correctly positioned ordinary extra worlds; and preserved native technology
unlock effects.

**Not a live installation test:** enabling all newly optional mods can
introduce conflicting deep science-pack costs or new endgame definitions.
Review Wit space-science availability, the Balack promethium science
requirement, Shattered Planet redefinitions, Ferrum choice-driven research,
Hephaestus shortcuts and Arkanyx's Voidcraft requirement before shipping.

## Community industry sources and tests

`lua5.2 tests/lua/test_community_industry_exchanges.lua` validates the
post-load optional Ferrum, Wit and Balack alternatives. It checks actual
native recipe quantities, independent late tech prerequisites, missing mods,
suppliers and machines, original recipe preservation, disabled optional
settings, and repeat-run stability. This is a synthetic prototype fixture,
not a complete live Factorio 2.1 startup and playtest.

## Startup performance regression checks (2.1.21)

The Lua fixtures in `tests/lua/test_planet_production_exchanges.lua`,
`tests/lua/test_campaign_weave.lua` and
`tests/lua/test_regional_research_bridges.lua` cover cached machine/lab
catalogues, unchanged research guards and the empty-optional-world fast path.

For a real benchmark, check `docs/STARTUP_PERFORMANCE.md`. Tests can check
recipe and tech behaviour, but cannot substitute for a full dependency-load
timing or test Factorio's sprite atlas build.

## Campaign gates and mass-research stress test (2.1.22)

The data stage already loads `util.lua`, which provides global helpers for
science packs and technology prerequisites. The seven-system gate module
now performs these checks locally, rather than relying on that implicit
global dependency. Its fixtures no longer install mocked helper globals.
New prerequisite edges also refuse a cycle when a source mod moves a
discovery behind the proposed campaign gateway.

The Codex groups bursts of twelve or more relevant research completions
within a 120-tick window. Normal research still refreshes on the next
30-tick maintenance pass. A large batch waits for 180 ticks of quiet
before the next GUI rebuild. Older boolean pending-work entries remain
readable during save migration.

**In-game check with the actual full modpack:**

1. Boot a copied save with the Codex open; verify the game passes
   `data-final-fixes` and starts normally.
2. Confirm Solaris and Nyxaris both open from Calidus; neither should
   require the other branch's first planet.
3. Check that Panglia's native data-cell research remains present,
   that the Vibrant belt is required before Paracelsin, and that
   Beetlejuice/Umbra still contribute to outer mastery.
4. On a *disposable test save*, run the mass-research cheat with the
   Codex open and a quest pinned. The window should redraw once after
   the research events stop, not on every completion.
5. If the cheat still stalls, compare `factorio-current.log` with a
   run that has the Codex closed and a run without Razi. A hang in
   Factorio's bulk research processing or a different mod cannot
   be ruled out by the Lua fixtures.

The research burst guard does not change any technology's researched
state, source unlock, recipe, or the saved Codex preferences.

## Complete planet progression audit (2.1.23)

Run Factorio **once with the exact required and optional mods enabled** and
`--dump-data-raw`. Use the resulting `script-output/data-raw-dump.json`:

```bash
python3 scripts/audit_full_campaign.py \
  /path/to/script-output/data-raw-dump.json \
  --output full-campaign-audit.json
```

This joins the main prototype graph/route/card checks with a supply-chain
trace for **every installed planet's native discovery research**. It includes
a dedicated summary for Panglia, Aquilo, Linox, Crucible and Vesta. The report
also lists geometrically disconnected planets as an advisory, not an error:
scripted destinations and special travel mechanics require manual review.

An exit code of 1 means that the final prototype dump has a structural
prototype issue or a discovery with **only demonstrably blocked science
paths**. Unknown mining availability, missing discovery effects and
independent source technology branches are reported separately and never
silently treated as verified or as fatal.

For a machine-readable stdout report:

```bash
python3 scripts/audit_full_campaign.py \
  /path/to/script-output/data-raw-dump.json --json
```

The Linox and outer-world science guards also run once after the remaining
technology integrations. This catches late research rewrites that reintroduce
Linox science before landing, Crucible science before reaching Crucible, or
Vesta gas research before reaching Vesta. Linox's guard now avoids emitting a
zero-ingredient technology when the removed science was its only pack.

**Limits:** No real Factorio dump is committed to this repository, and the
audit has not been executed against the complete installed modpack here.
An unverified chain is not a confirmed deadlock or a pass. Production machines,
world-specific resources, transport logistics, scripted gates and native
research triggers still need a real-game campaign test. Never delete a source
research requirement automatically based solely on an advisory result.

## Return-cargo network checks (2.1.24)

The Lua fixture `tests/lua/test_network_components.lua` now checks both
new guarded components, Deep-mode restrictions, missing Panglia/Crucible,
source unlocks and premium recipe dispatch. The Codex and locale fixtures
cover six new industry milestones without renaming the previous 204 IDs.

Run the opt-in Check workflow or locally:

```bash
lua5.2 tests/lua/test_network_components.lua
lua5.2 tests/lua/test_razi_journal.lua
python3 -m unittest tests/test_razi_journal.py
```

Check source versions with `python3 scripts/audit_full_campaign.py` on a
real Factorio `--dump-data-raw` export. The opt-in network intentionally
does not register its recipes when a source-mod recipe, machine,
technology or compatible science lab is absent.

## Industrial economics audit (2.1.25)

Run the new source-only fixtures locally:
```bash
lua5.2 tests/lua/test_planet_production_exchanges.lua
lua5.2 tests/lua/test_outer_production_exchanges.lua
lua5.2 tests/lua/test_network_components.lua
python3 -m unittest discover -s tests -p "test_exchange_economy.py"
```

On an actual complete Factorio `--dump-data-raw` export:
```bash
python3 scripts/audit_exchange_economy.py /path/to/data-raw-dump.json
python3 scripts/audit_full_campaign.py /path/to/data-raw-dump.json \
  --output full-campaign-audit.json
```
The full campaign report now includes an industrial freight economy section.
It checks source recipe output, added import amounts, throughput, bonus
caps, productivity and recycling. Its negative results should be reviewed
against in-game transport and source material production costs; source
analysis cannot prove actual rocket-level profitability. These commands
do not create GitHub Actions runs.

## Galactic Operations card layout and localisation (2.1.26)

Run existing fixtures from the mod root:

```bash
lua5.2 tests/lua/test_galactic_operations.lua
python3 -m unittest discover -s tests -p 'test_galactic_operations.py'
```

The suite now checks layout budgets on 1920×1080, 1280×720 (150% scale),
1024×768 (150% scale), 900×600 and ultrawide resolutions, plus paging,
translated planet-name matching, platform location matching and the
shared translation event. Planet icons are validated with Factorio's
`helpers.is_valid_sprite_path` before rendering. Missing icons use the
existing Galactic Operations artwork.

**Manual game check:** Change the GUI scale between 100% and 150%, filter
a large mixed fleet, switch tabs, select a planet, assign and reset a
private fleet role, favourite a destination, open the Atlas, and use
the Clear search action. Repeat with a non-English game locale. Ensure the
existing Discord presence translation handler continues to receive its
events. Native platform schedules, hub cargo and surfaces must remain
unchanged. This verification requires a real Factorio runtime.

## Cargo Network dashboard (2.1.27)

Run the existing Galactic Operations test suite (now expanded for all
four industrial components and ten downstream technology IDs):

```bash
lua5.2 tests/lua/test_galactic_operations.lua
python3 -m unittest discover -s tests -p 'test_galactic_operations.py'
```

The Lua fixture checks native-tech filtering, missing optional branches,
research blockers, completed consumers, direct recipe rendering and narrow
layout actions with a mock GUI. The Python check guards data-stage
technology IDs, locale keys and read-only Factorio API usage. The
dashboard does not poll inventories or transit every tick.

In a real game, compare Balanced versus Deep and verify the Umbra
Pressure Frame is absent in Balanced; collapse and expand cards,
inspect a recipe with missing supplies, and check real native
ingredient counts from the current enabled mods. Do not treat a
researched technology as proof of live manufacturing or delivery.

## Cargo ↔ Protocol Codex navigation regression (2.1.28)

The existing Galactic Operations and Protocol Codex fixtures now check
the entire eleven-milestone ID map, the actions behind both link
directions, invalid technology rejection, and exact quest selection:

```bash
lua5.2 tests/lua/test_galactic_operations.lua
lua5.2 tests/lua/test_razi_journal_layout.lua
python3 -m unittest discover -s tests -p 'test_galactic_operations.py'
python3 -m unittest discover -s tests -p 'test_razi_journal.py'
```

Live verification: Open a Panglia industrial Codex objective outside
Remote View and follow its Cargo link. Check that the Cargo panel
remains visible after the existing 30-tick map check and after changing
GUI scale. Return to the exact objective. Repeat with the Umbra Pressure
Frame in Balanced and Deep interdependence modes; missing source
technology must not advertise a link. Neither operation may create a
surface, move a player, complete research or dispatch a space platform.

## Recommended expedition objectives (2.1.29)

The planner fixture uses the real 210-quest catalogue and synthetic native
research states, so a recommendation only becomes research-ready if its
technology is enabled and all actual prerequisites are researched.

```bash
lua5.2 tests/lua/test_razi_journal_guidance.lua
lua5.2 tests/lua/test_razi_journal.lua
lua5.2 tests/lua/test_razi_journal_layout.lua
python3 -m unittest discover -s tests -p 'test_razi_journal.py'
```

Check the Codex at the start of a save, after unlocking Solaris/Nyxaris,
and after disabling optional planet mods. The primary and parallel
milestones should remain navigable, the blocker must describe real
source technology or story prerequisites, and unrelated pinned quest
preferences must survive navigation. A native technology may be ready
for research while the required science production is still unavailable;
the guide makes no claim about inventories or materials.

In particular, verify the priorities stay visible at the top of the
existing scrollable chapter navigator without adding new horizontal
scrollbars or increasing the overall Codex window height.

## Galactic technology-tree coherence (2.1.30)

The final post-arrival `prototypes/technology/research_tree_polish.lua` pass
adds conservative prerequisites **only to Razi's optional industrial
technology**. It does not touch native planetary discoveries, source
recipes, labs, science packs or star-system gateway research. A link is
skipped when the source technology is absent, hidden, disabled, or would
make a prerequisite cycle. Deep-only weaving runs only with
`razi-planetary-interdependence=deep`; Off does nothing.

The industrial research price ceilings apply to six older Razi factory
upgrades rather than rescaling every technology installed by source mods.
Four major component nodes are marked essential for easier technology
tree filtering, and the related downstream upgrades are grouped together
by component family using Razi-owned `order` keys.

To run the new standalone regressions and audit:

```bash
lua5.2 tests/lua/test_research_tree_polish.lua
python3 -m unittest discover -s tests -p "test_research_balance.py"
python3 -m unittest discover -s tests -p "test_full_campaign.py"
python3 scripts/audit_research_balance.py /path/to/data-raw-dump.json --json
python3 scripts/audit_full_campaign.py /path/to/data-raw-dump.json \
  --output full-campaign-audit.json
```

The pacing audit lists Razi milestone costs and science usage, checks
Sol/Nyx, Vibrant/Vespera and Beetlejuice/Umbra as independent paired
entry routes, and flags suspicious cost differences, absent required
science prototypes and impossible combined laboratory inputs. Only
definite contradictions are considered errors. Absence of a production
recipe, inaccessible crafting conditions and unexpected mod-specific
scripted unlocks still require the separate supply-chain audit and a
real Factorio playthrough. Do not force-fix advisory source-mod prices.

Test a fresh save and a pre-existing save with interdependence set to
Balanced, Deep and Off. At least one of each paired star-system entry
must remain researchable without completing the other entry. Panglia,
Aquilo, Linox, Crucible and Vesta must all retain their first viable
factory setup and all pre-arrival science guards.

## Returning planetary science to later research (2.1.31)

The research weave only operates on Razi-owned optional factory
technologies, after all planetary discovery guards and industrial
prototype registration. It requires an upstream source discovery,
a craftable native science recipe with an earlier research unlock,
compatible surface conditions, and one existing lab accepting the
full science set. No lab, source recipe or planet technology is
modified to make a test pass.

```bash
lua5.2 tests/lua/test_planetary_science_weave.lua
python3 -m unittest discover -s tests -p "test_planetary_science_weave.py"
python3 -m unittest discover -s tests -p "test_research_balance.py"
python3 -m unittest discover -s tests -p "test_galactic_operations.py"
python3 scripts/audit_research_balance.py /path/to/data-raw-dump.json --json
```

The Lua fixture covers missing native producers, unavailable inputs,
wrong production surfaces, disabled interdependence, source technology
loops, incompatible labs, repeated passes, and Deep-only recipes.
The Python audit also checks that a planet never needs its own science
before arrival, and reports actual reused native science packs in
loaded Razi industry research.

**Manual validation:** In Balanced and Deep, visit Panglia, Paracelsin,
Linox, Rubia, Tenebris, Crucible and Vesta as each becomes available.
Check that research only demands sciences obtainable on worlds already
unlocked, and that an installed lab accepts the whole combination.
Expand Cargo Network components and jump to a downstream Codex
milestone to verify the displayed science requirements match the
native technology tree. Use the complete modpack, not source mocks.
