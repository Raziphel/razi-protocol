# Validation strategy and release expectations

Use the [Developer Handbook](DEVELOPER_HANDBOOK.md) for design invariants and [Architecture](ARCHITECTURE.md) for ownership boundaries.

**Validation has four layers:** (1) static/source tests for stable IDs and guarded lookups; (2) technology graph and recipe/laboratory reachability; (3) Factorio startup/new-game/old-save checks; (4) visual map and journal interaction checks. Passing one layer is not evidence of passing all four.

For a progression or route change, confirm research prerequisites, science production, lab access, platform accessibility, optional-mod fallbacks, real finalized routes and old-save schedules. For journal changes, confirm existing save IDs, English locale completeness, translated placeholders, truthful project states, scrolling and smaller UIs.

### Contributor commands

```bash
python tools/journal_locale.py
python -m unittest discover -s tests -p 'test_*.py'
```

Other Lua fixtures and in-game steps are listed below. Run focused tests during development; execute the wider suite before release where available. Do not invent a green result when a runtime or modpack could not be loaded. Documentation-only edits should not trigger redundant build CI.

### Acceptance record

Each pull request should document *tests executed*, *manual checks*, *untested environments*, and *save/compatibility consequences*. Distinguish source-level checks from actual Factorio visual/gameplay verification.

The dated sections below are historic test plans that may cover older route layouts. Prefer final prototype state and current source when they disagree.

---

## October 2026: Vesta, Abacayba, and the outer Obsidiax branch

Install Abacayba 0.0.42+ only when testing the optional alpha endgame
overhaul, including its own UMR/UFP/Ultimate Core dependencies. Confirm
Abacayba's orbit has **planet Vesta** as its parent, not Nauvis/Aquilo.
At multiple zoom levels confirm a short Vesta-Abacayba moon route and a
clear diagonal Vesta-Obsidiax connection with no route through the
Shattered Divide or ghost Nauvis/Aquilo links.

Verify the source-owned discovery has planet-discovery-vesta as a
prerequisite but keeps its other required science, recipes and research
effects. Check game startup, the full native Abacayba enemies and
Itaverax mechanics, and native Ominous Science availability.
Check both with and without Abacayba and test an old copied save
with the original source route (platform schedules may require
manual replacement after removing source connection IDs).

The checks are manual/opt-in and require no automatic GitHub Actions:

```bash
lua5.2 tests/lua/test_abacayba_integration.lua
lua5.2 tests/lua/test_route_authority.lua
lua5.2 tests/lua/test_razi_journal.lua
python3 -m unittest tests/test_starmap_clarity.py tests/test_optional_planets.py
```

## 2.1.73: Distributed native and modded technologies

The default-on `razi-distributed-technology` startup option now
uses real source science from Gleba, Vulcanus, Fulgora and Cerys for
selected reactor/robotics/remote industry research. Missing packs,
research producers, unlocked prerequisites, cycles or early compatible
labs must cause an **individual safe skip**, not a startup failure or
new machine registration. See [Distributed Technology](DISTRIBUTED_TECHNOLOGY.md)
for the complete bootstrap, modded technology and old-save checklist.

Confirm construction robotics does not require a technology whose
recipe or manufacturing line itself requires construction robotics.
Confirm first rockets, Calidus cards, both first star gateways,
lab construction and basic asteroid platform supplies still work
without bots or nuclear power. Nuclear power and logistic robotics
need actual metallurgic and agricultural research units, not simply
discovery prereqs. Test with/without Planet Express, AAI and Cerys.

Run local fixtures and post-load audits with **manual invocation**
only. No automatic GitHub Actions or mod release promotions.

## 2.1.72: Minimal-art starmap and clear-tech review

In Subtle background mode, there should be exactly 36 original small-dot
sky tiles, eight individually tuned system halos, two single-layer
outer-belt images and eight distant dust accents when all options are
enabled. The original Vibrant ring is managed separately. Cinematic may
add two low-opacity outer debris layers. All existing orbit coordinates
and route lengths remain untouched. Confirm quiet stars and clear hover
targets at close, medium and full-map zoom.

Open Galactic Operations -> Research & Campaign at normal, narrow,
and high-DPI resolutions. Each installed system card should have a
20px source item sprite, a small colored title and a thin completion bar
based on *discovery technologies actually present*. No fictitious
completed discovery should be shown for missing source mods.
The five first-party technology groups reorder Razi-owned milestones
only and must never rewrite a native world's `order` or prerequisites.

Open a harmless source route and confirm the tooltip has no warning
spam. Open Vespera and Umbra's physical belt crossings and confirm
the biggest threat, critical warning and preparation line remain easy
to find. Confirm modded unknown asteroids still warn rather than
silently receiving a benign classification.

Focused local fixtures:
```bash
lua5.2 tests/lua/test_starmap_background.lua
lua5.2 tests/lua/test_tech_tree_visibility.lua
lua5.2 tests/lua/test_route_intel.lua
python3 -m unittest discover -s tests -p 'test_starmap_background.py'
python3 -m unittest discover -s tests -p 'test_tech_tree_visibility.py'
python3 -m unittest discover -s tests -p 'test_route_intel.py'
python3 -m unittest discover -s tests -p 'test_galactic_operations.py'
```
Do not start GitHub Actions just to check these cosmetics. Full modpack
startup, physical starmap render and old-save screenshots remain
unverified until run in Factorio.

## 2.1.71: Space artwork render checks

Test the full constellation at multiple zoom levels with Razi Protocol
Subtle and Cinematic sky settings, with Fine Details and Galactic
Ornaments on and off. Expect tiny stars with faint per-tile variations,
small coronas that don't cover planets or their routes, and no duplicate
generic ring above Vibrant's existing native art. Vespera should have a
pale icy debris accent and Umbra a muted copper-red one.

Confirm `razi-starmap-background-style=off` and
`razi-starmap-belt-atmosphere=false` both hide the Razi Vibrant ring
without changing actual belt rim positions. If the optional
`Better_Starmap_Background` mod is enabled, Razi's sky and special
Vibrant atmosphere should both defer to it. Preserve the game's native
star layers, click/hover connections, physical travel lengths and
asteroid spawn definitions.

Regression fixtures (run locally; do not enable automatic Actions):
```bash
lua5.2 tests/lua/test_starmap_background.lua
lua5.2 tests/lua/test_asteroid_belt_integration.lua
python3 -m unittest discover -s tests -p 'test_starmap_background.py'
python3 -m unittest discover -s tests -p 'test_route_highlights.py'
python3 scripts/audit_assets.py
```
Artwork changes do not claim gameplay speedups or measured GPU gains.
A real Factorio render and a copied old save remain the release gate.

## 2.1.70: Native asteroid belt and saved-platform checks

Razi replaces the external AsteroidBelt mod's gameplay with **Razi-owned**
Vibrant, Vespera and Umbra crossings. Both inner and outer rims should
offer safe native chunks; Vibrant favors metallic, Vespera oxide and Umbra
carbonic. Inspect each mid-crossing at 25%, 50% and 75% progress for
improved native chunks and higher combat asteroid pressure, respecting
the original big/huge difficulty tiers. Existing modded chunk types must
remain unchanged. No newly invented asteroid species or runtime spawns.

Do not enable the old AsteroidBelt at the same time: it is incompatible
in `info.json`. Keep Vibrant's original belt endpoints and survey
technology ID. Check early survey availability before new Vespera/Umbra
planet sciences and confirm the actual space-platform path cannot bypass
either crossing through an unintended source route. Back up saves and
pause platforms midway through the now-rebalanced crossings before
testing a fresh install. Check visuals, old schedules, and optional
native mod integrations; static tests are not enough.

```bash
lua5.2 tests/lua/test_asteroid_belts.lua
lua5.2 tests/lua/test_asteroid_profiles.lua
lua5.2 tests/lua/test_asteroid_belt_ecology.lua
python3 -m unittest discover -s tests -p 'test_asteroid_belt_ecology.py'
python3 -m unittest discover -s tests -p 'test_route_distances.py'
python3 scripts/audit_route_distances.py /path/to/full-data-raw-dump.json
```

The full dump now checks safe-rim resource spawns, one actual route per
belt and richer native ore at each route midpoint. Runtime compatibility,
platform damage balance and UPS remain unverified until Factorio runs.

## 2.1.69: Mod settings sort-position experiment (reverted 2.1.84)

Factorio sorts option groups **by mod first**, then sorts the settings
inside each group by each prototype's `order` and `name`. Its published
modding API does not expose a supported per-mod settings sort priority.
Renaming `razi-protocol` would break mod identity, dependencies and
`__razi-protocol__` asset paths; do not do that.

The cosmetic experiment did not improve the settings group position.
In 2.1.84, English `locale/en/settings.cfg` again contains
`[mod-name] razi-protocol=Razi Protocol`, matching the canonical
`info.json` title. Mod identifiers and setting names remain unchanged.
Do not introduce special punctuation to game-facing names or modify
dependency exclusions (the `! mod-name` syntax in `info.json` is
meaningful and must remain). Use Factorio's settings search/filter
instead of trying to force cross-mod sort order.

Run the static identity check locally:
```bash
python3 -m unittest discover -s tests -p 'test_settings_sort_hint.py'
```
This validates localization and identity only, not the engine's GUI sort.

## 2.1.68: Science-economy and freight balance release gate

The seven system-card freight alternatives are **optional**, never first
discovery requirements. Test all seven registered recipes when their source
items exist. Verify that four ordinary card batches and their original
ingredients are charged, imported inputs are additionally consumed, and
five cards are produced. Confirm craft time equals 4 × ordinary recipe
seconds × 1.15, with no productivity stacking or automatic recycling.
When a supplier item or source discovery is absent, only its optional
freight recipe should be suppressed. Existing save technologies, native
one-card recipes and existing science labs must be preserved.

Pay particular attention to newly added Beetlejuice (Secretas gold + Linox
rare earths) and Umbra (Tenebris chitosan + Vesta supermagnets + Linox
rare earths). Check the actual source recipe unlocks, factory ingredient
slots, real interstellar transport, and machine surface requirements in
Factorio. Registration now skips an optional recipe when no existing
crafting-category assembler can accept its ingredient count, and the
post-load audit independently checks that machine capacity. If source mod prototypes no longer match, fix or skip only the
optional recipe rather than forcing a substitute source mod.

Compare first-frontier Razi-owned direct Calidus-card costs against the
mod's previous values. The audit excludes Panglia native data-cell work:
a shorter Razi research total **does not** prove Nyxaris is faster in game.
Open the Galactic Operations Campaign tab and confirm it only advertises
installed multiplex recipes. Load a copied old save with normal and
multiplex crafting in progress, and compare recipe behavior after updating.

Run the existing manual local fixtures and the post-load data-raw audits:
```bash
lua5.2 tests/lua/test_system_card_manufacturing.lua
lua5.2 tests/lua/test_galactic_operations.lua
python3 -m unittest discover -s tests -p 'test_system_card_progression.py'
python3 -m unittest discover -s tests -p 'test_research_balance.py'
python3 -m unittest discover -s tests -p 'test_galactic_operations.py'
python3 scripts/audit_research_balance.py script-output/data-raw-dump.json --strict
```

No GitHub Actions jobs have been requested for this pass. Full pack startup,
live save compatibility, and actual UPS / logistics throughput remain untested.

## 2.1.67: Planetary supply roles and campaign evidence gate

**Static source changes, not a completed in-game certification.** The Galactic
Atlas now displays the actual installed shared-component technology associated
with an unlocked supplier world, the technology's live research status, and
the existing Cargo Network description. It does not create logistics, scan
inventories, reveal undiscovered worlds, or add save data.

The Campaign UI now displays direct pack totals for pending gateway research,
including live modded science mixtures. Check the shown totals against the
actual technology screen, including research-trigger technologies and labs.

The post-load research audit now prints direct system-card item demand for each
campaign stage and reports which *existing* laboratories accept every science
ingredient together. These are research costs, not the total recursive cost
of crafting precursor cards. The full-campaign auditor also produces a sorted
`planet_review_queue`: confirmed static discovery blockers first, uncertain
science or disconnected routes second, and remaining worlds last. A listed
geometric connection is not proof that a ship can actually travel it.

After loading the **complete** modpack, run the following locally using a
fresh prototype dump. No GitHub Actions job is needed:

```bash
python3 scripts/audit_research_balance.py script-output/data-raw-dump.json --strict
python3 scripts/audit_full_campaign.py script-output/data-raw-dump.json --output full-campaign-audit.json
lua5.2 tests/lua/test_atlas_industry_index.lua
python3 -m unittest discover -s tests -p 'test_research_balance.py'
python3 -m unittest discover -s tests -p 'test_full_campaign.py'
```

Inspect the planet review queue **world by world**, prioritising Panglia,
Moshine, Rubia, Linox, Crucible, Vesta and the native Aegis/Nexus endgame.
Try Off, Balanced, and Deep settings, then repeat with recommended mods
disabled. In Factorio, open Atlas on an unlocked Moshine and Panglia and
verify displayed supply roles against the Cargo Network; locked worlds
must not expose those roles. Compare research before and after completion
without reopening a save. Check the full science pack mixture against
the listed lab, actually craft all eight system cards, test the paired
gateway routes, and restore an old save with partially delivered
Convergence freight. Profile GUI open time and UPS before calling any
performance improvement proven.

## 2.1.63: Research and science balance release gate

1. Load the **complete Factorio 2.1 modpack** from scratch in Off,
   Balanced and Deep interdependence modes. Inspect technology and
   Factorio startup logs, not just individual Lua fixtures.
2. Confirm Solaris/Nyxaris, Vibrant/Vespera and Beetlejuice/Umbra remain
   independently researchable paired entrances, with reduced symmetric
   costs of 650, 1,200 and 1,600 units respectively. Outer Frontier
   Mastery costs 1,900 units.
3. Craft all eight ordinary system cards. Verify times of 10, 12, 16,
   22 and 28 seconds by tier; outer native science amounts double
   without doubling the predecessor system cards. Confirm the optional
   freight recipes still multiply the **final** ordinary recipe.
4. Verify 30 optional native-science weave candidates do not change
   any world's first-discovery requirements. Open an installed native
   lab for each *actual* combined research set, especially a technology
   receiving multiple native sciences. Test intentionally missing
   suppliers, missing laboratories and reversed source prerequisites.
5. Run the existing `/razi-audit` in-game and export a complete
   `--dump-data-raw` for `audit_research_balance.py`,
   `audit_tech_tree.py`, `audit_supply_chains.py`, and
   `audit_full_campaign.py`. The research report now detects
   card-manufacturing ingredient loops as definite errors.
6. Open an existing save with partially completed research and an
   earlier Convergence win. Confirm quest IDs, completed research,
   shipments, Mandates, laboratory entities and saved progress are
   preserved. Recheck the final victory path separately.
7. Compare early/middle/outer research pacing in a playable save, not
   only numerical unit costs. Real recipe producers, world surfaces,
   factory throughput and cargo travel still require playtesting.

Focused repository regressions (manual only):

```bash
lua5.2 tests/lua/test_research_tree_polish.lua
lua5.2 tests/lua/test_planetary_science_weave.lua
lua5.2 tests/lua/test_system_card_laboratories.lua
lua5.2 tests/lua/test_system_card_manufacturing.lua
python3 -m unittest discover -s tests -p 'test_research_balance.py'
python3 -m unittest discover -s tests -p 'test_planetary_science_weave.py'
python3 -m unittest discover -s tests -p 'test_system_card_progression.py'
```

No automatic GitHub Actions builds are enabled by this pass.
Full in-engine testing and real startup/performance benchmarks have
not yet been completed.

## 2.1.62: Original icon, machine and migration checks

Confirm five unique Convergence PNG icons render at normal and 150%
GUI scale. The five saved shipment IDs, count requirements and
old winners must remain unchanged.

After Ignition research, build one Calidus Stellar Frame, one
Outer-System Engineering Matrix and one Deep-Space Resonance Lens
in existing installed assemblers. Together the ingredient recipes
must consume all eight original system science cards. The final
Mandate requires one of each part. Confirm that no included source
ingredient exceeds the machine input-slot limit.

Load a 2.1.61 save with Ignition already researched. All three
component recipes should be unlocked after configuration changed
without changing force research or consuming cargo. Test a previously
won save separately, and verify the saved victory is not replayed.

Use the administrator-only `/razi-audit` to inspect all five Mandate
recipes, three component recipes, native labs and crafting-machine
compatibility. This checks loaded prototypes, but does not prove
the whole source-mod research graph is reachable.

Source/mock regressions, included in the manual-only Check workflow:
```bash
lua5.2 tests/lua/test_convergence_prototypes.lua
lua5.2 tests/lua/test_convergence_runtime.lua
lua5.2 tests/lua/test_convergence_audit.lua
python3 -m unittest discover -s tests -p 'test_convergence.py'
```
Full Factorio/modpack playtesting and performance benchmarks remain
outstanding.

## 2.1.61: loaded-modpack checks and regression status

**Available directly in Factorio:** With your full Factorio 2.1
modpack loaded, an administrator enters `/razi-audit`. The command
reports Convergence registration, each of its three research science
pack sets and whether at least one native laboratory accepts ALL of
them, the five actual `force.recipes` unlock states, real producer
recipe visibility, existing Dyson receiver count, native
crafting-machine category and ingredient-slot compatibility, and
direct research prerequisite cycles. Missing producer recipes are warnings rather
than proven softlocks because source mods may mine or generate items
scriptedly. It does not change unlocks or create storage rows.

**Run the pre-existing manual workflow only if a dedicated verification
pass is wanted:** GitHub Actions > Check > Run workflow. This workflow
is opt-in and now includes `tests/lua/test_convergence_audit.lua`,
`tests/lua/test_atlas_industry_index.lua`, Convergence inventory/merge
fixtures and the Python regression discovery alongside the existing
Factorio-mod-tools static checks. No workflow was triggered during
this change.

**Must still be performed on the real installed game:** A new-game
startup, import/upgrade of a previously won save, quest-to-recipe
craftability and source research graph reachability, multiplayer
force merges during the final twelve-second transmission, GUI scaling
and FPS/UPS comparison before/after 2.1.61. A prototype being present
and a production recipe listed does not prove the source planet is
reachable. No Factorio executable/full modpack/save was present during
development, so these gameplay and speed measurements remain unknown.

**Performance verification:** Profile the Galaxy Atlas while opening
many different worlds, rather than inferring UPS gains from source
changes. The prototype-to-industry index is cached per script session,
with actual per-force research/visibility checked on every inspection.
A normal Convergence run performs no audit work unless an administrator
explicitly runs the command. The transceiver safeguard stops counting
entities for forces whose gate research is already complete.

```bash
lua5.2 tests/lua/test_convergence_audit.lua
lua5.2 tests/lua/test_atlas_industry_index.lua
lua5.2 tests/lua/test_convergence_prototypes.lua
lua5.2 tests/lua/test_convergence_runtime.lua
python3 -m unittest discover -s tests -p 'test_convergence.py'
python3 -m unittest discover -s tests -p 'test_galactic_operations.py'
```

## 2.1.60 release gate: responsive finale and full research reachability

**UI:** Compare Galactic Operations at 1024x768, 1280x720, 1600x900,
1920x1080, and higher display scaling (especially 1.25 and 1.5).
Five array sections must switch to three/two columns before tile
labels or partial-progress meters create horizontal scrolling. Deliver
3 of 8 Stellar Mandates and verify both the local and overall meters
advance before the stage is complete. Confirm each module's color and
native Mandate item icon displays without stretching.

**Research and crafting:** From a new post-transceiver save, inspect
Commission, Synchronization, and Ignition before and after research.
The next-action panel must report the actual missing ForceTechnology
prerequisite and actual `force.recipes` unlock status, never claim
that researching a technology fabricated inventory or gave production.
Verify that the real complete modpack has *at least one* native lab
for each finale science recipe, a valid producer and legal recipe
unlock for every required Mandate input, and no prerequisite loops.
Inspect the data-raw dump with the existing campaign and supply-chain
audit scripts. Read any advisory warnings, especially scripted source
content that cannot be inferred from technology effects.

**Codex:** While Stellar/Industrial/Deep Space/Pulsar/Final deliveries
are active, the Expedition Priorities panel must label them as
delivery objectives rather than newly researchable technologies.
During the 12-second final transmission it must identify the pending
signal instead of recommending the Ignition technology again. Other
available star-frontier research remains selectable in parallel.

**Deep Space Atlas:** On discovered Solar System Edge, Shattered Planet,
Nexus, Deep Space Edge and Black-Hole Approach, inspect the briefings
and their direct Finale console button. A locked or missing source
destination must not reveal descriptions or fabricate an itinerary.
Existing source routes, asteroid hazards, Nexus boss progression and
space platform schedules must remain unchanged.

**Save recovery and multiplayer:** Run a reload between partial
shipments and a reload at each transmission beat. Merge two active
forces with different recorded source platforms and contributors;
the older accepted signal must win exactly once and retain the
correct archive details. Test an older, already-won save separately.
No background polling when the pending-transmission table is empty.

Checks available in the repository (not executed automatically):
```bash
lua5.2 tests/lua/test_convergence_prototypes.lua
lua5.2 tests/lua/test_convergence_runtime.lua
lua5.2 tests/lua/test_razi_journal_guidance.lua
python3 -m unittest discover -s tests -p 'test_convergence.py'
python3 -m unittest discover -s tests -p 'test_galactic_operations.py'
python3 -m unittest discover -s tests -p 'test_razi_journal.py'
```

## The Convergence transmission, source Dyson and save safety (2.1.59)

- With a recognisable native Dyson energy receiver item/entity installed,
  the last delivery must fail **without consuming cargo** until the same
  force owns at least one placed receiver. The live count is the
  engine-maintained `get_entity_count`; no surface search and no invented
  satellite/energy telemetry. In incompatible source combinations where
  no receiver entity can be identified, this physical gate is skipped
  rather than permanently blocking a save. Native Dyson research
  prerequisites still apply.
- Deliver the final Ignition Mandate and confirm exactly one item is
  consumed and the 12-second four-beat sequence starts. The win screen
  must not appear immediately. The player may disconnect or save at
  3, 6 and 9 seconds without losing or duplicating a beat. At the
  12-second mark the original Factorio ending appears with Continue.
- Repeat using two multiplayer forces. Only the force that delivered
  the final mandate should get the force-wide signal updates. Merging
  forces mid-sequence should retain one active sequence and yield one
  victory. Reload a 2.1.57/2.1.58 already-won force: the victory must
  remain complete without starting a transmission or asking for receivers.
- Inspect Galactic Operations at 1024px, 1280px, 1920px and ultrawide
  resolutions. The construction tracker should wrap from five to
  three or two columns; progress bars, real receiver count, in-progress
  beats and shipment details must stay readable without horizontal
  scrolling.
- Performance: Confirm the one-second event touches only pending
  forces and only redraws Convergence windows when a beat changes.
  The code must not poll satellite state, generate worlds, change source
  ship schedules or allocate an entity/particle every tick.

Mock/source checks:
```bash
lua5.2 tests/lua/test_convergence_runtime.lua
lua5.2 tests/lua/test_convergence_prototypes.lua
python3 -m unittest discover -s tests -p 'test_convergence.py'
python3 -m unittest discover -s tests -p 'test_razi_journal.py'
```

## The Convergence: five-stage validation (2.1.58)

**Tech graph:** Commission must unlock only Stellar/Industrial recipes;
Synchronization must unlock Deep-Space/Pulsar Resonance recipes;
Convergence Ignition Protocol alone unlocks the final accord.
Check research cost and preconditions in source Dynamo/Dyson and Aegis
combinations, including missing Nexus Omega Lab. Never create a lab.
Inspect that the optional installed native supplies are genuinely
manufacturable before a release, and that the final mandate's eight
card families are accessible without a technology cycle.

**Runtime progression:** 8 Stellar -> 10 Industrial -> 6 Deep Space ->
4 Pulsar Resonance -> 1 Ignition. First three stages alone must NOT win.
Fourth stage cannot win. The fifth should win exactly once after
its own research. Keep Remote View and invalid/platform-owning force
checks; wrong stage and missing items must not consume anything.

**Saves/migrations:** Load a completed 2.1.57 save and confirm
M.current reports finished, both new shipment milestones count as
completed for that previously won force, and the native victory
does not replay on load. On a partial 2.1.57 save, existing deliveries
are untouched. Verify newly installed recipe unlocks are enabled only
if their corresponding research is already complete. Force merges
must preserve earlier and new contributions, never resetting the
source game's science tree.

**UI:** Confirm five stage bars, carried counts, and research guidance
on 1024px to 4K UI scaling. The user must be physically aboard a
force-owned expedition platform to submit freight. No inventory scans
or heavy physics polling should be introduced.

Source-level fixtures (run locally without new Actions workflows):
```bash
python3 -m unittest discover -s tests -p 'test_convergence.py'
python3 -m unittest discover -s tests -p 'test_razi_journal.py'
lua5.2 tests/lua/test_convergence_prototypes.lua
lua5.2 tests/lua/test_convergence_runtime.lua
lua5.2 tests/lua/test_razi_journal.lua
```

## The Convergence: release blocking tests (2.1.57)

**Phase gating and panel:** Convergence Commission must unlock ONLY Stellar
and Industrial Mandates; Deep-Space Synchronization must unlock the
Deep-Space Mandate crafting recipe. Check old saves with commission
researched but synchronization pending, and old saves where the
final mandates were already fabricated. Previously delivered cargo
must survive unchanged. In Galactic Operations inspect a zero-cargo
stage, partial and complete progress bars, active/pending status, and
the cargo counter as items move in and out of the character inventory.
The Submit button must never enable in Remote View or without cargo.
Opening the panel must not initiate a repeated background scan.

## The Convergence: release blocking tests (2.1.56)

**Factory/prototype:** Load the complete Factorio 2.1 pack and confirm
the three Convergence recipes, the two commissioning technologies and
each required source material have real producers and sensible unlocks.
Verify original card recipes and native K2SO transceiver remain intact,
and at least one installed *reachable* laboratory researches the
complete science for both Convergence technologies. Test without Dyson,
Aegis and Nexus installed to ensure optional research requirements
cannot create a circular dependency or an impossible endgame. Without
Nexus Omega Lab, the final authorization may use the existing outer
science pair, while the physical Deep Space Mandate still requires
the actual Deep Space card.

**Physical cargo:** On a real force-owned space platform stopped at
Solar System Edge, carry 3 Stellar Mandates, submit them, then carry
and submit the remaining 5. Verify the 8-item stage completes, the
entire input is consumed and force members see the same progress.
Verify remote map view (even while the physical character is already
on the platform) and an unrelated planet cannot submit cargo.
Repeat for 10 Industrial and 6 Deep-Space Mandates. Test save/reload
between partial submissions and multiple force merge events. Make
sure unrelated players' cargo and other forces' victory state are
untouched.

**Win conditions:** Final Deep-Space Mandate delivery must be rejected
without Synchronization research, without the first two stages, or
from a planet. Completing research alone must never win. A save which displayed an
old victory before the update should re-arm the game state only at
the real final submission, then show the new ending. On the
last accepted real cargo, Factorio's native victory UI should show
The Convergence and offer Continue. Test existing saves in which the
transceiver was already activated. Confirm the K2SO transceiver's
original victory and Space Age's Solar System Edge victory are both
suppressed using their supported remote interfaces on new-game init
and save configuration updates. Reaching the edge should no longer
claim the new victory before the physical manifests are delivered.

**Performance/compatibility:** No per-tick inventory scan, route
overrides, new planet, lab entity or source platform schedule changes.
The first Convergence Codex viewing should not allocate empty
save-state records. Validate in multiplayer and inspect logs for
omitted source products or missing science-compatible labs.

Local tests (no unnecessary GitHub Actions):
```bash
python3 -m unittest discover -s tests -p 'test_convergence.py'
python3 -m unittest discover -s tests -p 'test_razi_journal.py'
python3 -m unittest discover -s tests -p 'test_galactic_operations.py'
lua tests/lua/test_convergence_prototypes.lua
lua tests/lua/test_convergence_runtime.lua
```

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
the Clear search action. Repeat with a non-English game locale. Confirm
localized search updates continue to arrive through the Galactic Operations
translation handler. Native platform schedules, hub cargo and surfaces must
remain unchanged. This verification requires a real Factorio runtime.

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

## 2.1.85: Planet Athos full-pack recursion resolution

The 2.1.83 Linux engine log captured an actual crash at 91.620 seconds,
not a long normal startup. Athos 1.1.3 dumped 1,757 technology nodes in
its data-updates traversal. Offline graph analysis found two strongly
connected cyclic components (19 Muluna/Space Science nodes and 18
Nyxaris/Apia/Aquilo nodes). The 2.1.83 pre-update Athos guard correctly
reported but did not repair those non-Athos cycles.

The 2.1.85 guard is still **source-restricted by default**, with exactly two
additional verified bootstrap rules applied ONLY if their named child,
prerequisite and every required witness occur in the SAME detected cycle:

- `space-platform-thruster -> space-science-pack`: remove this backwards
  requirement so the ship can reach Muluna before Muluna produces the
  technology required to research Space Science. Muluna's existing science
  production prerequisite remains untouched.
- `nyxaris-discovery -> lithium-processing`: remove the backwards Aquilo
  science requirement so Nyxaris precedes Vibrant and Aquilo as designed.

A separate test fixture simulates both cycles, verifies both cuts, confirms
that space-science still depends on Muluna, checks no additional progress
research gets removed, and proves unrelated cycles are not silently
modified. Offline replay of the crash graph removes both strongly-connected
cycles. Real Factorio startup and full-save testing remain required.

## 2.1.86: Secretas Golden Science bootstrap cycle

The 2.1.85 engine startup passed Athos's recursive technology dump and reached
the game engine's own cycle validator, which rejected
`golden-science-pack -> steam-recycler -> golden-science-pack`.
Razi's `prototype_sanity.lua` caused one direction by unconditionally
appending `steam-recycler` to Golden Science's prerequisites.

Secretas's original technologies have the reverse **production** relationship:
mining spaceship scrap triggers Steam Recycler, which unlocks the gold plate
recipe; crafting 20 gold plates triggers Golden Science. To preserve that
original source behavior, Razi 2.1.86 first removes an externally injected
`golden-science-pack` prerequisite from `steam-recycler`, verifies source
triggers and the gold plate unlock, then safely keeps the forward
`golden-science-pack -> steam-recycler` requirement. If a longer reverse
research path survives, it omits the Razi gate instead. All unrelated native
Secretas discoveries, technologies, recipe unlocks and triggers remain intact.

Repeat on a copied save with a real Factorio 2.1.21+ executable. The source
and static assertions are not a substitute for a complete full-modpack load.

## 2.1.87: Outer star map visual release checks

After loading the entire modpack, open the fully zoomed-out starmap and
verify: Ferrum is on Beetlejuice's west with only its Slip Stream spur;
Obsidiax is on Umbra's Vesta-side exterior without a second crossing;
Shchierbin is clearly separate from Vibrant's entrance and remains beyond
the physical belt; Athos is near Vulcanus with no diagonal through the
Solaris gateway. Confirm no residual red dotted tails beside Carna or
Velora, and no long prose appears as a waypoint name. Route identities
are selectively preserved for schedules; players with preexisting
Ferrum/Obsidiax routes should check existing schedules on a copied save.

## 2.1.88 red dotted trail source remediation

User's 2.1.83 full-pack Factorio log confirms `orbital-cannon 0.15.0` is
enabled. Orbital Catapult explicitly generates its own space-map graphics,
independent of Razi's earlier route-highlight and PlanetsLib orbit renderers.
Version 2.1.88 removes Catapult-owned sprite atlas layers at the very end of
Razi's `data-final-fixes.lua`, removes untagged old Carna/Velora orbit
art, and trims nearby vivid-red Razi overlay strokes defensively. It does
not remove `orbital-cannon-link` prototypes, native `space-connection`
routes, orbit metadata, planet graphics, or transport gameplay.

Check Factorio's log for `Final red-trail cleanup: removed ...` then
view Carna and Velora at both close and distant zoom. If any red trails
remain, capture the **new Factorio log** as the actual late renderer may
be drawing from another mod namespace. Do not indiscriminately remove
planet art or disable the transport mod.


## Razi 3.0 second-pass audits

Use a complete post-data-final-fixes Factorio `data.raw` JSON export before
interpreting recipe-navigation or technology results:

```sh
python scripts/audit_crafting_navigation.py --dump-data-raw loaded-data-raw.json --json
python scripts/audit_tech_tree.py --dump-data-raw loaded-data-raw.json --json
python scripts/audit_research_balance.py --dump-data-raw loaded-data-raw.json --json
python scripts/audit_campaign_consistency.py
python tools/journal_locale.py
python -m unittest tests.test_razi_3_0_first_pass tests.test_razi_3_0_second_pass tests.test_galactic_tech_audit
```

**Audit limitations:** source recipe grouping is display-only. The recipe
audit validates name and ingredient/product shapes but cannot prove that
the full modpack starts, that an assembled machine can craft a recipe or
that a factory can ship enough goods. The tech audit's new missing-science
and missing-unlock checks run only when item or recipe tables exist in
the export. Treat unusual source mods as advisory until verified live.

Required smoke checks: original save + clean save, optional mod disabled,
each corporate record unlocked after genuine research, related-planet links
open correct dossiers without changing completion, barrel tabs don't hide
native recipes, and perishable option disabled by default.

## 3.0 third-pass factory validation

The source-native exchange guard rejects source recipes with non-deterministic,
range-based or missing result amounts *before* multiplying native batches.
This prevents malformed optional recipes without changing original content.
The Cargo Network portfolio reads actual technologies and loaded recipes.

```sh
python -m unittest tests.test_razi_3_0_third_pass tests.test_razi_3_0_second_pass tests.test_razi_3_0_first_pass
python scripts/audit_campaign_consistency.py
python tools/journal_locale.py
python tools/factory_review.py --dump-data-raw loaded-data-raw.json --json
```

Also run `tests/lua/test_razi_industry_portfolio.lua` in the Lua
regression runner and the full existing exchange suite. Live Factorio
engine startup and save migration remain mandatory before release.

## Razi 3.0 fourth-pass validation

```sh
python -m unittest tests.test_razi_3_0_fourth_pass tests.test_exchange_economy
python -m unittest discover -s tests -p 'test_*.py'
python scripts/audit_campaign_consistency.py
python tools/journal_locale.py
python tools/factory_review.py --dump-data-raw loaded-data-raw.json --json
python scripts/audit_freight_break_even.py --dump-data-raw loaded-data-raw.json --json
```

Also run `tests/lua/test_planet_production_exchanges.lua` from the
repository root with Lua and execute your usual full Lua regression suite.

The machine ingredient-capacity guard must reject a recipe with more
distinct input types than the only compatible machine can accept. It must
allow a recipe that fits exactly and continue accepting machines without
an explicit limit. The original native recipe must remain unaffected.

Compare recipes in the real Factorio craft menu after researching their
native and optional technologies. The Cargo Network should show the
true deterministic craft output, without implying shipping has occurred.
Open a partnership's existing Journal dossier and confirm no GUI scroll
position regression.

The new freight report is **scenario math**, never authoritative
shipping telemetry. Check its missing-price and missing-route handling,
and reject a positive-looking scenario when native ingredients have been
removed. Test multiplayer force research and old saves before release.

## Razi 3.0 Pass 06: source-backed value and midgame guardrails

The Cargo Network portfolio can show fixed gross output gains, up to two
additional per-craft inputs and the first real unmet research prerequisite
for first/middle-frontier factories. These are read-only comparisons and
must not be mistaken for transport savings or completed deliveries.

```sh
python -m unittest tests.test_razi_3_0_sixth_pass
python -m unittest discover -s tests -p 'test_*.py'
python tools/factory_review.py --dump-data-raw loaded-data-raw.json --json
python scripts/audit_frontier_pacing.py --dump-data-raw loaded-data-raw.json --json
luatex --luaonly tests/lua/test_razi_factory_comparison.lua
luatex --luaonly tests/lua/test_razi_industry_portfolio.lua
luatex --luaonly tests/lua/test_planet_production_exchanges.lua
```

Run Lua checks at the repository root (a local Lua interpreter works too).
Focused comparison and Cargo portfolio tests passed with Lua 5.3 and
exact Git-blob matches;
the other listed tests still need execution against this commit, as do
Factorio startup and migrated-save smoke checks.

Verify that a blocked technology names an actual prerequisite, that missing
source mods hide rather than invent the value comparison, and that clicking
a card still opens its original Journal quest without scroll regressions.

## Razi 3.0 Pass 07: middle-frontier validation

```sh
python -m unittest tests.test_razi_3_0_seventh_pass -v
python -m unittest discover -s tests -p 'test_*.py' -v
python scripts/audit_midgame_partnerships.py --dump-data-raw loaded-data-raw.json --json
python tools/factory_review.py --dump-data-raw loaded-data-raw.json --json
```

On GitHub, the existing **Actions > Check > Run workflow** step remains
manual-only. It includes Lua tests for both source-backed factory value
and optional factory portfolio ordering, plus the broader original
exchange and Python discovery suites. Never infer a passing run merely
because the workflow file is updated.

Check source-mod absence, native output provenance, extra batch-import
quantities, preservation of original native ingredients, technology
unlock effects, science lab compatibility, and prevention of late
Beetlejuice/Umbra requirements in midgame factory technologies.

Within Factorio, verify paired Fulgora/Aquilo and Paracelsin/Rubia
optional recipes against actual production, physical freight needs and
an existing save. The Cargo Network's original recipe label must be
truthful, and its journal links must not lose scroll position.

## Razi 3.0 complete story, archive and ending regression

The 25 corporate cases are gated by the real Expedition Journal quest
completion state; the original 15 transmission IDs are unchanged.
The five Convergence shipment files unlock only with accepted physical
cargo. The epilogue is reserved for actual winning state, not ignition
research or arrival at the edge.

```sh
python scripts/audit_campaign_consistency.py
python tools/journal_locale.py
python -m unittest tests.test_razi_3_0_story_pass tests.test_razi_3_0_first_pass
python -m unittest discover -s tests -p 'test_*.py'
lua5.2 tests/lua/test_razi_story_dispatch.lua
lua5.2 tests/lua/test_convergence_runtime.lua
lua5.2 tests/lua/test_razi_journal.lua
```

Test both fresh saves and saves with research already completed. A save
reload must not send retrospective notifications. A 20+ research
burst should result in one digest, not repeated messages. Test
separate/muted clients on the same force, disconnected players, optional
world research with unlock-space-location effects, merged forces and
delivered stages. The force's genuine winning screen must show the
ending while Factorio still allows continuing the game.

**Do not ship on static validation alone.** The full Lua/Python suites,
actual modpack load, GUI layout, multiplayer and old-save verification
remain required unless explicitly logged as completed.

## 3.0 default-on spoiler protection

```sh
lua5.2 tests/lua/test_razi_spoiler_fog.lua
lua5.2 tests/lua/test_razi_project_spoilers.lua
lua5.2 tests/lua/test_razi_journal.lua
python -m unittest tests.test_razi_spoilers -v
python -m unittest discover -s tests -p 'test_*.py' -v
```

Additional live Factorio checks:

- New map defaults to **Hide Spoilers ON** without manual clicks.
- Unreached quest/chapter/archive titles are not leaked through
  browsing, searching, opening an old pinned quest, or selecting
  the chapter drop-down. Completed pages remain readable.
- Native research screen conceals Razi-owned future technologies and,
  when the expanded switch is ON, unresearchable external technologies.
  Research a prerequisite and confirm its successors become available.
  Disable the expanded switch and verify every source-owned technology
  restores its prior enabled/visibility state.
- Turn Hide Spoilers **OFF** and verify all Razi-managed technologies
  restore original enabled/visibility settings, including old saves.
  Toggle **ON** again and verify consistent research gating.
- Multiplayer: shared map setting changes must apply to all forces;
  personal story dispatch muting remains separate.
- Old saves containing researched technology, physical Convergence
  deliveries and completed campaign victories must retain progress.
- Ensure large cheat-research bursts and normal progress still
  re-enable the right descendants, without per-tick tech scans.

**Scope:** Factorio Lua can hide disabled research by setting
`visible_when_disabled=false`. The safe implementation restricts
runtime fog to the technologies' real prerequisite chains. The optional
expanded switch also conceals future external technologies, restoring
prior per-force states when disabled. Full-modpack validation is still
pending until executed.

## Startup, global research spoilers and complete settings styling

```sh
python -m unittest tests.test_razi_spoilers tests.test_razi_settings_welcome
lua5.2 tests/lua/test_razi_spoiler_fog.lua
lua5.2 tests/lua/test_razi_welcome.lua
lua5.2 tests/lua/test_razi_journal.lua
python -m unittest discover -s tests -p 'test_*.py'
```

Check all 59 Razi setting names in English and the existing Russian
localization. Every setting label has a restrained category heading
or colored continuation marker; all settings have descriptions.

Research test: load required Factorio 2.1/K2SO and representative
optional planets. With Hide Spoilers and expanded research spoilers ON,
locked future Razi and external technologies disappear from the native
research UI. Already researchable technologies, even red science or a
source-mod's first research, must remain accessible. Research their
prerequisites and verify successors appear immediately. Switch off the
external control without turning off Journal protection and confirm
that all external enabled/visible states restore. Switch off the main
control and verify all Razi-managed states restore. Test scripted
`/razi-cheat` research, disabled-by-source technologies, technology
cycles, multiplayer force merges and old saved games.

Startup test: a **new map** temporarily prints source-mod notices, then
optionally clears each player's console once and shows a compact localized
welcome. Factorio's `clear_console` API cannot delete specific mod
messages, so a warning such as Muluna's fluidbox advisory may also be
removed. Test `razi-clean-startup-chat=false`, normal player chat,
returning players and mature saves. No delayed clearing may occur after
the startup window. Test `/razi-welcome` replay and personal welcome mute.
The combined Check workflow remains manual-only.

## Rubia research placeholders and welcome verification

```sh
lua5.2 tests/lua/test_razi_rubia_spoilers.lua
lua5.2 tests/lua/test_razi_spoiler_fog.lua
lua5.2 tests/lua/test_razi_welcome.lua
python -m unittest tests.test_razi_spoilers -v
```

A fresh or migrated Factorio 2.1 save with Rubia installed must be
tested after a real mod reload. Under Settings > Mod settings > Map
leave **Hide Spoilers** and **Also hide future technologies from other
mods** both ON. The `rubia-unknown-technology-*` question-mark
placeholders should not appear in the research grid while their real
counterparts remain unavailable. Research or reverse Rubia stages and
verify legitimate successor science is still visible. Repeat after
mod migration, `on_technology_effects_reset`, and toggling the
expanded option OFF and ON.

The welcome code is only in `feat/razi-3.0`, not the published release
branch. Installing the GitHub commit alone does NOT change the mod that
Factorio has already loaded. After installing the updated 3.0 build,
fully reload the game. `/razi-welcome` prints the new welcome;
`/razi-welcome clear` explicitly erases all of the requesting player's
current console messages and prints the new welcome. It is destructive,
not a selective filter for Rubia, Nexus or Muluna messages. Their
independent startup notices may still appear again if their own mods
print them later.

## Orbital Catapult required local corridors (3.0)

```sh
lua5.2 tests/lua/test_orbital_catapult.lua
python3 -m unittest tests.test_razi_orbital_catapult
python3 scripts/audit_campaign_consistency.py
python3 -m unittest discover -s tests -p 'test_*.py'
```

For a full in-game test, install Orbital Catapult **0.15.0+** plus its
`powered-machine` dependency, with Razi's `~` load-order-independent
requirement. Confirm Factorio 2.1 loads without a dependency cycle.
Verify Muria, Rubia and Aquilo form three **bidirectional** local
catapult corridors at the correct starmap positions and that:
1. The original Muria-Aquilo two directed IDs survive migrated saves.
2. Normal platform routes, asteroid difficulty and existing research
   prerequisites are unchanged.
3. Only **actually discovered** planets become usable via the source
   mod's own target gating; travel must not grant discovery research.
4. Surface placement, electricity, transported items, player travel,
   source requests/circuit operations and receiver inventory work.
5. Turning the startup toggle OFF and restarting removes Razi's six
   links without removing third-party links or any source technology.
6. A source planet missing in a fixture skips only its affected
   catapult links, without generating invalid custom prototypes.
7. Journal dossiers accurately describe available short-haul lanes
   without claiming the player has transported any cargo.

No full Factorio engine/old-save tests were executed while authoring
this patch. These must pass before public merging.

## Vespera regional freight UI integration

```sh
lua5.2 tests/lua/test_orbital_catapult.lua
lua5.2 tests/lua/test_razi_catapult_network.lua
python3 -m unittest tests.test_razi_orbital_catapult tests.test_razi_catapult_network -v
python3 -m unittest discover -s tests -p 'test_*.py' -v
```

**Source tests:** three bidirectional links, no duplicate names,
correct native discoveries, safe handling of absent planet prototypes,
OFF startup option, OFF spoiler setting, no invented shipments, and no
scheduled runtime scanning.

**In-game verification (still required):** check Cargo Network at early
Muria progression with Hide Spoilers ON. Unexplored Rubia and Aquilo
should remain unnamed; after native planet discovery research, exactly
one additional corridor should appear per valid discovered pair. With
spoilers OFF, display all installed pairs but correctly label their
research as outstanding. Open each planet's Journal dossier and confirm
the listed neighbors match Cargo Network. Check narrow-screen layouts,
tooltip/localization, old saves and game multiplayer.

The transport source is authoritative: physically construct and power
both catapult endpoints and test target selectors, electricity, cargo,
item filters/circuits, player transport, native arrival conditions and
normal space-platform behavior. Neither the dossier nor source checks
prove the actual transport operates.

## Orbital Catapult: cross-system local network expansion

```sh
lua5.2 tests/lua/test_orbital_catapult.lua
lua5.2 tests/lua/test_razi_catapult_expansion.lua
lua5.2 tests/lua/test_razi_catapult_network.lua
lua5.2 tests/lua/test_razi_catapult_regional.lua
python3 -m unittest tests.test_razi_orbital_catapult tests.test_razi_catapult_network tests.test_razi_catapult_expansion -v
python3 scripts/audit_campaign_consistency.py
python3 -m unittest discover -s tests -p 'test_*.py' -v
```

Source checks cover six two-way corridors, the first six old link
IDs, three new locally adjacent regions, missing prototype guards,
the independently reversible `razi-orbital-catapult-regional-links`
startup setting,
original and new startup settings independently, and no unwanted
space connection, technology or recipe changes.

In-game Factorio checks are still required for all six pairs:
Vulcanus–Castra, Gleba–Moshine, Muria–Aquilo, Muria–Rubia,
Rubia–Aquilo and Rubia–Maraxsis. Test that physical catapults on both
ends actually launch/receive cargo and players with source energy
requirements, do not bypass intended planet-discovery gates, respect
native transport restrictions and coexist with normal platform routes.
Pay special attention to Maraxsis's possible surface limitations.

Test old saves, new saves, spoiler ON/OFF, both startup switches in
all four combinations, absent optional worlds and multiplayer.
The Razi Journal should list available local routes under their
correct star systems while concealing undiscovered neighbors.

**No full-modpack Factorio startup or old-save migration is claimed**
merely from static source checks or committed test fixtures. The
GitHub Check workflow remains manual-only.

## Real regional Freight Desk planning

```sh
lua5.2 tests/lua/test_razi_freight_orders.lua
python3 -m unittest tests.test_razi_freight_orders -v
python3 -m unittest discover -s tests -p 'test_*.py' -v
```

In-game: open Projects → Cargo Network on an established save with
Orbital Catapult installed, both corridor switches ON and planet
research complete. Verify both directional selectors show on each
valid discovered route; item selection uses the native Factorio item
picker; quantities must be positive whole numbers at most 1,000,000.
Check real stack-size calculation and player-carried item counts,
especially if item stack size has been modified by another mod.
Try 21 orders, invalid inputs and no item. Verify manual packed/unpacked
and delete actions. Test save/load persistence, two different players,
player removal, toggling each startup corridor group and Hide Spoilers
ON/OFF. No save should ever gain free cargo or a fake completion flag.

The board **does not** count actual launches, receiver inventory or
transported goods. Checking a manual packed order must never mark
Convergence progress or invoke Orbital Catapult methods. Test the
entire modpack and old-save GUI layout before public release.

The manual-only GitHub Check workflow now includes
`tests/lua/test_razi_freight_orders.lua`; its execution and full
Factorio startup are not implicitly confirmed by a GitHub commit.
