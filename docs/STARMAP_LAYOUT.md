# Razi Protocol starmap: The Branching Constellation

This layout deliberately replaces the 2026 horizontal double-row map. The old
layout stretched the galaxy over hundreds of map units, forced many crossings
between bright stars, and exposed the player to too much empty space.

## A new silhouette

Visual progression is now **top to bottom**:

```text
                         CALIDUS (Nauvis)
                          /             \
                   SOLARIS             NYXARIS
                       |                   |
                   VIBRANT               VESPERA
                        \                 /
                 required ASTEROID BELT crossing
                        /                 \
                  BEETLEJUICE            UMBRA
                       \                   /
                            DEEP SPACE
                                |
                        BELLICOS EXPEDITION
```

The astronomical map coordinates are **not** kilometres. Use
`prototypes/system/galaxy_layout.lua` for display-only polar coordinates, and
`prototypes/system/route_reconcile.lua` for game travel lengths, route hazards,
and the actual progression graph.

Approximate centers in Razi starmap units:

| Star/region | X | Y |
|-------------|---:|---:|
| Calidus | 0 | 0 |
| Solaris / Nyxaris | -56 / +56 | +60 |
| Vibrant / Vespera | -70 / +70 | +138 |
| Original Asteroid Belt, inner / outer edge | 0 | +177 / +191 |
| Beetlejuice / Umbra | -86 / +86 | +218 |
| Deep Space | 0 | +310 |

## First-class Asteroid Belt

[Asteroid Belt by MrLumme](https://mods.factorio.com/mod/AsteroidBelt) is
required, Factorio 2.1 version **1.2.11 or newer**.

The mod owns the `asteroid-belt-inner-edge`,
`asteroid-belt-outer-edge`, and its **native 5,000 km crossing**. Do not
recreate those prototypes under Razi names, copy the upstream assets, or
overwrite its asteroid spawn tables. The belt is the shared gateway between
middle systems and outer systems:

- Reach the inner edge from Shchierbin (Vibrant) or Maraxsis (Vespera).
- Cross the source-mod native inner-to-outer connection.
- Reach Beetlejuice or Umbra from the outer edge.
- The straight mid-to-outer shortcuts are intentionally removed.
- The late Vespera and Umbra original Razi belts remain as separate, tougher
  local detours with their existing custom asteroid difficulty profiles.

`asteroid_belt_integration.lua` repositions the upstream belt edge locations
around the constellation's central waist while preserving the upstream icons,
research, travel lengths, and resources. It suppresses **only** the source
mod's giant solar-origin asteroid-ring background layer. That layer would
otherwise surround Calidus, which is no longer where the belt lives.

## Composition constraints

- Every star has a compact planetary crescent; the ordinary star icon must
  remain visible and no route should cut through its center.
- The inner belt is **between** the middle and outer chapters, not inside
  Calidus. Do not create easy bypasses around its central crossing.
- Portal nodes sit slightly above and to the outside of each branch star.
- Local route edges must not intersect except at intentional shared hubs.
- Only large star-centered cosmetic orbit rings are suppressed. Do not alter
  native moon orbits, hidden sub-surfaces, or other mods' local mechanics.
- Allow optional worlds to join their natural host crescent without changing
  their native science, crafting, surface triggers, or teleport mechanics.
- The Bellicos endgame annex is below the Deep Space convergence, with
  missing-pulsar and missing-gateway protections intact.

## Quality checks

`tests/test_starmap_clarity.py` checks symmetrical tiers, stellar clearance,
readable spacing, and source-mod belt connectivity.
`tests/lua/test_asteroid_belt_integration.lua` checks upstream icons,
hazards, ring-layer removal, missing prototype safety, and repeat execution.
`tests/lua/test_galaxy.lua` checks allowed connections and source-prototype
identity.
`tests/test_route_distances.py` checks gameplay km independently of
visual distances, including safeguards against belt-bypassing shortcuts.

Static tests cannot establish what the actual Factorio UI displays for
third-party star effects and labels. Use real Remote View screenshots to
make a final visual refinement without compromising route gameplay.
