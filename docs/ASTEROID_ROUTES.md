# Seven-System Asteroids and Debris Belts

**Implementation:** Private `main`, pending the first full Factorio 2.1 engine load and real space-platform playtesting.

## Size unlocks: the hard progression rule

Razi's own routes now have actual asteroid-size ceilings, not just density nerfs.

| Frontier | Natural vanilla sizes | What players need |
| --- | --- | --- |
| **Calidus (Nauvis, Muluna)** | Resource chunks and **small only** | Basic platform defenses |
| **Solaris / Nyxaris** | Small and medium; **no big/huge** | First proper turrets and ammunition logistics |
| **Vibrant / Vespera** | Small, medium, **big**; no huge | Improved coverage, ammo production and durability |
| **Beetlejuice / Umbra** | All sizes, huge initially uncommon | Developed warships and layered defenses |
| **Umbra belt / Deep Space** | Big and huge concentrated | Serious long-distance combat platforms |

For Razi-managed Calidus routes, the same small-only rule also applies to
existing moon routes. Nauvis, Muluna and the Calidus transit point
receive a defensive clamp for vanilla stationary asteroid spawns.
**Modded asteroid species and their spawn curves remain unchanged.**

An asteroid size blocked by the tier has zero vanilla spawn probability.
No absent asteroid species is automatically created on ordinary routes.

## Three actual belt crossings

The original [MrLumme AsteroidBelt](https://mods.factorio.com/mod/AsteroidBelt)
is REQUIRED. Its native 5,000 km crossing, asteroid hazards, resources,
tech and original graphic stay source-owned. Razi adds two more custom
debris-belt encounters in Vespera and Umbra.

### Vibrant: Required Native Crossing

    Fulgora / Ribbonia -> INNER EDGE ==> ORIGINAL BELT ==> OUTER EDGE -> Shchierbin / Paracelsin / Beetlejuice

The graphic circles Vibrant at 1.12 scale, gateways at 31/39 map units.
Frozen Paracelsin and Shchierbin are beyond its perimeter, with their
tech progression requiring the belt. No direct Vibrant→Beetlejuice or
Ribbonia→Paracelsin route can bypass it. We never regenerate
the original native crossing or its custom asteroid resources.

### Vespera: The Debris Divide

    Muria -> Aquilo -> INNER RIM ==> DENSE BELT ==> OUTER RIM -> Rubia -> Maraxsis

* **Survey:** `razi-vespera-belt-survey`, following Aquilo discovery.
* Requires Solaris and Nyxaris Tech Cards, both available before Vespera opens. The Vespera card still uses Rubia/Maraxsis science and therefore cannot gate this survey.
* A 10,500 km approach, **6,500 km dangerous core**, and 10,500 km exit.
* The core is a concentrated medium/big-asteroid encounter; **no huge yet**.
* Both rims are resource-rich stops with metallic, carbonic, and oxide chunks.
* Direct Aquilo-to-Rubia shortcuts are removed. The path's existing custom
  asteroid resources are transferred into the central crossing.

### Umbra: The Shattered Divide

    Tenebris -> Crucible Orbit -> INNER RIM ==> SHATTERED CORE ==> OUTER RIM -> Vesta

* **Survey:** `razi-umbra-belt-survey`, following Crucible discovery.
* Requires Vibrant and Vespera Tech Cards, both available before Umbra opens. The Umbra card is reserved for later Umbra mastery and cannot gate this survey.
* A 10,000 km approach, **8,000 km dangerous core**, and 11,000 km exit.
* Strong big-asteroid encounters and **the first intentionally added huge
  asteroid encounters**, provided the relevant vanilla prototypes exist.
* Both rims provide additional metallic, carbonic, and oxide chunks.
* Direct Crucible-Orbit-to-Vesta shortcuts are removed, preserving any unique
  custom asteroid species from the retired route.

Both Razi-created belts are **real named space locations and actual route segments**, not
a cosmetic hazard modifier on an existing direct route. The map uses safe
built-in placeholder icons for the four rims. Unique debris-ring starmap art
can follow once the orbital layout is verified in-game.

### Engineering details

* Vanilla resource **chunks are not made rarer** by the size ceilings.
* On retained modded routes, only exact vanilla asteroid names are resized
  and reweighted. An Imersite asteroid is not mistaken for a metallic asteroid.
* Modded source asteroid definitions remain intact, including native
  probabilities, spawn-point curves, speeds, and asteroid types.
* When replacing an old direct crossing, any unique modded asteroid definitions
  are copied to the new core connection rather than silently discarded.
* Explicit big and huge encounters on belt cores are added **only if Factorio
  already defines those vanilla asteroid prototypes**.
* Native Aegis/Bellicos, Apia/Carnova, Dea Dia, source moon and special
  Crucible routes are left untouched.
* AsteroidBelt >= 1.2.11 is a required dependency.

## Regional density profiles

Density still varies by region, applied on top of the hard size limits.

| Region | Base multiplier |
| --- | --- |
| Calidus launch | 0.82x |
| First interstellar crossing | 0.99x |
| Solaris industry / Nyxaris biology | 0.96–1.10x |
| Middle system crossings | 1.08–1.13x |
| Vibrant / Vespera interiors | 1.08–1.25x |
| Vespera belt core | **1.48x** |
| Outer system crossings | 1.30–1.33x |
| Beetlejuice / Umbra interiors | 1.30–1.42x |
| Umbra belt core | **1.72x** |
| Deep Space approach | 1.40x |

These numbers describe probability scaling, not guaranteed asteroid counts.
The underlying preset, asteroid size and platform speed all influence actual
combat difficulty.

## Remaining tests before release

The latest GitHub CI runs structural Lua fixtures only, not a Factorio game
load. Before publishing, inspect a real `--dump-data-raw` snapshot and fly
both belts. Test resource throughput while parked at each rim, the actual
big/huge encounter rate, defenses and ammunition economy, survey unlock
timing, existing-save migration, and any modded asteroid resource behavior
that relies on original route names.

Source modules:
* [Asteroid profiles](../prototypes/system/asteroid_profiles.lua)
* [Belt locations](../prototypes/system/asteroid_belts.lua)
* [Route reconciliation](../prototypes/system/route_reconcile.lua)
* [Belt surveys](../prototypes/technology/asteroid_belts.lua)

## Route distance calibration

The revised Razi network now makes paired-star crossing lengths consistent
with the physical positions drawn on the map and later-stage platform design:
Solaris/Nyxaris **88,000 km**, Vibrant/Vespera **103,000 km**, and
Beetlejuice/Umbra **126,000 km**. Middle and outer diagonals are correspondingly
longer, and the Deep Space approaches from Secretas and Vesta are substantial
expeditions rather than cheap cross-star hops. The former 23,000 km
Vesta/Secretas shortcut was removed to preserve the Umbra belt's significance.

The dangerous **belt cores themselves remain unchanged** at 6,500 and
8,000 km. Other source-mod intra-system routes can keep their original travel
distances if they are appropriate for the new orbit. See SEVEN_SYSTEMS.md for
the table of revised km distances and `scripts/audit_route_distances.py` for
the post-load geometry checks.
