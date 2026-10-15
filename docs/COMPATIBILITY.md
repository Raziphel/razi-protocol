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

`celestial-weather-updated` remains recommended. The installed
`celestial-weather-additions-updated` 1.6.0 reports a direct conflict with
the base fork even though public 1.3.0 metadata declares it required.
The add-on is withdrawn from Razi's recommendation list until upstream
correction and a controlled Factorio test. Razi's weather guide detects
installed source settings and never simulates effects itself.

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
`+ secretas-orbit-patch >= 1.1.3` is recommended for native moon orbits;
`! outer-rim` blocks the incompatible competing space-map ruleset.
Razi retains its own asteroid-belt corridors.
See [K2SO integration](K2SO_PLANET_INTEGRATION.md#community-k2so-compatibility-ownership)
for ownership and in-engine validation requirements.

## K2SO integration for every enabled planet

Razi's final K2SO pass reconciles known K2SO material aliases on all installed planet recipes without rewriting Null's intentionally visible common fluids. Its existing system cards also import native K2SO planetary research data from accessible earlier regions. See [K2SO Planet Integration](K2SO_PLANET_INTEGRATION.md) for the science matrix, guards and remaining engine tests.

## Armoured Biters 2.1 fork compatibility (2.1.76)

An installed ArmouredBiters21Compat 2.0.6 stack failed prototype validation
with a missing `armoured-biter-spawner.autoplace.probability_expression`.
Razi 2.1.75 was manufacturing an empty `autoplace={}` for the source-owned
nest, then other mod integrations encountered that incomplete definition.

Razi 2.1.76 never synthesizes a partial enemy-autoplace prototype. If the
source pack supplies a valid probability expression, the dedicated nest can
populate Hyarion, Nexus and Crucible. Otherwise, source armoured units
remain in the original biter-spawner's `result_units` and Razi skips the
invalid dedicated placement instead of suppressing vanilla fauna. The final
prototype pass strips malformed placement rules on known optional spawners
without deleting their entities or scripted spawning support. Electric and
Arachnid routing also checks source placement validity. This is guarded by
the Lua enemy fixture and still requires an actual Factorio modpack launch.
