# Razi More Asteroids integration (RP3)

Razi Protocol requires **razi-more-asteroids 1.0.1+** and **razi_lib 1.3.1+**.
The asteroid fork remains usable with Space Age alone or optionally K2SO; the
RP3-specific galaxy distribution lives entirely in Razi Protocol.

## Stage order and ownership

- The asteroid mod supplies six families: uranium, rock, scrap, organic,
  chemical, crystalline. It owns graphics, processing, recipes, K2SO recovery,
  and its native Space Age routes.
- RP3 first reconciles its authored galaxy, special exits, belts, native source
  sub-networks and distances.
- `more_asteroids_integration.data_final_fixes()` then replaces ONLY these six
  families' entries on routes whose endpoints have known RP3 system/planet
  profiles. All other asteroid definitions, route IDs, geometry, schedules,
  source mechanics and K2SO recipes remain untouched.
- The reprofiled asteroids are evaluated by the existing route tooltip,
  1-to-10 danger scale, and quality-asteroid carrier pass. Resource chunks do
  not become quality enemies and no extra runtime tick handler is installed.
- Uncatalogued third-party systems, source stellar/plasma-clot routes,
  stargates, portals and hidden links remain source-owned.

## Resource geography

| RP3 region | Main new resources |
| --- | --- |
| Calidus | Uranium, rock, crystalline |
| Solaris | Rock, uranium, crystalline |
| Nyxaris | Organic, crystalline, rock |
| Vibrant | Scrap, crystalline, chemical |
| Vespera | Chemical, organic, rock |
| Beetlejuice | Crystalline, scrap, chemical |
| Umbra | Rock, uranium, crystalline, organic |
| Deep Space | All six families, with crystalline and chemical emphasis |
| Vibrant asteroid belt | Rock, crystalline, scrap; extra crossing salvage |
| Umbra asteroid belt | Uranium, crystalline, chemical; more severe crossings |

Specific planets override the broad system profile. Routes interpolate between
the *actual* endpoint mixes; an Aquilo-bound run gradually becomes chemically
richer rather than abruptly swapping all resources halfway through.

## Encounter progression

The existing RP3 ten-stage ladder determines when additional hostile sizes
can start appearing: small at stage 2, medium at stage 3, big at stage 6, huge
at stage 9. Asteroid chunks are collectible at any stage. Density follows the
existing RP3 asteroid population, belt threat, and belt ore richness options.
The fork's special K2SO orbital production remains research-gated by its
existing recipes. There is no free rare-metal or imersite yield.

Registered RP3 planet/orbit destinations gain **missing resource chunks only**,
without rewriting native orbit encounters or existing family spawn records.

## Verification checklist

1. Install RP3, Space Age 2.1, RaziLib 1.3.1+, Razi More Asteroids 1.0.1+,
   and all remaining RP3 required dependencies. Load once with K2SO enabled.
2. In the prototype dump, verify every surviving, profiled RP3 connection has
   no duplicate asteroid names and that nonexistent asteroid prototypes are
   never referenced.
3. Verify the starter Nauvis routes remain small/chunk-heavy, Vibrant and
   Umbra belt crossings are materially different, and Solar System Edge /
   Nexus lanes can contain huge asteroid families.
4. Check all six families' chunk processing, both regular and advanced, and
   the optional K2SO specialty recipes in real crushers.
5. Confirm RP3 route tooltip size/risk summaries and quality asteroid
   conversion agree with the new finalized spawn definitions.
6. Load an existing save and inspect scheduled platform routes; connection IDs
   and lengths were not deliberately changed by this integration.

These are required in-engine acceptance tests, not a claim that a full
Factorio startup was executed by the connector.
