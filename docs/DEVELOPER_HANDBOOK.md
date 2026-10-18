# Razi Protocol: developer handbook

> **Purpose:** Explain *why* this mod exists and the standards used when changing it. For the current implementation, inspect code, `info.json`, and tests. Historical changelogs and older design documents can describe superseded behavior.

## North star

Razi Protocol is a curated, multi-system **Factorio 2.1 Space Age campaign** built around the Krastorio 2 Spaced Out ecosystem and a large collection of authored planet mods. It should feel like a long expedition with memorable systems, distinct destinations, discoveries that change the factory, and a real ending.

The goal is **not** to collect the largest possible mod list, add busy visuals, or make every recipe arbitrarily complicated. The goal is to create a world where travel, research, logistics, construction, exploration, and story reinforce each other.

An ideal player remembers *why* a world was worth visiting, *what* they learned there, and *what* that unlocked in another system.

## Non-negotiable design invariants

1. **Source mods own their content.** Preserve their real planet, research, recipe, enemy and production mechanics unless a deliberate, documented compatibility patch is required. Use their actual prototype identifiers. Never fabricate missing content to make a journal entry appear.
2. **Progression is meaningful, not circular.** Moving powerful research into later systems is intentional, but every required technology must remain reachable with available labs, science, routes and prerequisite technologies. Optional worlds must not silently become mandatory.
3. **Travel routes are gameplay.** Keep the starmap legible and visually plausible. Danger, asteroid exposure and deliberate crossings should communicate real route properties. Do not draw fake links or inadvertently bypass intended bottlenecks.
4. **Narrative is honest.** Journal quest completion tracks real research/discovery; the Projects reader must separately represent real construction, shipping and endgame state. Flavor writing may interpret events, not fabricate player actions.
5. **Save compatibility comes first.** Avoid renaming stable quest IDs, setting names, technology prototypes, locations and persisted project keys without migration. Test old saves after large topology changes.
6. **Performance is a feature.** Prefer load-time/precomputed data, bounded UI work, guarded optional features and explicit settings for heavyweight behavior. Default-off optional optimizations must not alter gameplay without consent.
7. **Quiet visual hierarchy.** Distinct system identity without decorative overload. Native Factorio readability and accessibility outrank ornament. Every color, arc, icon and line needs a purpose.
8. **Compatibility should fail soft.** Absent optional sources or renamed technologies must skip only the affected feature where feasible, never crash the entire campaign. Required dependencies should be explicit.
9. **Test intent, not only syntax.** A green static test does not prove that a new run can research every tier or that a planet appears at a sensible position. Build fixture tests and run visual/in-game checks.
10. **Respect contributors and upstream authors.** Maintain attribution, avoid copying unlicensed mod textures/code and document why overrides exist.

## The intended player journey

| Phase | Experience and developer responsibility |
| --- | --- |
| Nauvis / Calidus | Establish automation, energy, logistics, chemistry and a capable platform. Early objectives teach purpose rather than bury players under tutorial popups. |
| First frontiers / Solaris and Nyxaris | Industrial worlds and living worlds should play differently and introduce real interdependence. Support multiple sensible choices where the tech graph allows them. |
| Middle systems / Vibrant and Vespera | Electricity, asteroid corridors, cold logistics, remote industry and distinct branch worlds increase the demands on ships and factories. |
| Outer systems / Beetlejuice and Umbra | Material specialization, hazard preparation and advanced engineering should reward accumulated mastery. |
| Great projects | Dyson work, cargo networks and the Transceiver represent sustained construction/production, not merely clicking research. |
| Finale | Deep Space and the Convergence sequence should close the expedition with measurable physical achievements and a clear narrative payoff. |

The seven main systems are a campaign framework; the journal also has thematic chapters for fleets, science, trade, outposts, defense, industry and recovered transmissions. Do not confuse chapter count with system count.

## Map and route design

- A system should have visual breathing room: legible orbit spacing, concise labels, intentional approach paths and no arbitrary overlapping or doubled routes.
- Planet positions and connections must be checked together. Moving a location may affect science categorization, route hazards, starmap artwork, journal prose, train-like platform schedules and prior saves.
- The authored asteroid-belt/divide design should have an understandable approach, a deliberate crossing, and no unintended shortcuts through the belt graphic.
- Route overlays reflect finalized route hazard data, not cosmetic fabricated difficulty. Keep the renderer free of per-tick draw work and follow [Art Direction](ART_DIRECTION.md).
- Distinguish required campaign passages from optional offshoots. Prefer a memorable route network to one giant tangle of near-identical connections.

## Science, technology and economy

The player should progressively need factories on several worlds. Late research can require earlier offworld science or products, including moved vanilla/K2 technologies when safely supported. Follow [Distributed Technology](DISTRIBUTED_TECHNOLOGY.md).

Before editing a dependency:
1. Identify the original technology, all prerequisites, science packs, recipes it unlocks and first machine capable of crafting those packs.
2. Establish that a route and a laboratory exist before the first required use.
3. Check for cycles, unavailable optional planets, duplicate/moved unlocks and old-save researched states.
4. Define the fallback for missing mods or startup settings.
5. Validate on the expected pack and on at least one intentionally reduced optional-mod combination.

Cross-world manufacturing should reward logistics with distinct industry, not just import chores. Respect the original recipes and ownership boundaries. See [FluxWorks](FLUXWORKS_INDUSTRY_ATLAS.md).

## Expedition Journal, projects and fiction

The **Expedition Journal** is the unified player-facing narrative surface: **Quests**, **Projects**, **Journal**. Keep it helpful, readable and restrained.

- Quests use actual technology/discovery/boss state. IDs live in `scripts/razi_journal_data.lua` plus frontier, expansion, industry and optional companion modules.
- Projects represent large real-world operations and should never auto-complete merely because a research entry did.
- Recovered transmissions are fiction unlocked by a linked milestone, not a second hidden tech tree.
- A chapter needs a premise, a useful briefing and a reason its quests belong together.
- Preserve the difference between authorial voice (story), player instruction (field note) and achievement evidence (runtime state).
- Stable localization keys are contracts. For writing and translating use [Localization](LOCALIZATION.md).
- UI rebuilding should preserve navigation state where appropriate. Never introduce per-tick scans or unbounded widgets for the sake of atmosphere.

See [RAZI Industries](RAZI_INDUSTRIES.md) for the corporate narrative pilot,
planetary industry briefs, safe crafting-group work and team authoring rules.

## Engineering map

| Concern | Primary starting points |
| --- | --- |
| Mod manifest and dependencies | `info.json` |
| Journal runtime and UI | `scripts/razi_journal.lua` |
| Quest definitions | `scripts/razi_journal_data.lua`, `scripts/razi_journal_expansion.lua`, `scripts/razi_journal_frontier.lua`, `scripts/razi_journal_industry.lua` |
| Optional workshop objectives | `scripts/razi_journal_fluxworks.lua` |
| Recovered lore | `scripts/razi_journal_records.lua`, `locale/en/razi_journal_transmissions.cfg` |
| Starmap risk lines | `prototypes/system/route_highlights.lua` |
| User settings | `settings.lua`, [Settings](SETTINGS.md) |
| Validation and regressions | `tests/`, [Validation](VALIDATION.md) |

Read the implementation rather than assuming these are exhaustive. Compatibility and content modules are distributed across `prototypes/` and `scripts/`.

## Change review checklist

- [ ] Why is this good for the *player's journey*, not just the mod list?
- [ ] Is this behavior required, recommended/optional, or a player setting?
- [ ] Does it preserve source-mod authority and source credits?
- [ ] Can a new game still reach its next science and launch capability?
- [ ] Does it preserve quest IDs, saves, prototype names and existing settings?
- [ ] Are map location, routes, hazards and artwork all consistent?
- [ ] Are journal story, field notes, unlock requirements and project state accurate?
- [ ] Are old optional mods and disabled settings handled safely?
- [ ] Do relevant tests pass, and has a live game been checked where needed?
- [ ] Can a contributor explain the intention from documentation alone?

**Release discipline:** Favor a small number of logically grouped commits/pushes. Avoid redundant CI builds and costly GitHub Actions; do not disable essential checks or release safeguards merely to conserve minutes.

## Authority when documents disagree

Current `info.json` and executable source determine **what the mod presently does**. Automated tests document checked invariants. This handbook states **desired direction**. Historical changelogs record prior decisions, not authoritative current topology. If these disagree, investigate and update the relevant documentation; do not silently claim a feature has shipped because it is described as a goal.
