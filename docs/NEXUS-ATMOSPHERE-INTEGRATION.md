# Nexus, Celestial Weather and Outer Rim integration

**Razi Protocol dev 2.1.10 | October 2026**

This pass integrates source-owned Nexus trial progress and 2.1 Celestial Weather atmospheric information in the existing Expedition Journal and Galactic Atlas. It does **not** claim full in-game validation, introduce new scripted bosses, or make Outer Rim mandatory.

## Nine boss trials, one authoritative game state

| Native research circle | Bosses in encounter order | Razi Journal role |
| --- | --- | --- |
| Whisper | Arachnid Queen; Watcher; Rogue Spidertron | Three independently completed quests, plus source research and expedition bearings |
| Chorus | Twin Maws; Colossus; Plague Hulk | Three independently completed quests; the original mod awards the next circle |
| Convergence | Storm Guardian; Devourer; Last Commander | Three independently completed quests; the native nine-trophy key and Silence remain the reward |

Native `nexus-bosses` owns summon beacons, preparatory defense waves, boss health, trophy drops, lairs, storm shards, warp key, scripted stage technologies and route unlocks. The Journal does not impersonate any of them.

The source mod exposes a **read-only** `remote.call("nexus-bosses", "get_state")` API. Razi reads the `defeated[force.name]` table once per Journal view, with `pcall` and feature detection. Each quest uses its matching boss ID and becomes **complete only when that boss actually died**, never merely because its stage technology was researched. Multiplayer players on the same force see consistent victories. A missing or incompatible source API hides boss-specific quests instead of claiming a false victory. Research-only Chronicle quests remain unchanged.

The existing ten-second transceiver-maintenance callback also refreshes **only** an open Deepworks Journal or a pinned boss objective. No 1-tick boss polling, entity scans, separate high-frequency loops, kill duplication or direct writes to Nexus storage are introduced.

### Preparation technology: six original research milestones

The Journal now links to native Photon Electronics, Advanced Magnetic Shielding, Nexus Storm Prediction, Omega Substation, Omega Accumulator and Omega Beacon. These milestones are preparation guidance, not additional hard gates. Their source technology, crafting and science costs stay authoritative.

Use the native Nexus Bosses Codex for battlefield tactics, expedition logs, boss bearings and optional lair quality. It is reachable directly from the Journal's individual boss pages and the Nexus page of Galactic Atlas. Razi calls only `open_codex` through a user click, not its debugging, boss-abort or state-mutation functions.

Three new **original-fiction** recovery transmissions unlock on Whisper, Convergence, and Silence. Completion records use the research milestone so the archive also works in saves where the original boss fights are already completed.

### Collaboration contract with the Nexus authors

We should ask the maintainers to document `get_state` and `open_codex` as stable optional public read-only interfaces, including per-force merge and multiplayer behavior, rather than relying indefinitely on a debug-oriented API. Graceful absence handling is already in place.

## Atmospheric field guide

The original 2.1 weather forks still own all actual weather effects, particles, fog and clouds. Razi adds no competing simulation loop. The Journal and planetary Atlas show concise environment guidance **and whether the relevant source startup toggle is currently on**.

| Source planet | Field-note focus |
| --- | --- |
| Panglia | Timewarp habitat clouds, luminous sparks and dust |
| Muria | Corrosive spores, original rain toggle, dark fog |
| Rubia | Biological skies and drifting cloud cover |
| Paracelsin | Optional winter and permanent darkness, normally disabled |
| Vesta | Gas-giant clouds, haze and atmospheric visibility |
| Cubium | Electrical sparks and industrial cloud cover |
| Rabbasca | Fog, sparks and dust above isolated vaults |
| Igrys | Industrial atmosphere |
| Khemia | Chemical haze |
| Carna | Dense outer-world organic weather |
| Pelagos | Maritime visuals complementing ship logistics |

A disabled setting is shown as disabled, not as a forecast. A missing source weather add-on hides the field guide entirely. No source weather settings are overwritten.

### Performance

Effects remain controlled by the upstream weather authors' existing startup settings. For lower-end machines, tune their cloud, fog and particle settings independently. In particular, Muria can retain its original rain if the corresponding source setting is enabled, but that may increase simultaneous visual effects. Do not force such expensive combinations onto every player.

## Outer Rim: optional, not a mandatory bridge

The **Outer Rim 2.9.x** source coordinates Aquilo, Paracelsin, Carna, Secretas and Frozeta, with additional research, production and space connections. These worlds are spread across several different Razi systems. Its published changelog explicitly flags K2SO compatibility as potentially malfunctioning or crashing. Its native route rewrites and research redistribution could also bypass Razi's asteroid-belt crossings or create a science dependency on a later system.

`? outer-rim` stays optional. No Outer Rim technology is required to reach Nexus, the outer frontiers, or the transceiver. It is not appropriate to promise integration without a verified complete data-stage load and controlled save testing.

Suggested collaborative pass with the Outer Rim author: isolate world-local resource and recipe integrations behind a compatibility setting, leave Razi-owned interstellar routes untouched, then validate each affected science predecessor before enabling any shared research requirements.

## Manual validation checklist

1. Start the full Factorio 2.1/K2SO pack with Nexus Updated, Rebalanced, Nexus Bosses, Nexus Threat, both weather forks and their required enemy mods. Verify a clean data stage and real in-game load.
2. On a copied existing save and a new save, research the native Nexus scan, omega power, shields and storm prediction. Confirm Razi's six preparation quests appear without granting technology or science.
3. Defeat a single Whisper boss. Verify **exactly one** Journal boss objective completes, the source trophy drops once, other two remain incomplete, and the Codex is unchanged.
4. Complete the first three, the second three, and the last three. Verify the source stage technologies, Signal bearings, weather/storm-shard interactions, lair rewards, native warp key, Silence and Oort/Sol routes remain controlled solely by the source.
5. Repeat victory checks with two players on one force, then merge two forces; verify a source snapshot failure gracefully hides individual combat quests.
6. Visit weather-profile worlds, toggle startup effects on a copied mod settings profile, and verify the Journal/Atlas labels follow the source setting. Compare UPS with and without heavy fog, sparks and clouds on a busy factory.
7. Separately test Outer Rim 2.9.x using a disposable save and full logs. Audit all crossing routes, source technologies, availability of every required science pack, and K2SO chemistry. **Do not merge it into required dependencies unless all checks pass.**

All GitHub Actions remain manual-only. The Lua and Python regressions are committed as runnable checks, but this document does **not** substitute for an actual Factorio load or nine-boss playtest.

## Upstream references

- https://github.com/GreenTech-Solutions/nexus-bosses
- https://github.com/GreenTech-Solutions/Nexus-Updated
- https://github.com/GreenTech-Solutions/nexus-rebalanced
- https://github.com/GreenTech-Solutions/celestial-weather-additions
- https://mods.factorio.com/mod/outer-rim
