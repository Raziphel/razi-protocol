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
| Required Asteroid Belt inner edge | Vibrant + 31 at 0.17 turns | Inner side |
| Required Asteroid Belt outer edge | Vibrant + 39 at 0.17 turns | Outer side |
| Deep Space / solar-system-edge | 0 | -190 |

## Design rules

- All six star centers share a **104-unit radius**, down from 124
  (~16% closer to Nauvis). The layout is still a symmetric clockwise-turn
  hexagon. The absolute starmap width is reduced without scaling planetary
  orbits, chopping off their labels, or crowding larger optional planets.
- The widest optional planet rings reach about 51 map units from their stars.
  A 104-unit adjacent-star separation is intentionally chosen instead of a
  tighter 90-unit circle, which would overlap the optional orbital rings.
- Planet climates guide visual orbital distances: hot Vulcanus (18),
  Hyarion (19), Arig (27), Muria (20), Moshine (22) and Crucible orbit
  (19) move inward. Remote/icy Paracelsin (49), Aquilo (40),
  Maraxsis (44) and Secretas (40) sit farther away.
  Source game temperatures, solar yields and moon orbits are unchanged.
- Calidus opens two branches through Solaris/Nyxaris into
  Vibrant/Vespera. The Vibrant to Beetlejuice stage now physically
  requires the original native AsteroidBelt crossing. Only seven
  direct interstellar lines remain, plus the belt, with the two useful
  crosslinks Solaris↔Nyxaris and Beetlejuice↔Umbra.
- The Calidus departure slipstream is 20 units due south of home
  (previously 25), clear of Nauvis and Muluna but closer to the center.
  Planet orbits, the six-star radius (104) and all star textures stay put.
- Neighboring planets now have short return routes: Vulcanus↔Castra,
  Arig↔Hyarion, Gleba↔Moshine, Moshine↔Apia-Carnova Orbit,
  outer AsteroidBelt edge↔Paracelsin, Linox↔Secretas,
  and Umbra slipstream↔Crucible Orbit. These are 12–22k km local
  expeditions, not new interstellar shortcuts. They reuse existing
  asteroid difficulty profiles; world discovery prerequisites are unchanged.
- Vespera and the remaining Umbra rim routes intentionally keep a
  single dangerous crossing. Extra shortcuts there either bypass the
  surveys or run over Rubia/Crucible map markers. Old same-system
  crossings directly from Vibrant's inner planets to its outer planets
  are removed while preserving the original native belt core.
- The original discovery technologies continue to gate travel:
  the first two frontiers use Nauvis science, the middle frontiers
  require the earlier branches, and outer discoveries still require
  `space-discovery-asteroid-belt` plus both middle branches.
- Routes increase in challenge: early 60–65k km, midgame 90–100k km,
  Umbra branch 120k km and Vibrant→Beetlejuice 137.5k km total through
  Ribbonia and the source-native asteroid crossing (23.5+24+5+85k).
  The original belt-core 5k segment and its native asteroid spawns
  remain untouched.
- Route distance audit also addressed the three clearest local mismatches:
  Nyxaris ↔ Apia-Carnova planned 17k → 23k km, Nyxaris ↔ Moshine 18k →
  22k, and Cubium ↔ Secretas 19k → 23k. Native in-system lengths still
  use the existing source-preserving 75–135% clamp.
- The original source AsteroidBelt graphic surrounds Vibrant at
  1.12 scale, its native inner/outer gateway at radii 31/39 and
  0.17 clockwise turns north-east. The gateways orbit the root star
  because PlanetsLib removes sprite-only stars in final fixes.
  Fulgora and Ribbonia are inside; Shchierbin and frozen Paracelsin
  outside. To reach the outer worlds: Ribbonia → inner edge →
  native belt → outer edge → Shchierbin / Beetlejuice.
  The direct Vibrant→Beetlejuice and Ribbonia→Paracelsin shortcuts
  are removed. Shchierbin requires native belt science, Paracelsin
  requires Shchierbin.
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
- Keep the two short same-tier crosslinks, the required asteroid expedition
  around Vibrant, and both distinct outer branches to Deep Space. Avoid
  additional Calidus spokes and unnecessary neighboring-star loops.

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
`[Razi Protocol/starmap] PRE-RENDER-2026-10-11-v3` line and a later
`[Razi Protocol/starmap] NATIVE-2026-10-11-v3` line to
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
Vibrant sun asteroid ring as a distinct midgame hazard landmark, not
something every new player sees circling Nauvis. Avoid additional direct
outer-system routes that would bypass the native asteroid crossing.

## First-party asteroid frontier (2.1.14)

Razi now replaces the required upstream AsteroidBelt with three Razi-owned
physical crossings: Vibrant, Vespera and Umbra. The original Vibrant waypoint
and research names remain for save migration; the surrounding ring uses
existing Razi textures rather than external art. Four longer routes also have
concentrated midroute asteroid fields and dim decorative field markers.
See [ASTEROID_ROUTES.md](ASTEROID_ROUTES.md) for the current implementation;
earlier references in this file to source-owned AsteroidBelt are historical.

## Visual orbit density (October 2026)

The older rule that all positioned planets draw native orbit rings remains
available using **Full** orbital chart detail. **Balanced** is now the
default, reserving a few spaced circles per star; **Clean** leaves one.
These are visual-only `draw_orbit` changes. The six star coordinates,
all planet and moon positions, custom orbit graphics, campaign routes,
tech gates and travel distances remain exactly as before.

The geometry is intentionally not moved during this polish pass. Moving star
anchors requires regenerating pre-aligned highlight masks and repeating all
campaign-clearance tests.
