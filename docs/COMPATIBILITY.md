# Compatibility and Integration Policy

Most of the planets in this pack come from other developers. Compatibility
patches should be small, easy to track and safe to remove once the original
mod fixes the problem.

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

The Factorio 2.1 forks `celestial-weather-updated` and
`celestial-weather-additions-updated` are now **recommended**, not required,
in `info.json`. The add-on declares a source-owned hard dependency on the
base weather mod. Razi's Atmospheric Field Guide only inspects the installed
mod settings; Razi does not duplicate weather effects or introduce its own
periodic environment logic. Verify real-game atmosphere settings on Muria,
Rubia, Paracelsin, Vesta, Panglia and any opt-in Pelagos configuration.

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

## Curated K2SO compatibility bridges (2.1)

`corrundum-krastorio-compatibility-plus >= 1.1.2` is a required dependency
on the same footing as Null's Tweaks, xyrc's Null Fork, Castra, Rubia,
Paracelsin and Cubium compatibility bridges. Keep third-party conversions
source-owned. Razi's Solaris system card already consumes the native
Corrundum electrochemical science pack.

`secretas-krastorio-compatibility-plus` currently has a Factorio 2.0
release and must not enter the required Factorio 2.1 stack. The distinct
`secretas-orbit-patch >= 1.1.3` is optional because Outer Rim expressly
excludes it; Razi also preserves Secretas/Frozeta source moon orbits.
See [K2SO integration](K2SO_PLANET_INTEGRATION.md#community-k2so-compatibility-ownership)
for ownership and in-engine validation requirements.

## K2SO integration for every enabled planet

Razi's final K2SO pass reconciles known K2SO material aliases on all installed planet recipes without rewriting Null's intentionally visible common fluids. Its existing system cards also import native K2SO planetary research data from accessible earlier regions. See [K2SO Planet Integration](K2SO_PLANET_INTEGRATION.md) for the science matrix, guards and remaining engine tests.
