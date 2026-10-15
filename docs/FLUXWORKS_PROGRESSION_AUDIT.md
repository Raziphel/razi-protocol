# FluxWorks: Machinery Progression and Codex Usability Pass

An experimental, companion-only integration for Razi Protocol Dev. FluxWorks stays optional. No original FluxWorks prototype IDs, Space Age research paths, Razi discovery technologies, or vanilla recipes are removed.

## What the audit found

1. **Factory previews silently absent.** The Codex looked up `prototypes.recipe[quest.tech]`. The twelve FluxWorks industry quests research `razi-fw-*-industry` and `razi-fw-*-exchange`, but their recipes are named `razi-fw-*-specialty` and `razi-fw-*-assembly`. The lookup therefore showed no actual inputs/outputs.
2. **Missing quantities and equipment.** Even when a recipe preview existed, its material icons did not show how much of each ingredient was required, and the player could not see which machine to build.
3. **Optional progress counted as compulsory campaign completion.** The seven specialist and five exchange researches could inflate the main campaign's completion percentage, despite being advertised as optional.
4. **Optional industry competing with next-story suggestions.** The guidance algorithm treated an optional factory goal like a normal quest with a suggested world.
5. **Stacked research costs for machine introductions.** The initial Flux synthesis, Harvester and Arc Foundry technologies carried several substantial consecutive research bills. The later biological, phase and convergence tiers were similarly heavy atop their existing planetary requirements.

## Improvements in Razi Dev

- Every FluxWorks Codex objective now has an explicit **recipe** and **compatible machine** reference. The Codex verifies that the selected research actually unlocks that recipe before showing the diagram.
- Factory supply cards show quantities, ranges and probabilities where relevant. The panel identifies the machine and names the recommended supply-chain world. Players can search Codex objectives by recipe and machine ID.
- The existing source-owned Codex recipes still work through their old same-name lookup, so this is a backwards-compatible enhancement.
- All twelve FluxWorks objectives remain available in their own violet chapter with separate chapter completion totals, but do **not** count against the Protocol's global campaign-completion statistics or primary ready-objective count.
- Industrial goals have reduced recommendation priority. They can still appear in the planner as spare ready objectives but should not displace primary story or destination research.
- Eight *existing FluxWorks* technologies get modest companion-mode ceilings on their science **count** and research-unit **time**, while every prerequisite, science ingredient, unlock, and product remains the same:

| Technology | Original count | Companion ceiling | Max time (seconds/unit) | Role |
| --- | ---: | ---: | ---: | --- |
| `fw-flux-yellow-catalysis` | 220 | 180 | 35 | First chemistry milestone |
| `fw-flux-stabilization` | 260 | 210 | 35 | Synthesis Plant |
| `fw-harvester-systems` | 320 | 250 | 35 | Flux Harvester |
| `fw-flux-red-energetics` | 320 | 260 | 40 | Fuel Flux groundwork |
| `fw-flux-metallurgy` | 580 | 460 | 40 | Arc Foundry |
| `fw-flux-green-cultivation` | 860 | 690 | 45 | Biological production |
| `fw-flux-phase-engineering` | 980 | 820 | 55 | Phase machinery |
| `fw-cross-planetary-industrial-convergence` | 2200 | 1760 | 65 | Cross-system industry |

Ceilings only reduce the original cost when the tech exists and its cost is a positive, fixed research-unit count. A cheaper setting or another mod's previous integration is never raised back to these numbers. This is not an instant unlock, and the required planetary sciences and all actual tech prerequisites remain intact. Industrial Project mastery research stays at its original costs.

**Standalone FluxWorks is unchanged.** All adjustments happen in the optional Razi integration only.

## Source

- `scripts/razi_journal_recipe_preview.lua`: explicit recipe resolution and quantity caption formatting.
- `scripts/razi_journal_fluxworks.lua`: twelve optional research goals annotated with recipe and equipment IDs.
- `scripts/razi_journal.lua`: supply diagram, equipment cards, global statistics.
- `scripts/razi_journal_guidance.lua`: prioritization.
- `locale/en/razi_journal_fluxworks_ux.cfg`: labels and readable workshop site guidance.
- `prototypes/compat/fluxworks_machine_pacing.lua`: bounded data-stage research pacing.
- `data-final-fixes.lua`: applies companion pacing after other FluxWorks and Razi reconciliation steps.

## Validation needed

The change includes Lua mock regression tests for the twelve industry IDs, exact recipe selection, quantity formatting and cost ceilings. Execute from repository root:

```sh
lua tests/lua/test_fluxworks_journal.lua
lua tests/lua/test_fluxworks_factory_preview.lua
lua tests/lua/test_fluxworks_machine_pacing.lua
lua tests/lua/test_fluxworks_specializations.lua
lua tests/lua/test_fluxworks_exchanges.lua
lua tests/lua/test_fluxworks_research_clarity.lua
```

**The full Factorio 2.1 + K2SO + Razi + FluxWorks pack must still load successfully before stable release.** Verify with and without FluxWorks, check the visual Codex, ingredient cards and production facilities in real play, compare actual research availability, and use a backup of existing saves. Research time/cost changes are prototype-stage changes; ongoing research progression may need re-evaluation in copied saves.

This does not establish whether every recipe is optimally balanced. Actual throughput, production costs and ingredient availability across hundreds of mods require in-game production testing.
