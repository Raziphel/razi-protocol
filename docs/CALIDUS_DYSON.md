# Calidus Stellar Works: source-owned Dyson sphere, Razi-integrated campaign

This feature uses the maintained Factorio 2.1
`slp-dyson-sphere-reworked-fork >= 1.0.5` and
`k2-dyson-sphere-rebalance >= 0.1.2`. Razi does not copy or replace the
authors' runtime scripts, satellite tracking, custom orbital locations,
plasma asteroid encounters, energy-connector control, or satellite costs.

## Galaxy and progression

Both source orbit locations are identified from their existing
`unlock-space-location` technology effects at data-final-fixes time.
Razi positions them at radius 10 and 5 around the starting Calidus
star (source starmap sprites preserved) and adds a short Calidus-hub
access link to the outer orbit if that link does not already exist.
The original solar-to-inner-solar connection survives unchanged.
Disable `razi-dyson-calidus-layout` to restore source positions.
The new Razi route does not automatically unlock its destinations.

| Native technology | Additional guarded Razi project context |
| --- | --- |
| `planet-discovery-sunorbit` | Vulcanus + Fulgora discoveries |
| `slp-solar-system-sun2` | Gleba + Cerys moon discovery |
| `slp-dyson-sphere` | Cerys advanced structural repair + Moshine data processors |
| `slp-dyson-sphere-grounded` | Aquilo discovery |
| `ds-energy-loader-mk2` | Maraxsis Project Seadragon research |
| `ds-energy-loader-mk3` | Outer Frontier Mastery (promethium stays source-owned) |
| Razi `razi-singularity-test-fire` | Source receiver engineering research, not an invented satellite-count trigger |

Links are added only if both native technologies exist and the result
is acyclic. The Razi milestone toggle can disable all added prerequisites.

This gives the original Dyson a strong multi-planet story and preserves
the starting/first-frontier power economy. A Dyson orbit being close to
Nauvis on the map is not permission to visit it before Fulgora research.

## More informative Galactic Operations

The existing map-attached Galactic Operations button now has
**Stellar Works**, a read-only progress and prerequisite inspector.
The six native Dyson technologies are also flagged as essential in
Factorio's condensed technology-tree filter when the Razi milestone
weave is enabled.
It shows actual installed native research, not fabricated satellite
counts or claimed physical construction progress. Connectors and
repeaters remain fully controlled by the source mod.

The SLP fork has several known quirks. Do not write into its private
control-stage satellite tables, rewrite its event handlers or assume
its player death warnings are disableable from Razi's settings.
The 2.1 port added resilience for damaged connectors and rebuilt
platforms. Full multi-user save compatibility is unverified.

## Balance contract

- The source's bounded power connectors are **not made infinite**.
- Its repeater satellite requirements, plasma, energy and science stay.
- K2 Rebalance controls the plasma-card conversion; no competing
  Razi science recipe is created.
- MK2 waits for advanced Maraxsis research, MK3 stays very late.
- Solar plasma asteroid hazards are left intact. The short local
  Calidus hub connector is intentionally an ordinary transit leg.
- Solar Halo is a separate, optional mod with overlapping concepts.
  Do not collapse its locations into the Dyson project automatically.
- No per-tick Razi controllers, generated planets, satellite counters,
  item prototypes, or new source asset dependencies.

## Validation before release

Load the entire Factorio 2.1 mod set and validate the actual two source
unlock effects and orbit IDs. Launch several satellites, unlock each
receiver, destroy a connector, build from blueprint, and try a platform
transfer away from inner orbit. Then test an old multiplayer save and
run the technology-graph, science-lab and routing audits. All research
changes are save-affecting, so back up saves before toggling them.

The data-stage source audit is not equivalent to in-engine playtesting.

## Stellar Works II: genuine receiver census and research artwork

The map-native **Stellar Works** tab now includes a visual construction
phase (derived from **researched technology only**), a cached placed-
receiver census, per-surface receiver counts, and honest diagnostics.
Read-only entity candidates are resolved from source-owned
`ds-energy-loader-mk1`, `ds-energy-loader-mk2`, and
`ds-energy-loader-mk3` item `place_result` prototypes. Exact placed
receiver counts use the engine's `LuaForce.get_entity_count` and
`LuaSurface.count_entities_filtered` methods, and are sampled only
when a player opens or refreshes the GUI, with a 600-tick cache. Player
cache refresh uses the existing Galactic Operations refresh control.

**Important:** the installed SLP fork does not advertise a documented
read-only satellite-count and energy-delivery API. Razi therefore does
not report or synthesize its private satellite count, repeater totals,
allocated megawatts or real physical sphere-completion percentage.
A research-phase illustration is never presented as physical progress.
A true satellite-driven starmap phase also cannot be changed at runtime
through data-stage `starmap_star` textures. That visual remains
static; evolving research illustrations live in the GUI.

The five GUI sprites reuse existing Razi artwork. No additional art
files, periodic game-tick callbacks, source-mod runtime edits or
source-state migrations are required.

## Compact Calidus layout cleanup

The optional Razi Calidus hub-to-outer-solar-orbit connector is not added
if an existing Nauvis or Muluna native route already reaches the outer
station. Otherwise it still supplies the missing access. The source
Sun-to-inner-Sun connection, Dyson research and receiver mechanics remain.
