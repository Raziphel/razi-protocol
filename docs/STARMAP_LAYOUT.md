# Calidus-centered radial starmap

The map returns to the appearance of Razi's original version: Calidus stays in
the center, six star systems occupy loose radial sectors, and special remote
content remains outside the main constellation.

| Location | X | Y | Notes |
| --- | ---: | ---: | --- |
| Calidus | 0 | 0 | Home star, restored native asteroid halo |
| Solaris | 150 | -115 | Upper-right industry |
| Nyxaris | 145 | 92 | Right-side biology |
| Vibrant | 20 | 180 | Lower technology arc |
| Vespera | -142 | 138 | Lower-left planetary/belt cluster |
| Beetlejuice | -180 | -25 | West remote industrial |
| Umbra | -102 | -151 | Upper-left exotic |
| Main Asteroid Belt inner | -96 | 86 | Source-owned gateway |
| Main Asteroid Belt outer | -118 | 67 | Source-owned gateway |
| Deep Space | -292 | -155 | Detached outer frontier |

Each planetary family is rotated as a whole. Native moons remain untouched,
and the same existing travel lengths, research prerequisites and asteroid
hazards continue to determine gameplay. Razi's interstellar links use
Factorio's curved `arc` rendering to avoid the old straight-line mesh.

**Asteroid art:** Restore the required MrLumme AsteroidBelt source graphic
instead of deleting its starmap layer. Its scale is reduced from 1.1 to 0.28,
so the original Calidus-centered asteroid halo is readable without covering
other stars. Its source item/technology icons and native crossing stay intact.

**Special annex:** Aegis/Bellicos uses the actual Near Bellicos Orbit graphics
location where available, because some source versions have no registered
`pulsar` prototype. Its Aegis locations and stargate travel with it to the
upper-left Deep Space annex. Missing source prototypes are guarded to
prevent Factorio startup failures.

## Checks

- `tests/lua/test_galaxy_layout.lua`: radial sectors, one ring per system,
  safe native moon orbits, final stage ordering.
- `tests/test_starmap_clarity.py`: six star centers, local route geometry,
  mandatory belt progression and route clearance.
- `tests/lua/test_asteroid_belt_integration.lua`: source-owned belt hazard and
  native graphic restoration, including idempotent loading.
- `tests/lua/test_bellicos_layout.lua`: absent/retyped pulsar and actual
  Near Bellicos Orbit placement.
- `tests/lua/test_galaxy.lua`: curved route presentation and research gates.

A screenshot from Factorio's Remote View is the final visual check. Static
tests cannot account for all external mod sprites, labels, and render sizes.
