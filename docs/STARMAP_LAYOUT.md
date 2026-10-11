# Calidus starmap: compact connected star ring

The starmap uses a small Calidus-centered six-system constellation. The
previous radius of roughly 170–200 visual units spread individual chapters
over several screens; star centers are now 120–160 units from home, with the
six systems arranged as two opening worlds, two middle worlds, and two outer
worlds. Deep Space converges a short distance beyond the outer pair.

| Star/landmark | X | Y |
|---|---:|---:|
| Calidus | 0 | 0 |
| Solaris | 100 | -80 |
| Nyxaris | -90 | -80 |
| Vibrant | 121 | 41 |
| Vespera | -117 | 43 |
| Beetlejuice | 75 | 135 |
| Umbra | -78 | 141 |
| Original Asteroid Belt, inner | -30 | 36 |
| Original Asteroid Belt, outer | -26 | 48 |
| Deep Space | 0 | 232 |

## Art and routing

- Each planetary family rotates as a unit around its new star position.
  Ordinary planet radii shrink by about six percent; native orbit moons and
  hidden destinations retain their source mechanics.
- Long inter-system links use direct **line** presentation rather than very
  large Factorio arc curves. Local planetary routes can remain curved.
- The oversized optional Vibrant–Vespera shortcut is removed. Both middle
  systems remain reachable from their respective opening systems; they join
  at the mandatory source Asteroid Belt instead.
- Solaris and Nyxaris retain their shorter early crosslink.
- The native AsteroidBelt graphic is preserved from the upstream mod at scale
  0.85 (instead of the tiny 0.28 halo). Its two source-owned travel locations
  now sit close to the visual ring around Calidus. The upstream 5,000 km
  crossing, hazards, science and art files remain source-owned.
- Vespera/ Umbra local asteroid belt detours remain unchanged in difficulty.
- Deep Space is a compact outer convergence at (0,232).
- Optional Aegis & Bellicos remains a distinct annex beyond Deep Space, but
  its root offset is reduced to 120 units and its orbitals grouped 30–49
  units from the shared Near Bellicos Orbit anchor. No native asteroid
  spawning or routes inside Aegis are rewritten.

## Regression checks

`tests/test_starmap_clarity.py`: core star centers, visual clearance,
crossing connectivity, planetary marker spacing.

`tests/test_route_distances.py` and `scripts/audit_route_distances.py`:
travel kilometres remain independent of starmap geometry.

`tests/lua/test_galaxy_layout.lua`: star sectors, native moons, one
signature orbit per star, safe final-fixes ordering.

`tests/lua/test_galaxy.lua`: required routes and hazards, native belt
preservation, no redundant middle crosslink, direct long-route presentation.

`tests/lua/test_asteroid_belt_integration.lua` and
`tests/lua/test_bellicos_layout.lua`: source asset and remote prototype safety.

Live Factorio rendering remains the final visual check for special artwork
and label positions; static geometry can not verify sprite anchoring.
