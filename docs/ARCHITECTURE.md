# Razi Protocol architecture

This document describes the current Factorio 2.1 structure. Dependencies in `info.json` remain the source of truth.

## Directory map

| Location | Responsibility |
| --- | --- |
| `settings.lua`, `settings-final-fixes.lua` | Settings-stage compatibility and pack toggles |
| `data.lua` | Primary system, planet and technology prototype setup |
| `data-updates.lua` | Intermediate-stage compatibility and safe corrections |
| `data-final-fixes.lua` | Final progression cards, recipe fixes, route cleanup, final deduplication |
| `control.lua` | Runtime entry point, transceiver event gate and Chronicle registration |
| `util.lua` | Data-stage global helpers used by existing prototype modules |
| `prototypes/system/` | Star-system positions, planetary connections and conditional systems |
| `prototypes/technology/` | Technology prerequisites and progression across modded systems |
| `prototypes/compat/` | Narrow optional-mod and other prototype interoperability fixes |
| `prototypes/compat/research_exchanges.lua` | Late-stage Tech Card manufacturing recipes and cross-system research integrations |
| `scripts/chronicle/story.lua` | Story text and quest definitions, without gameplay side effects |
| `scripts/chronicle/tracker.lua` | Runtime milestones, save-safe persistent progress and event wiring |
| `scripts/chronicle/gui.lua` | Seven-tab Chronicle, per-player navigation and notifications |
| `scripts/chronicle/theme.lua` | Reusable Factorio GUI widgets, colors, icons and spacing |
| `scripts/chronicle/planets.lua` | Planet dossier context, not new planet prototypes |
| `locale/` | English and Russian prototype names and setting descriptions |
| `graphics/icons/` | Actively referenced system icons and tech cards |
| `docs/` | Maintainer notes, compatibility guidance and manual regression checks |
| `tools/` | Offline, opt-in static checks; no scheduled CI |

## Data-stage order

`data.lua` loads systems, K2SO setup and technology modules.
`data-updates.lua` handles early third-party interoperability.
`data-final-fixes.lua` must continue to apply lab cards **before** the final technology progression pass, and must preserve compatibility modules' ordering. The final lab-input deduplication intentionally runs after all those passes. Research exchanges are defined after the base card recipes and compatibility passes, then the lab-input deduplication completes. They use the final Tech Card recipe inputs and do not rewrite the original recipes.

Do not consolidate or reorder the `prototypes/compat/` modules just for tidiness. Their order reflects third-party prototype availability and historical compatibility fixes.

## Runtime data and boundaries

`control.lua` owns the existing intergalactic-transceiver activation logic. The Chronicle registers event handlers separately. Its persistent storage root is `storage.razi_protocol_chronicle` with per-force chapter, quest, visit and platform records plus per-player display preferences.

Always distinguish **technology researched**, **physical planet landfall**, **research project complete** and **space platform achievement**. A Chronicle quest reflects the real tech tree but does not modify technology prerequisites or travel routes.

The Chronicle deliberately complements Factorio's native starmap rather than replacing native panels. All GUI construction must be event-driven, never per-tick. Keep record keys unchanged across renames so existing saves retain timestamps.

## Conventions

- Keep prototype creation and data-stage mutations out of `scripts/chronicle/`.
- Avoid global functions in new code; `util.lua` is retained for legacy data-stage helper compatibility.
- Prefer new narrowly scoped compatibility modules over adding unrelated features to `prototype_sanity.lua` or `progression_polish.lua`.
- Guard optional prototypes by checking existence; never assume an optional mod is installed.
- Keep asset paths under `__razi-protocol__/` exact and case-sensitive.
- Keep `info.json` version and newest `changelog.txt` entry synchronized.
- Use `python3 tools/audit_repository.py` before a release, and follow `docs/CHRONICLE-QA.md` when runtime behavior changes.

## Release workflow

The GitHub Actions check is `workflow_dispatch` only. Batch related changes where possible, manually run the workflow only when warranted, and test mod loading and real save migration in Factorio before publishing a mod-portal release.
