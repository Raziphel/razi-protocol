# Required-mod difficulty coverage audit

This inventory is generated from the current Razi Protocol `info.json` on
`feat/razi-3.0`. **Hard requirements (51)** include Factorio `base` and
`space-age`; **recommended (23)** are a distinct category. An installed
recommended mod participates only when it defines relevant entity prototypes.

## Implementation rules

Razi's difficulty selects gameplay modifiers during startup. Those modifiers
operate through *Razi's integrations and final prototype definitions*, not by
mutating another mod's saved settings. Explicit overrides of the relevant
Razi advanced settings continue to win. Custom uses saved Razi control values.

- Assembling machines, furnaces, mining drills, and labs: native speed fields;
  all original recipes, science pack inputs and module slots preserved.
- Walls, gates and player-buildable ammo, electric, fluid and artillery turrets:
  health scaling only. Do not modify enemy worm turrets or scripted unbuildables.
- Solar panels and accumulators: output and buffer capacity only. Solar rules,
  accumulator charge/discharge limits and Dyson/nuclear/steam scripts remain
  untouched.
- Existing Razi integrations: enemy habitat spread, planet resource map controls,
  evolving raids, K2SO launch costs, planetary exchanges, HELIOS, asteroid
  encounters and hard/nightmare Rocket Reusability side-wreck approaches.
- Deliberately *not* controlled: boss AI, bespoke planetary weather scripts,
  source-mod recipe inputs, runtime-only toggles, original map chunks and
  foreign saved startup settings.

### New electric-grid difficulty

| Selected difficulty | Solar production | Accumulator capacity |
| --- | ---: | ---: |
| Easy (Robust) | 120% | 120% |
| Normal | 100% | 100% |
| Hard (Limited) | 90% | 90% |
| Nightmare (Precarious) | 80% | 80% |

Use `razi-grid-resilience` to override this axis manually. This is a
startup setting, so restart Factorio before creating/loading the map.
Changing these capacities on an existing save may require the game to
re-evaluate stored charge; test existing saves with a backup.

## Complete hard requirement coverage

| Category | Source mods (internal dependency names) | Integration scope |
| --- | --- | --- |
| Engine / expansion (2) | `base`, `space-age` | Base mapgen/rocket cost, entity classes and power infrastructure; no native setting saves changed |
| Libraries / assets (3) | `razi_lib`, `PlanetsLib`, `Krastorio2Assets` | APIs/assets only; no meaningful standalone gameplay setting to force |
| Industrial overhaul (1) | `Krastorio2-spaced-out` | K2SO factories, miners, labs, buildable defenses, solar/storage, rocket cost and science economy when matching prototypes exist |
| Rocket wreck source integration (1) | `razi-rocket-reusability` | Razi Rocket Reusability 1.1.6+ reads Razi Hard/Nightmare for side approaches |
| Dyson / stellar systems (2) | `slp-dyson-sphere-reworked-fork`, `k2-dyson-sphere-rebalance` | Existing HELIOS/Dyson science and route integration; scripted power stages deliberately source-owned |
| Outer-system gameplay (1) | `bellicos-and-aegis` | Existing system routes, threats and technology; no unsupported boss AI overrides |
| Planets and native industries (33) | `planet-muluna`, `planetaris-unbounded`, `planetaris-tellus`, `planetaris-hyarion`, `planetaris-arig`, `Cerys-Moon-of-Fulgora`, `linox`, `Muria`, `corrundum`, `apia`, `Moshine`, `panglia_planet`, `tenebris-prime`, `secretas`, `maraxsis`, `rubia`, `cubium`, `Nexus-Updated`, `skewer_planet_vesta`, `castra-prime`, `planet-crucible`, `ribbonia`, `Paracelsin`, `Igrys`, `foliax`, `obsidiax`, `carna`, `Velora`, `alchemy-khemia`, `Arcanyx`, `biological-machines-planet-balack`, `nulla`, `PlanetAthos` | Prototype-matched miners, labs, factories, defenses, solar/storage; planet resource ecology and expedition research where registered |
| Compatibility and recipe bridges (8) | `corrundum-krastorio-compatibility-plus`, `castra-krastorio-compatibility-plus`, `k2so-cubium-compatibility-fork`, `nulls-k2so-tweaks`, `xy-k2so-enhancements-nulls-fork`, `rubia-krastorio-compatibility-plus`, `tenebris-prime-made-in-hide`, `paracelsin-krastorio-compatibility-plus` | Native recipes, inputs and settings retained; compatible entity prototypes get the shared scaling |

## Recommended dependencies (not hard-required)

`aai-signal-transmission`, `planet-express`, `upgraded-rocket-turrets`, `frozeta-nuclear-winter`, `secretas-orbit-patch`, `celestial-weather-additions-updated`, `VoidProcessing-Updated`, `ArmouredBiters21Compat`, `Cold_biters`, `Explosive_biters`, `Imersite-Asteroids`, `science-tab`, `LithiumBattery`, `rabbasca-underground`, `skewer_shattered_planet`, `planet-ferrum`, `Big-Monsters`, `Various_Cargo_Bays`, `space-age-railway-expansion`, `shield-generators`, `CircuitLaunchableRockets`, `CargoBayLimitResearch`, `platform-logistics-overhaul`.

Recommended mods with supported entity types receive the same conditional
prototype balancing. In particular, optional enemy families and Big-Monsters
keep their own spawn/event APIs rather than having settings silently rewritten.

## Optional or load-order-neutral

Optional: `planet-rabbasca`, `shchierbin`.

Neutral load order: `orbital-cannon`, `nexus-bosses`.

Excluded incompatible mods (22) are intentionally
not considered for compatibility or difficulty patches.

## Validation checklist

1. Load all hard dependencies and confirm prototype validation completes.
2. Check every difficulty across one vanilla and one modded example of each
   supported class: mining drill, lab, assembler, wall, turret, solar panel,
   accumulator. Check Normal returns source baselines.
3. Confirm existing producer recipes, lab pack lists, turret targeting and
   enemy worms remain unchanged. Check that absent optional speed fields
   correctly assume native defaults and can restore to absent values.
4. Confirm solar output scales only production; accumulator buffer capacity
   scales without changing flow limits or surface efficiency logic.
5. Verify selected New Game preset matches Easy/Normal/Hard/Nightmare/Custom
   after restart; the auto-select opt-out must preserve external defaults.
6. Confirm Custom and manual Razi overrides are independent of the other
   preset axes. Foreign saved mod settings remain untouched.
7. Test existing saves (backed up) separately from a new-map test, including
   Rocket Reusability 1.1.6+ for difficulty-specific side-arriving wrecks.

Static source checks and Lua unit tests do not replace a real Factorio
modpack startup and gameplay compatibility test.
