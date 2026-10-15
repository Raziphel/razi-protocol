# Contributing to Razi Protocol

Start with [Developer Handbook](docs/DEVELOPER_HANDBOOK.md) for project philosophy, then [Architecture](docs/ARCHITECTURE.md) for implementation boundaries and [Validation](docs/VALIDATION.md) for testing.

## Workflow

1. Identify the player problem and the intended change. Prefer one coherent fix over unrelated experimental changes.
2. Inspect the real source prototype IDs, mod dependencies and callers before patching a route, research chain or journal definition.
3. Respect existing saves: do not casually rename setting keys, quest IDs or technologies.
4. Update English locale text and relevant translations/context, documentation and focused tests together.
5. Run affected tests locally. Test Factorio startup, loading an existing save, and in-game behavior when the change touches prototypes, tech trees, starmap or UI.
6. Describe what was checked, what could not be checked, and any migration or compatibility consequences.

## Contributor roles

**Writers:** edit chapter fiction, quest stories, field notes and recovered transmissions in the split files under `locale/en/`. Use [Localization](docs/LOCALIZATION.md). The title, narrative and player-facing advice of an objective must agree with the runtime trigger.

**Translators:** translate values without changing `[section]` headings, keys, placeholders or rich text tokens. Run `python tools/journal_locale.py` and check compact-screen readability.

**Gameplay engineers:** preserve reachability of science and actual ownership of third-party mechanics. Model optional worlds as opt-in branches unless explicitly designed otherwise.

**Map and visual contributors:** favor clear routes and restrained art. Compare rendered positions with connections and actual asteroid hazards; avoid visual lines mistaken for routes.

**Performance contributors:** benchmark before and after, document gameplay tradeoffs, and use startup settings for optional heavy optimizations.

## Pull request description

State: **player impact**, **implementation rationale**, **source-mod compatibility**, **save impact**, **tests run**, **manual verification still needed**. Screenshots are recommended for visual map and UI changes. Avoid claiming complete in-game verification from static checks alone.

## Changes to avoid

Undocumented hard dependencies on optional mods; duplicating source recipes or research; fake research completion or manufactured quest rewards; arbitrary planet relocation without route/test updates; excessive starmap decorations; runtime UI rebuilding every tick; breaking key or save migrations without an explicit plan.

## Build and automation policy

The development and release workflow should avoid unnecessary GitHub Actions usage. Batch related updates where practical, keep essential validation, and do not create redundant build runs for documentation-only edits.
