# Architecture and ownership boundaries

This is a navigation guide, not a replacement for reading code. Razi Protocol operates across Factorio's prototype/data stages and the runtime control stage.

## Layers

| Layer | Responsibility | Invariant |
| --- | --- | --- |
| `info.json` | Mod requirements, compatibility and metadata | Do not confuse required dependencies, recommended additions and incompatible alternatives |
| `settings.lua` | Player-selectable startup behavior | Existing keys and defaults are compatibility contracts |
| `prototypes/` | Content integration, science and research wiring, system topology, hazards and visual prototypes | Mutate source prototypes only deliberately and after checking their final definitions |
| `scripts/` | Read-only guides, runtime project state, journal and event-driven tools | Avoid repeated full research scans, UI rebuilding or expensive polling |
| `locale/<language>/` | Display language, flavor, quests, tips and recovered fiction | Keys are stable, translate values, never claim unverified achievements |
| `tests/` | Reachability, source compatibility and regressions | Static tests must be accompanied by in-game checks for startup and map visuals |

## Journal contracts

`scripts/razi_journal.lua` computes available, complete, active and unavailable milestones from real force research, world discovery and relevant project/boss state. It does not create a second quest progress database.

`scripts/razi_journal_data.lua` combines core quests with frontier, expansion, industry and conditional companion definitions. Story, title and tip keys live in split locale resources. Stable quest IDs link these layers.

`scripts/razi_journal_records.lua` links recovered transmissions to researched milestones. Fiction does not confer gameplay rewards.

`scripts/razi_journal_projects.lua` presents larger undertakings using their real source data. Do not equate discovery/research with constructed, delivered or victorious state.

## Route ownership and UI artwork

The final space-connection prototypes are the source of truth for playable links. Route graphics, hazard explanations and journal descriptions must follow those prototypes, not independently invent travel connections.

`prototypes/system/route_highlights.lua` uses finalized positions and asteroid definitions for visual accents. Renderer work occurs at prototype/data construction, not by spawning runtime decorative objects every tick. See [Art Direction](ART_DIRECTION.md).

## Safe integration patterns

- Guard optional prototype lookups, named technologies, machine availability and mod-specific effects.
- Keep compatibility patches isolated and documented with a reason.
- Check dependency chains at both research and production levels, including lab access and science-pack manufacture.
- Test with and without optional mods where practical; never require an optional mod solely because its journal entry exists.
- Preserve older saves by using stable IDs and keeping forward migrations explicit.

## Developer reading order

1. [Handbook](DEVELOPER_HANDBOOK.md): design goals and non-negotiable rules.
2. [Expedition Journal](EXPEDITION_JOURNAL.md) and [Localization](LOCALIZATION.md): narrative and player guidance.
3. [Distributed Technology](DISTRIBUTED_TECHNOLOGY.md): science ownership and progression constraints.
4. [Art Direction](ART_DIRECTION.md): visual philosophy, starmap and GUI.
5. [Settings](SETTINGS.md): feature flags and defaults.
6. [Validation](VALIDATION.md): regression and in-game acceptance scenarios.

Historical sections can be useful evidence but may refer to superseded map layouts or versions.
