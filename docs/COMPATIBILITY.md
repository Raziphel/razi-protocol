# Compatibility and Integration Policy

This project integrates many independent Factorio 2.1 planet mods. We should
make them feel cohesive while preserving the ability of upstream maintainers
to update independently.

## Working with Alex and other maintainers

The upstream author should own broad gameplay changes. Razi Protocol should
carry only **small, conditional and tested** cross-mod compatibility fixes.
Keep a link to the issue or PR in the registry as soon as one is available;
never assume an upstream release contains a fix unless it has been verified.

The machine-readable [registry](../compat/registry.json) identifies the
current integration modules, their scope and their tests. It is *not* evidence
that every upstream issue is unresolved; `needs-review` is deliberately
conservative.

Before adding a new patch:
1. Reproduce the bug in a specific required/optional mod combination.
2. Capture the technology/recipe prototype from `--dump-data-raw`.
3. Check whether an upstream issue/fix already exists, and write its link.
4. Modify only the impacted prototypes and guard on the expected mod/version.
5. Add a fixture reproducing both the bug and the absence of the dependency.
6. Test that the patch does **not** overwrite a source mod's already-correct fix.
7. Remove the patch once the upstream fix is verified in the supported version.

## Post-load prototype audit

With the exact modpack enabled in Factorio 2.1:

    python3 scripts/audit_prototypes.py /path/to/script-output/data-raw-dump.json
    python3 scripts/audit_compatibility.py /path/to/script-output/data-raw-dump.json

The compatibility audit checks Razi's science-card ingredients/results,
stale K2SO research trigger names, high-risk recycling-productivity settings,
the hydrogen/oxygen/water cycle, and missing planet-specific research-data
surface conditions. It is intentionally conservative:

- **ERROR**: a system-card ingredient/result definitely does not exist, or a
  research trigger points to an obsolete output while the renamed product is
  the only producible one.
- **WARN**: a suspicious recycling loop, or absent surface restriction.
  These might be intentional. Review them instead of blindly patching.
- Use `--json` for automation and `--strict-warnings` when conducting a
  manual all-findings review.

The audit does **not** prove the Factorio engine can load the modpack, or
that every planet's mining and resource chain is playable. A complete game
load, save migration and practical exploration remain mandatory.

## Celestial weather

The 2.1 forks `celestial-weather-updated` and
`celestial-weather-additions-updated` can be installed independently, but Razi
Protocol does not yet patch their prototypes or runtime behavior, so they are
not declared as optional dependencies in `info.json`.
Avoid duplicating their mechanics inside Razi. Audit the final enabled planet
prototypes and weather settings before adding integrations, especially Muria,
Rubia, Paracelsin, Vesta, Panglia and optional Pelagos. The next step is to
evaluate their in-game severity and communicate weather requirements through
the planet guide rather than introducing unverified hazards.

## Enemy integration

Optional enemy placement must never remove vanilla spawning when all custom
spawner prototypes are missing. The regression fixture tests both sides,
including the global enemy-routing off switch. Future balancing should assess
spawn weights and evolution per planet using screenshots and in-game combat
data, not blanket global multipliers.

## Player-facing encyclopedia

Start with [the Planet Field Guide](PLANET_FIELD_GUIDE.md), keeping source
mod names, environment descriptions and optionality accurate. The repository
already declares Informatron as optional, but we will not write against an
unverified API. After validating its current Factorio 2.1 contract, adapt
these entries into Informatron pages without requiring it.

## Planet expansion intake

New 2.1 planet candidates should be reviewed for: real native game version,
mod ID, dependencies, author permission/credit, unique gameplay, science,
resource supply, surface conditions, native connections, save stability and
which system's research tier they fit. Do not add experimental planet mods to
required dependencies until those checks pass.

## K2SO integration for every enabled planet

Razi's final K2SO pass reconciles known K2SO material aliases on all installed planet recipes without rewriting Null's intentionally visible common fluids. Its existing system cards also import native K2SO planetary research data from accessible earlier regions. See [K2SO Planet Integration](K2SO_PLANET_INTEGRATION.md) for the science matrix, guards and remaining engine tests.
