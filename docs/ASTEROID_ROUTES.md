# Razi Asteroid Frontier

**Razi Protocol now owns three physical asteroid belts and four route fields.**
The external AsteroidBelt dependency is incompatible: no sprites, scripts or
prototype data are copied from that mod.

## Physical belts

| Sector | Survey research | Crossing | Threats |
| --- | --- | --- | --- |
| Vibrant Metallic Divide | `space-discovery-asteroid-belt` | 5,000 km | Medium with rare big asteroids |
| Vespera Debris Divide | `razi-vespera-belt-survey` | 6,500 km | Medium and big |
| Umbra Shattered Divide | `razi-umbra-belt-survey` | 8,000 km | Big and rare huge |

All three are real space locations with inner and outer rims and a real
space-connection. Rims contain collectible metallic, carbonic and oxide
asteroid chunks when those prototypes are present. Ship captains can resupply
at an edge rather than trying to mine inside the most dangerous portion.

The Vibrant rim names `asteroid-belt-inner-edge` and
`asteroid-belt-outer-edge`, connection name
`asteroid-belt-inner-edge-asteroid-belt-outer-edge`, and technology name
`space-discovery-asteroid-belt` remain stable to aid existing saves.
This is a Razi-authored replacement, not a copy of the former mod.

The Vibrant detour still gates travel toward Paracelsin and Beetlejuice.
Vespera's Aquilo→Rubia shortcut and Umbra's Crucible→Vesta shortcut remain
replaced by mandatory physical crossings, preserving custom asteroid species
from the retired routes.

## In-transit asteroid fields

Fields spike the native asteroid spawn probability at the **middle** of
selected routes, increasing smoothly from 30% to 50% of route completion
and fading by 70%. They do not introduce new waypoints or extra travel lines.

| Route | Midpoint multiplier |
| --- | ---: |
| Solaris slipstream → Vibrant slipstream | 1.50× |
| Nyxaris slipstream → Vespera slipstream | 1.48× |
| Beetlejuice slipstream → Umbra slipstream | 1.68× |
| Secretas → Deep Space edge | 1.85× |

These are local multipliers *above the route's existing profile*, not fixed
asteroid counts. Custom and third-party asteroid species retain their own
spawn curves. Blocked asteroid size tiers remain blocked. All edits happen
once during the data stage, without per-tick spawning or GPU animation.

The starmap uses dim, existing Razi debris/nebula artwork as a field marker
on real, verified route guides. Decorations are below the actual connection
masks and skip unsupported or relocated routes. Highlights Off hides field
art but not the actual route hazards.

## Migration and testing

**Back up saves first.** Disable/remove the former AsteroidBelt mod.
Razi keeps the legacy Vibrant names, but it cannot guarantee unchanged
external mod metadata, mod-owned dependencies, platform schedules or safe
migration while a platform is mid-crossing. The new dependency is marked
incompatible with the former mod to avoid duplicate prototypes.

Before publishing to the stable pack, test a copied old save and a fresh
new map in a real Factorio 2.1 client: research/unlocks; all three physical
belt crossings; the four route fields; platform resupply; custom Imersite or
other asteroid species; no progression bypass; and the visual ring placement.

Razi's data-stage code:
- `prototypes/system/asteroid_belts.lua`
- `prototypes/technology/asteroid_belts.lua`
- `prototypes/system/asteroid_profiles.lua`
- `prototypes/system/asteroid_belt_integration.lua`
- `prototypes/system/route_reconcile.lua`
- `prototypes/system/route_highlights.lua`
