# Expedition Journal 3.x: Phase 1 chapter architecture

This phase reorganizes the existing Journal into **five volumes and 42 chapters**. It does not add technologies, alter research prerequisites, switch on unfinished lore, or change the identity of a quest.

## Structure

| Volume | Chapters | Focus |
| --- | ---: | --- |
| Foundations | 7 | Nauvis, industrial setup, launch, Muluna and salvage |
| The First Frontiers | 10 | Solaris, Nyxaris, Panglia and the Aegis survey |
| The Outer Systems | 14 | Vibrant, Vespera, Beetlejuice and Umbra |
| The Industrial Network | 6 | Side expeditions, matrix research, defense, trade, partnerships and the Dyson Sphere |
| Beyond the Edge | 5 | Outer mastery, singularity, Deep Space, Nexus and Convergence |

The authoritative list is `scripts/journal/volumes.lua`. All **230 existing objective IDs** are assigned exactly once. Their original `tech`, `world`, `requires`, `boss`, `convergence`, `optional` and `story_only` conditions are unchanged. A catalog entry is a *chapter*, not a new research technology.

`scripts/journal/data.lua` applies the catalog after collecting the original quests. Every quest retains `legacy_chapter`; the new `chapter` field is presentation-only. All 56 existing authored act objects and their legacy `phases` storage keys remain unchanged. They are indexed under the new chapter that displays each quest.

## Compatibility

- `razi_chapter_completion_times[force].milestones` keeps every original quest ID and tick.
- Historical `chapters` and `phases` entries are **not renamed or deleted**, so old times remain auditable and existing act stamps retain their meanings.
- Newly defined chapters have new storage keys. On a prior save, a chapter gets a historical unknown time (`false`) unless **every required milestone** already has a real first-clear tick; when they do, use the latest tick as its reconstructed completion time.
- When the last required milestone is **newly researched after the update**, record that actual game tick, including when older milestones had unknown times.
- Old per-player `p.chapter` preferences are mapped to the selected milestone's new chapter where possible; otherwise legacy IDs map to a stable first/default destination. Pinned and selected **quest IDs do not change**.
- Optional planet content is still filtered by the real installed technology or discovery. A nonexistent mod does not create a phantom research blocker.
- Native research and world discovery remain authoritative. No separate progression storage was introduced.

## Verification

`lua tests/journal_volumes_test.lua` tests catalog completeness, all ID references, legacy act keys, preference aliases and three historical completion scenarios.

For an in-game smoke test, use both a new game and an existing 2.x/3.x save. Check the full Journal index, a pinned objective, at least one completed chapter and one optional planet removed from the installed mod list. Test both spoiler settings and the Journal at a smaller GUI scale.

## Next phases

Phase 2 will replace the long flat navigation list with volume-aware collapsible navigation and improve the reader layout. Phase 3 will author and enable the currently disabled written-story layer. This phase deliberately leaves the story switch off.
