# FluxWorks Industrial Exchanges and Research Clarity

This is a companion-only expansion for players running **FluxWorks with Razi Protocol Dev**. It deliberately avoids a second mandatory campaign.

## Factory networks

The original seven independent specialty industries remain optional. Five new **inter-system exchanges** let materials from two different regional workshops converge into a useful, established product.

| Exchange | Suggested workshop | Inputs supplied by both regions | Alternative output |
| --- | --- | --- | --- |
| Calidus → Solaris | Vulcanus | Calidus metal mesh + Solaris annealed cermet | Low-density structures |
| Nyxaris → Vibrant | Fulgora | Nyxaris nutrient beds + Vibrant resonance substrates | Processing units |
| Solaris → Vespera | Aquilo | Solaris annealed cermet + Vespera cryogel | Thermal buffers |
| Vibrant → Beetlejuice | Secretas | Vibrant resonance substrates + Beetlejuice quantum computers | Flux resonance cells |
| Nyxaris → Umbra | Tenebris | Nyxaris nutrient beds + Umbra phase manifolds | Rift stabilizers |

These facilities use existing FluxWorks Synthesis Plants or Arc Foundries. Each recipe consumes up to two Flux inputs and is **not productivity-compatible**, preventing multiplicative recovery loops. A trade may run on any surface with the requisite inputs; the suggested world is a narrative and supply-chain recommendation, not a forced crafting-surface restriction.

Five corresponding optional exchange technologies (`razi-fw-<pair>-exchange`) each require the **two regional specialty technologies** (`razi-fw-<region>-industry`). These five research rewards are not prerequisites of any planet discovery, Razi science card, route, story milestone, or native technology.

No new item tiers, fluids, entities, scripted automation, or periodic runtime scans were added. All existing factory recipes remain available.

## Simplification

- The seven regional recipes now use at most five ingredient lanes. In particular, Vespera cryogel no longer requires an unnecessary salt delivery, and Beetlejuice quantum fabrication no longer requires a separate memory-die shipment.
- In the combined pack, `fluxworks_research_clarity.lua` removes *redundant direct arrows* between FluxWorks-owned technologies. Example: when `B` already requires `A`, a technology listing both `A` and `B` only needs the direct `B` edge. This changes **tech-tree visual clutter**, not research reachability or cost.
- FluxWorks project and mastery reward paths are left intact. Razi-owned gates, K2SO techs, Space Age discoveries, and recipes are not rewritten.
- The existing companion science simplification remains: FluxWorks domain packs are optional mastery science rather than a mandatory second set for ordinary engineering.

## Protocol Codex

Five new objectives join the violet **FluxWorks | Industrial Atlas** chapter, after the original seven specialties. Each objective references its exact optional exchange research and the two earlier specialty quests. The Codex records **research completion time**, not physical construction or shipment delivery. Players are given a suggested workshop and a short, original engineering story.

The chapter and all new prototypes are omitted entirely when FluxWorks is not installed.

## Factory previews and priorities

The Codex now resolves each exchange's actual recipe name rather than attempting to display its technology as a recipe. Recipe input and output cards include quantities, and the suggested compatible machine is shown above the supply lines.

All exchange objectives remain optional and are excluded from the main Protocol campaign completion total. See [FluxWorks Progression Audit](FLUXWORKS_PROGRESSION_AUDIT.md).

## Safety, startup cost, validation

- All new recipes and technologies are registered through one data-stage pass. Source ingredient, output, fluid and crafting-category existence is checked before creating anything.
- Each exchange uses no more than six ingredients and two input fluids.
- Research simplification uses memoized graph reachability and only removes an arrow when its requirement is already satisfied through another prerequisite path. It does not delete research technologies, unlock effects or science costs.
- No existing prototype is renamed or destroyed, and no saves require runtime migration.
- FluxWorks' standalone gameplay and `Raziphel/razi-protocol` stable release are untouched.

Quick regression source tests:

```sh
lua tests/lua/test_fluxworks_companion.lua
lua tests/lua/test_fluxworks_specializations.lua
lua tests/lua/test_fluxworks_exchanges.lua
lua tests/lua/test_fluxworks_research_clarity.lua
lua tests/lua/test_fluxworks_journal.lua
```

These source-level tests are not substitutes for the full Factorio 2.1 + K2SO + Razi + FluxWorks data-stage load. Before adding this to the public Razi release, check research availability, production machines, all five import/export paths, live Codex updates, and saved games using disposable copies.
