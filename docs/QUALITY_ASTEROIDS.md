# Razi Protocol: Ten-Level Quality Asteroid Escalation

## Why this implementation is different

Quality Asteroids Expanded by thesixthroc is MIT-licensed. Its published
description and PickledCow's original open-source mod show the technique:
spawn a hidden native asteroid carrier, fire an on_script_trigger_effect,
replace the carrier with a real asteroid at a randomly selected quality.
The Expanded fork additionally increases child asteroid counts, which
can multiply explosively on promethium routes.

Razi uses an independently authored 2.1 integration, with **one real
asteroid for every one hostile carrier**, avoiding multiplied children,
per-tick scans, quality-chunk exploits and expensive platform polling.
Razi's existing profiles remain the source for asteroid species, small/
medium/big/huge availability, resource salvage, and native route shape.

## The 10-stage curve

These are difficulty **levels**, not ten new Factorio qualities. Vanilla
Normal, Uncommon, Rare, Epic and Legendary retain their identities and
vanilla HP bonus. All probabilities sum to 100%.

| Level | Normal | Uncommon | Rare | Epic | Legendary |
|------:|------:|---------:|-----:|-----:|----------:|
| 1 | 100% | 0% | 0% | 0% | 0% |
| 2 | 77% | 20% | 3% | 0% | 0% |
| 3 | 59% | 27% | 12% | 2% | 0% |
| 4 | 43% | 30% | 19% | 7% | 1% |
| 5 | 30% | 27% | 23% | 15% | 5% |
| 6 | 19% | 22% | 26% | 22% | 11% |
| 7 | 10% | 15% | 22% | 29% | 24% |
| 8 | 4% | 8% | 15% | 27% | 46% |
| 9 | 1% | 2% | 6% | 17% | 74% |
| 10 | 0% | 0% | 0% | 0% | 100% |

Fractional levels interpolate adjacent rows continuously. A route
begins at its departure world's level and grows toward its destination
with an optional mid-route field crest on longer hauls or required belt
crossings. Danger changes smoothly **within a single trip**. Midpoint
quality crests are highest on Umbra's Shattered Divide, with Level 10
guaranteed in deep space and Shattered Planet regions.

- Calidus/Nauvis: Level 1 on safe home-system links.
- Solaris / Nyxaris: Level 3 on their native planetary orbits.
- Vibrant / Vespera: Level 5 and a harder physical Vibrant belt.
- Beetlejuice: Level 7.
- Umbra: Level 8, rising to ~9-10 in the Shattered Divide.
- Deep Space: Level 10 (legendary hostile asteroids only).

Actual spawn density of vanilla hostile asteroids increases gently with
route danger, capped at +55%. In late routes, existing big/huge asteroid
definitions gain relatively more weight; **no previously disabled size
is resurrected**. Modded asteroid materials and all collectible chunks
keep their source values. Size, quality, and spawn density are separate.

## Route colors follow the quality scale

The same ten-level threat grades are used for route-map markers and route
tooltips, progressing blue (level 1), cyan and green through yellow and
orange to crimson (level 10). Colors are chosen by the route's *highest*
predicted danger stage, so a difficult belt midpoint does not appear safe.
A level 10 marker indicates 100% legendary hostile asteroid quality.
Existing Factorio native lines remain unaltered; coloring is indicated
by a single modest map marker per qualifying route. No per-tick drawing
or additional overlays are added.

## Settings and compatibility

- **Quality asteroid encounters:** On by default, can be disabled.
- **Difficulty scale:** Balanced (default), Challenging (+0.75 level
  on dangerous routes), Relentless (+1.5 levels). Level 10 caps at
  Legendary, and Calidus's home links remain safe.
- Quality Asteroids / Quality Asteroids Expanded are marked incompatible
  to prevent double carriers and duplicate script triggers.

Only real installed asteroid prototypes are converted, and unrecognized
sources are skipped. **No quality resource chunks** are introduced,
so killing a legendary hostile asteroid doesn't trivially produce a
legendary collectible. The new carrier-based spawn definition is
installed last, after Razi's route-authority, sprite and tooltip passes.
This preserves the original risk inspection rather than displaying
dummy asteroids as an independent native hazard.

The runtime handler consumes only its own prefixed script effects.
It does not register ticks, scan surfaces, or save per-asteroid state.
New saves and existing saves use the same technology and connection IDs.

## Validation

- `lua5.2 tests/lua/test_quality_asteroids.lua`
- `python3 -m unittest tests.test_quality_asteroids`
- Startup inside a full 2.1 modpack; test real platforms on Calidus,
  Vibrant's rocks, Umbra's divide, and the Solar System Edge.
- Inspect mid-route selection, hostile health, combat/drops, and frame
  pacing under peak promethium load.

Factoriopedia graphs display the carrier variant by an inherited
readable asteroid name and icon, and the original native route
tooltips report the Level 1-10 range. Gameplay validation in Factorio
is still required before a stable release.
