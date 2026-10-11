# Starmap art direction and geometry

The Razi Protocol map is a **compact constellation**, not a literal kilometre
scale diagram. The seven campaign systems are Calidus (home) and three pairs:
Solaris/Nyxaris, Vibrant/Vespera, and Beetlejuice/Umbra. Deep Space is the
rightmost destination, with Bellicos in its own modest right-side annex.

## Composition rules

- Keep the three pairs visually aligned in **two short progression lanes**.
  Adjacent column centres should be about 80 map units apart, with each pair
  separated vertically by about 84 units.
- Star-centred planets belong in compact, recognisable local crescents. Local
  routes must **go around stellar sprites**, not slice through their centres.
- The interstellar slipstream hubs sit northwest of each star so the main
  travel lanes are readable at normal Remote View zoom.
- Local canonical route graphs should have **no geometric edge crossings**
  unless they share an endpoint. Preserve multi-branch gameplay, native moons,
  belt detours, and discovery gates.
- Hide cluttering star-centred planet orbit rings. Leave planet-centred native
  moon orbits and external standalone systems alone.
- Optional planets receive room near their host star, not another broad ring
  at double the default distance.
- The Deep Space edge and its Shattered/Bellicos side branches should remain
  visually separate from the six-star campaign without consuming several
  screens of otherwise empty space.

## Technical contract

The authoritative **visual positions** are in
`prototypes/system/galaxy_layout.lua`, with conditional optional location
positions in `optional_planets.lua` and `community_expansions.lua`.
`bellicos.lua` positions only prototypes present during the actual data
stage, including safe fallbacks for a missing source pulsar.

**Never alter route kilometres to match visual orbit.distance.**
`route_reconcile.lua` controls gameplay travel lengths, hazard profiles,
and the canonical progression network. Asteroid belt crossings are intentional
short hops with escalating asteroid risk.

New layout changes must keep both Lua regression fixtures and Python geometry
checks passing. In particular, the geometry suite verifies compact stage
separation, star clearance, local edge crossings, and marker spacing.
Real Factorio starmap screenshots are still required to verify external
mods' artwork and scene composition: static tests cannot prove how the
client renders overlapping names, sprites, or native custom structures.
