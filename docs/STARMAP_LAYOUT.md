# Razi Protocol starmap: Calidus and the six-star circle

Factorio and PlanetsLib use clockwise turns: **0 north**, **0.25 east**,
**0.5 south**, **0.75 west**. The native map formula is
`x = radius * sin(2π * orientation)`, `y = -radius * cos(2π * orientation)`.

This design is an intentional ring centered on Calidus, with the expedition
chapters advancing upward to Deep Space and Bellicos.

```text
                         BELLICOS / AEGIS
                              /
                         DEEP SPACE
                              |
                UMBRA                  BEETLEJUICE
                     \                 /
               VESPERA    CALIDUS    VIBRANT
                     /                 \
                NYXARIS                SOLARIS
```

| Anchor | X | Y |
| --- | ---: | ---: |
| Calidus / Nauvis | 0 | 0 |
| Solaris | 52 | 90.07 |
| Nyxaris | -52 | 90.07 |
| Vibrant | 104 | 0 |
| Vespera | -104 | 0 |
| Beetlejuice | 52 | -90.07 |
| Umbra | -52 | -90.07 |
| Required Asteroid Belt inner edge | Vibrant X | Vibrant Y - 14 |
| Required Asteroid Belt outer edge | Vibrant X | Vibrant Y - 20 |
| Deep Space / solar-system-edge | 0 | -190 |

## Design rules

- All six star centers share a **104-unit radius**, down from 124
  (~16% closer to Nauvis). The layout is still a symmetric clockwise-turn
  hexagon. The absolute starmap width is reduced without scaling planetary
  orbits, chopping off their labels, or crowding larger optional planets.
- The widest optional planet rings reach about 51 map units from their stars.
  A 104-unit adjacent-star separation is intentionally chosen instead of a
  tighter 90-unit circle, which would overlap the optional orbital rings.
- Each existing planetary family is rotated in place so its slipstream portal
  points toward the readable campaign route; preserve planet distances from
  their parent stars to avoid crowding labels and sub-planet content.
- Six homeward slipstreams now connect Calidus directly with every system
  hub. All six destination hubs remain gated by their own discovery tech.
  Outer discoveries still require space-discovery-asteroid-belt AND both
  midgame discoveries, so the direct lines are not early-game shortcuts.
- The original AsteroidBelt graphic surrounds **Vibrant's sun** at (104,0),
  not Nauvis or Shchierbin. The original graphic is 0.55 scale. Native
  inner/outer endpoints are offset 14/20 units north of that sun, but
  their orbit prototypes reference the surviving root star because
  PlanetsLib deletes virtual sprite-only stars during final fixes.
- Shchierbin remains the local approach to the REQUIRED source-owned 5,000
  km native crossing and its unique asteroid resources. The far exit
  connects to Beetlejuice. The excessively long Maraxsis and Umbra
  diagonals were removed; the surrounding spokes use increasing hazards
  and travel times of 60-65k, 110k and 175k km by chapter.
- **Native rings for every planet around a Razi star** use the Factorio 2.1
  origin-based renderer provided by PlanetsLib >= 2.0.9. The previous code
  set `draw_orbit=false` for all except six handpicked planets, hiding most
  of the orbits. That suppression has been removed.
- Synthetic star icons, artificial slipstreams, and hazard/belt edge markers
  do not draw meaningless extra rings. Secretas, an orbiting world represented
  as a space-location, does receive a native orbit.
- Never copy old PlanetsLib orbit sprites into `PlanetsLib:update` calls.
  Preserve *source-owned* special sprites and moon orbits rather than globally
  deleting other mods' artwork.
- Deep Space sits north at **(0, -190)** instead of (0, -248).
  Shattered Planet remains source-owned with its local orbit.
- Bellicos/Aegis remains a **separate northeastern expedition**, but its
  pulsar/near-orbit anchor now lies only 110 units from Deep Space rather
  than 145. The entry stargate is 28 units away rather than 35. Keep source
  art, gate names, travel distance and every native Aegis connection.
- Do not remove campaign crosslinks just to conceal map lines: early parallel
  routes, the required asteroid expedition around Vibrant, and both outer
  routes to Deep Space are intentional. The compact layout reduces the long
  visual spans without weakening research gates or travel hazards.

## Verification

- `tests/test_starmap_clarity.py` verifies compact ring radius, exact
  six-star positions, northern Deep Space, belt integration, stellar clearance,
  segment crossings, and the minimum room for outer optional planet orbits.
- `tests/lua/test_galaxy_layout.lua` covers final-stage parent updates,
  native moon persistence and signature rings.
- `tests/lua/test_asteroid_belt_integration.lua` protects the original
  upstream sprite, its shift to Vibrant's sun, native hazards, and missing
  gateway safety. `tests/test_starmap_clarity.py` verifies that the belt
  doesn't intersect surrounding planets.
- `tests/lua/test_bellicos_layout.lua` covers absent and retyped source
  locations, gate routing and remote-orbit positioning.
- `scripts/audit_route_distances.py` validates actual travel kilometers,
  entirely independent of starmap art.

Real Factorio screenshots are still necessary to judge shader scale, label
overlaps, and third-party system art. Tests do not replace live rendering.

## Why earlier maps ignored the star positions

PlanetsLib 2.0.9 renders `sprite_only` stars into `utility-sprites`
and **deletes their space-location prototypes during its own
`data-final-fixes`**. Because PlanetsLib runs before Razi at that stage,
the old Razi layout encountered missing parents and skipped every star and
many planets. Our test mocks failed to reproduce that deletion.

The new two-stage design performs `galaxy_layout.data_updates()` in
`data-updates.lua` to move the actual star sprites **before rendering**.
`galaxy_layout.data_final_fixes()` subsequently reapplies the exact
native `origin/distance/orientation` coordinates to all surviving
planets, slipstreams, and nested moons without restoring removed stars.
Original unique source orbit sprites are retained.

## Verifying the running mod

On a mod-data rebuild, Razi writes a single
`[Razi Protocol/starmap] COMPASS-2026-10-11-v2` line to
`factorio-current.log`, followed by the final **native** starmap
coordinates calculated from each location's `origin`, `distance`,
and `orientation`. These are the same fields Factorio uses to draw
the map; the old geometry tests only checked `orbit` metadata.

If either log marker is absent, the client is loading an outdated build.
If the pre-render star positions differ from the expected positions,
the custom star sprites will be misplaced. The native pass logs virtual
star-art positions explicitly because PlanetsLib correctly removed
those prototypes before Razi's final fixes.

## Design follow-up

The six-star ring centered on Calidus works as an at-a-glance map. Keep
Deep Space to the north and Bellicos beyond it. Treat the required
Shchierbin asteroid ring as a distinct midgame hazard landmark, not
something every new player sees circling Nauvis. Avoid additional direct
outer-system routes that would bypass the native asteroid crossing.
