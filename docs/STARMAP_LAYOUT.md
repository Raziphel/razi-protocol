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
| Solaris | 62 | 107.39 |
| Nyxaris | -62 | 107.39 |
| Vibrant | 124 | 0 |
| Vespera | -124 | 0 |
| Beetlejuice | 62 | -107.39 |
| Umbra | -62 | -107.39 |
| Required Asteroid Belt inner edge | 0 | -26 |
| Required Asteroid Belt outer edge | 0 | -34 |
| Deep Space / solar-system-edge | 0 | -248 |

## Design rules

- The six star centers share an exact 124-unit radius around Calidus.
  Star sprites and most native planetary routes remain visually unobstructed.
- Each existing planetary family is rotated in place so its slipstream portal
  points toward the readable campaign route; preserve planet distances from
  their parent stars to avoid crowding labels and sub-planet content.
- Research progression follows two lanes from the southern opening systems,
  through the middle side systems to the REQUIRED, shared asteroid belt
  crossing. The northern pair is unlocked beyond that crossing.
- Long Razi-managed interstellar links are lines (not giant external arcs).
  No new crosslinks or impossible shortcuts are introduced.
- Native AsteroidBelt by MrLumme remains REQUIRED at >=1.2.11. Keep its
  native graphics at full scale (1.0), original five-thousand-km crossing,
  research and native asteroid hazard tables; the entry/exit nodes are now
  just north of Calidus, straddling the actual ring artwork at 26 and 34 units.
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
- Deep Space is genuinely north of the circular constellation at (0,-248).
  Shattered Planet stays source-owned with its own local orbit.
- Bellicos/Aegis branches northeast from Deep Space, independent of the
  six-star circle. Preserve source art, gate names and every native Aegis
  connection; guard missing and retyped source prototypes at final fixes.

## Verification

- `tests/test_starmap_clarity.py` verifies the common ring radius, exact
  six-star placement, northern Deep Space, belt integration and stellar clearance.
- `tests/lua/test_galaxy_layout.lua` covers final-stage parent updates,
  native moon persistence and signature rings.
- `tests/lua/test_asteroid_belt_integration.lua` protects the original
  upstream sprite, native hazards, and missing-location safety.
- `tests/lua/test_bellicos_layout.lua` covers absent and retyped source
  locations, gate routing and remote-orbit positioning.
- `scripts/audit_route_distances.py` validates actual travel kilometers,
  entirely independent of starmap art.

Real Factorio screenshots are still necessary to judge shader scale, label
overlaps, and third-party system art. Tests do not replace live rendering.

## Verifying the running mod

On a mod-data rebuild, Razi writes a single
`[Razi Protocol/starmap] COMPASS-2026-10-11-v2` line to
`factorio-current.log`, followed by the final **native** starmap
coordinates calculated from each location's `origin`, `distance`,
and `orientation`. These are the same fields Factorio uses to draw
the map; the old geometry tests only checked `orbit` metadata.

If the log line is absent, the client is likely running an outdated
copy of the dev mod. If a logged native position differs from its
expected position, check for a source mod or final-fixes overwrite.
Static geometry tests cannot detect incorrect local mod loading.
