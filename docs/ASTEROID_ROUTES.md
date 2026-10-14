## 2.1.70: First-party belt ecology and real crossing encounters

The older [Asteroid Belt by MrLumme](https://mods.factorio.com/mod/AsteroidBelt)
uses two physical resource rims, a difficult 5,000 km crossing, and
explicitly redirected inner/outer planet routes. Its public source code
(repository `MrLumme/FactorioMod-AsteroidBelt`, available `AsteroidBelt_1.2.3`
folder) confirms that broad design. Razi implements its **own** equivalent
using native Space Age location/connection and asteroid spawn prototypes.
No original artwork, Lua modules, or custom entity types are copied.

The original external mod patched individual Fulgora/Gleba/Aquilo routes
and hardcoded several supported mod planets. Razi deliberately does
not copy that topology. Our central `route_reconcile` +
`route_authority` passes curate the actual three local corridors,
protect critical native moons/Dyson routes, and migrate non-vanilla source
chunks when retired direct corridors are replaced.

All three existing Razi belts now have a **distinct collecting identity**:

| System | Safe rim specialty | Central crossing | Pressure peak |
| --- | --- | --- | --- |
| Vibrant Metallic Divide | Metallic chunks | 5,000 km | 1.25x near midpoint |
| Vespera Debris Divide | Oxide chunks | 6,500 km | 1.50x near midpoint |
| Umbra Shattered Divide | Carbonic chunks | 8,000 km | 1.70x near midpoint |

Each installed native metallic, carbonic and oxide chunk remains collectible
at both safe rims, with different weighted concentrations. The **actual
crossing** now contains a genuine resource seam: native asteroid-chunk
spawn probability rises toward the middle third of the route, while
Factorio's own space platform movement and asteroid collectors do the
harvesting. Medium/big/huge hazards are still determined by Razi's
existing escalating belt profiles; the additional 1.25–1.70x multiplier
tapers between 30% and 70% journey completion. Vespera does not gain
huge asteroids ahead of its normal progression, and no custom source
asteroid creature is changed.

The early and late stellar chapters **still require the existing original
technology IDs** and survey costs. Vibrant's three legacy identifiers
(`asteroid-belt-inner-edge`, `asteroid-belt-outer-edge`,
`space-discovery-asteroid-belt`) are preserved to minimize save and
schedule disruption. Neither Vespera nor Umbra first arrival is blocked
by the science packs that lie beyond its belt. Their resource zones are
made in prototypes at startup, not via per-tick entities or scripts.

**Source code:** `prototypes/system/asteroid_profiles.lua`,
`prototypes/system/asteroid_belts.lua`,
`prototypes/system/belt_expeditions.lua` and the final route authority.
The new final pass runs after route cleanup, never creates an alternative
route, and skips missing source locations/chunk prototypes.

**Release validation:** Copy an old save, park/prepare transit platforms,
restart with the external AsteroidBelt mod still disabled, and inspect the
three routes on the starmap. Test collection at each rim, difficulty at
25%/50%/75% of the route, a route with modded Imersite-like resources,
existing ship schedules and first-arrival research locks. With a real
post-load data.raw dump, `scripts/audit_route_distances.py` now checks
safe-rim chunk types, each physical crossing and its resource midpoint.
Its source-only geometry fixture intentionally lacks asteroid prototypes
and does not claim full in-game verification.

Run local focused regression fixtures before any stable promotion:
```bash
lua5.2 tests/lua/test_asteroid_belts.lua
lua5.2 tests/lua/test_asteroid_profiles.lua
lua5.2 tests/lua/test_asteroid_belt_ecology.lua
python3 -m unittest discover -s tests -p 'test_asteroid_belt_ecology.py'
python3 -m unittest discover -s tests -p 'test_route_distances.py'
```

## Authoritative route catalog (2.1.47)

Razi Protocol now has **one final route authority** instead of allowing
every planet mod to bring its own interplanetary shortcuts. This is a late
prototype pass, after source planets, Razi's seven-system corridors, community
expansions, optional side worlds, Dyson routes and technology integration
have all run.

**The rule:** For two known Razi-assigned locations, keep only pairs in
Razi's `route_reconcile.lua` planned route catalog, the chosen optional
planet side-route registry, or an explicit protected native connection.
All other built-in routes between those worlds are deleted, even when
both planets are in the same solar system. Duplicate route names
connecting the same approved endpoints are consolidated; source mod
IDs win where possible, and custom asteroid definitions survive.

**Critical exceptions**, with deliberately narrow scope:

- Nauvis/Muluna's real moon connection, Fulgora/Cerys, Gleba/Rabbasca
  and other *actual* parent-planet/moon links
- The original 5,000 km Vibrant inner/outer asteroid belt crossing, its
  real asteroid resource spawns, and Razi's required approach/departure
  corridors in all three belt systems
- Crucible and its source-owned orbit
- The original Dyson sun-orbit stations and their source technology
  unlock IDs, plus the native Calidus access they need
- A single deterministic connection into an otherwise unrecognized
  third-party dimension/planet when its author supplied multiple paths
  to our known systems. The external world's internal network is untouched

Known optional planets including Igrys, Foliax, Obsidiax, Ferrum,
Alchemy/Khemia, Arcanyx, Carna, Rabbasca, Velora and Balack keep an
explicit home hub. The final pass creates missing links and carries custom
asteroid resources across whenever a source route is replaced.

This is **not** a blind `data.raw["space-connection"] = {}`: that
would strand modded locations, break the native asteroid belt, and remove
travel needed for the Dyson project and boss/endgame dimensions. External
source-only subnetworks are intentionally retained until incorporated
into the Razi catalog rather than guessed or wiped.

### Setting and rollback

`razi-curated-space-routes` is a new startup toggle, **on by default**.
Turning it off bypasses the new final strict pruning pass for compatibility
diagnosis; the earlier Razi expedition-route balancing still runs. Always
back up saves before switching. A platform schedule referencing a deleted
source connection can require choosing a replacement itinerary.

### Diagnostics

Search `factorio-current.log` for `[Razi Protocol/routes] Authoritative
network:` to see counts for removed shortcuts, protected special links
and total retained routes.

### Engine acceptance checks

Launch Factorio 2.1 with all required planets, plus optional moon and
boss mods. Check Solaris and Nyxaris for duplicate local loops, inspect
the original 5,000 km Vibrant belt crossing and both Razi-owned outer
belts, verify Dyson station trips and Calidus's moon, and confirm that
every discovered optional world is reachable. The source prototype
fixtures verify topology but cannot certify platform schedules or all
unknown external mod connections.

> **Current route visuals (2.1.44):** Razi retains authored asteroid risk
> definitions and route intel, but no longer paints fixed colored sprite
> segments. Install the optional Space Route Overlay 0.2.7+ for native-route
> hazard coloring. The earlier route highlight designs below are historical.

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
