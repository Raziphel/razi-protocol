# FluxWorks: Seven-System Industrial Atlas

FluxWorks is an optional industrial companion to Razi Protocol. The Protocol controls exploration, the star map, mandatory research gates, science progression, and victory. FluxWorks contributes unique machines, Flux production, advanced components, and industrial rewards.

This pass gives players a useful, **optional factory specialization in each of the seven primary star systems**. These are not new world unlocks and none are prerequisites of native research or Razi's story.

## The seven specializations

| System | Suggested working world | Optional research | Specialty product |
| --- | --- | --- | --- |
| Calidus | Nauvis | Foundational Fabrication | Metal mesh using iron, copper, crystalline Flux and Yellow Flux |
| Solaris | Vulcanus | Arc Alloy Engineering | Annealed cermet using tungsten carbide and Red Flux |
| Nyxaris | Gleba | Closed-Loop Bioculture | Nutrient beds using spoilage, bioflux and Green Flux |
| Vibrant | Fulgora | Holmium Resonance Works | Resonance substrates using holmium, superconductors and Yellow Flux |
| Vespera | Aquilo | Cryogenic Crystalworks | Cryogel using ice, lithium, chilled fluoroketone and Purple Flux |
| Beetlejuice | Secretas | Golden Computation | Quantum computers using Secretas gold plus Purple and Yellow Flux |
| Umbra | Tenebris | Living Phase Architecture | Phase manifolds using chitosan plus Purple and Green Flux |

Each research is `razi-fw-<system>-industry`; the corresponding recipe is `razi-fw-<system>-specialty`. The recipes reuse **existing FluxWorks items and machines**, not new inventory clutter. The base machine family is the Synthesis Plant for most projects and the Arc Foundry for Solaris.

They are **regionally themed, not mechanically surface-locked**. Ingredients such as tungsten, bioflux, holmium, chilled fluoroketone, gold and chitosan are naturally associated with the suggested worlds. A player may import those materials and run the factory elsewhere if desired.

## Research and balance

- Each specialization requires an existing FluxWorks engineering technology and the relevant Razi system-discovery technology, not vice versa.
- Beetlejuice additionally requires Secretas discovery; Umbra additionally requires Tenebris discovery. These optional industrial technologies cannot bypass their suppliers' planet access.
- Uses the corresponding system's science card and native Space Age science where appropriate; optional research never feeds back into mandatory chapter science.
- All seven recipes are nonproductive (`allow_productivity=false`) to prevent stacked bonus loops with K2SO, modules and later research.
- Existing product item IDs are reused, and all source items, fluids, science tools, technologies, crafting categories and fluid-port counts are checked before registering a specialization.
- Unavailable modded materials simply omit the specific optional process and its technology, rather than adding a fake resource.
- No global worldgen changes, no save-game entity swaps, no recurring scans or control-stage hooks.

## Optional Codex chapter

With FluxWorks installed, **FluxWorks | Industrial Atlas** appears beside the existing Industrial Alliances chapter in the Razi Protocol Codex. Each system has:
- A corresponding research milestone (using the same research completion time tracking as the rest of the Codex).
- The suggested workshop planet.
- Clear production notes and an original short narrative about the role of that system's industry.
- A violet chapter color and existing FluxWorks icon, with no extra art assets.

The chapter is not registered without FluxWorks. The Codex correctly treats missing optional research prototypes as unavailable. A Codex objective is completed by researching the corresponding industry technology, **not** by crafting the output item. The text describes the factory that the player *can* then build.

## Source layout

- `prototypes/compat/fluxworks_specializations.lua`: seven guarded optional research + recipe registrations in `data-final-fixes.lua`.
- `scripts/razi_journal_fluxworks.lua`: seven optional objective definitions with stable IDs.
- `scripts/razi_journal_data.lua`: conditional chapter inclusion.
- `scripts/razi_journal_themes.lua`: chapter color, icon.
- `locale/en/razi_fluxworks_specializations.cfg`: production and technology names/descriptions.
- `locale/en/razi_journal_fluxworks.cfg`: objective titles, tips and journal stories.

## Connected manufacturing

Five optional research exchanges link the original seven specialist factories:
- Calidus–Solaris: aerospace frames using mesh and annealed cermet.
- Nyxaris–Vibrant: bioelectronic processing units.
- Solaris–Vespera: cryothermal storage components.
- Vibrant–Beetlejuice: quantum resonance cells.
- Nyxaris–Umbra: organic rift stabilizers.

Each exchange requires both associated optional FluxWorks industry technologies, without gating the Protocol campaign. The Codex now tracks twelve optional FluxWorks researches, including these five workshop connections. Regional specialty recipes also have a five-input budget to reduce excessive shipping requirements.

See [Inter-System Exchanges and Research Clarity](FLUXWORKS_INDUSTRIAL_EXCHANGES.md) for the full rules and testing notes.

## Regression and release checks

```sh
lua tests/lua/test_fluxworks_companion.lua
lua tests/lua/test_fluxworks_specializations.lua
lua tests/lua/test_fluxworks_journal.lua
```

A **full Factorio 2.1 engine load with Razi, K2SO and FluxWorks** is still required. Verify all seven technologies are reachable, their category machines work, the dual-fluid processes connect correctly, research cards are accepted by labs, all seven Codex entries appear, and the research-complete timestamps are recorded.

Also test Razi with **FluxWorks disabled**: all existing chapters, world unlocks, victories and save IDs must remain untouched. Always test migrations on copies of saves.

Do not mark FluxWorks mandatory in stable Razi until the game engine and compatibility tests have passed.
