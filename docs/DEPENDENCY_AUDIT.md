# Razi Protocol: Direct and transitive dependency audit (2.1.81)

Reviewed 15 October 2026. The complete direct manifest is registered in [`compat/dependency_policy.json`](../compat/dependency_policy.json). Verified upstream hard-dependency evidence and deliberate version floors are tracked in [`compat/dependency_transitive.json`](../compat/dependency_transitive.json).

| Direct declaration type | Count | Meaning |
| --- | ---: | --- |
| required | 50 | Core K2SO, seven-system worlds, libraries and curated campaign |
| recommended | 24 | Compatible 2.1 companion suggestions, not required |
| optional | 2 | Experimental and staff-approved manually installed planets |
| hidden-optional | 1 | Unadvertised load-order compatibility links |
| incompatible | 20 | Known conflicts and unsupported combinations |

## Guaranteed indirectly, so removed from Razi's direct manifest

| Still installed through | Guarantees |
| --- | --- |
| `Nexus-Updated >= 1.4.1` | [`Nexus-Threat-Updated >= 1.1.0`](https://mods.factorio.com/mod/Nexus-Updated/dependencies) |
| `k2-dyson-sphere-rebalance >= 0.1.2` | [`slp-dyson-sphere-reworked-fork >= 1.0.5`](https://mods.factorio.com/mod/k2-dyson-sphere-rebalance/dependencies) |

The transceiver, Dyson sphere stages, Nexus endgame, and all campaign planets retain the same intended mechanics. Transitive hard dependencies load before their requiring mods. We have not disabled the source mods.

## Appears redundant, but is a necessary version pin

The following entries are required by another already-required mod, **but their upstream requirement is less strict**. Removing their Razi entry would lose a version floor, potentially permitting old combinations that the curated research tree has never supported.

| Keep Razi direct requirement | Other required parent | Parent version floor |
| --- | --- | --- |
| `planetaris-arig >= 1.1.44` | [`planetaris-unbounded`](https://mods.factorio.com/mod/planetaris-unbounded/dependencies) | none |
| `planetaris-hyarion >= 1.3.23` | [`planetaris-unbounded`](https://mods.factorio.com/mod/planetaris-unbounded/dependencies) | none |
| `planetaris-tellus >= 1.1.11` | [`planetaris-unbounded`](https://mods.factorio.com/mod/planetaris-unbounded/dependencies) | none |
| `Moshine >= 1.2.10` | [`panglia_planet`](https://mods.factorio.com/mod/panglia_planet/dependencies) | `>= 1.2.9` |
| `cubium >= 1.0.31` | [`k2so-cubium-compatibility-fork`](https://mods.factorio.com/mod/k2so-cubium-compatibility-fork/dependencies) | `>= 1.0.29` |
| `Krastorio2-spaced-out >= 2.0.17` | [`k2-dyson-sphere-rebalance`](https://mods.factorio.com/mod/k2-dyson-sphere-rebalance/dependencies) | `>= 2.0.0` |
| `PlanetsLib >= 2.0.9` | [`planet-muluna`](https://mods.factorio.com/mod/planet-muluna/dependencies) | `>= 2.0.8` |
| `Krastorio2Assets >= 2.1.0` | [`planet-rabbasca`](https://mods.factorio.com/mod/planet-rabbasca/dependencies) | none |
| `castra-prime >= 0.9.2` | [`castra-krastorio-compatibility-plus`](https://mods.factorio.com/mod/castra-krastorio-compatibility-plus/dependencies) | none |
| `rubia >= 0.69.159` | [`rubia-krastorio-compatibility-plus`](https://mods.factorio.com/mod/rubia-krastorio-compatibility-plus/dependencies) | `>= 0.69` |
| `Paracelsin >= 1.10.2` | [`paracelsin-krastorio-compatibility-plus`](https://mods.factorio.com/mod/paracelsin-krastorio-compatibility-plus/dependencies) | `>= 1.6` |
| `tenebris-prime >= 1.3.12` | [`tenebris-prime-made-in-hide`](https://mods.factorio.com/mod/tenebris-prime-made-in-hide/dependencies) | none |

## Big Monsters and Nexus Bosses

Nexus-Updated **does not** require Big Monsters. The separate Nexus Bosses add-on explicitly requires `Big-Monsters >= 2.2.1`, `Nexus-Threat-Updated >= 1.1.0`, Toxic Biters, Arachnids and Electric Flying Enemies. Since Nexus Bosses declares `? razi-protocol` and is installed separately, Razi must not introduce a reverse dependency cycle. Big Monsters can remain recommended as an extra enemy addition when the addon is absent; when the addon is installed it will be loaded as a hard transitive dependency regardless of Razi's `+` declaration. [Official Nexus Bosses dependency list](https://mods.factorio.com/mod/nexus-bosses/dependencies).

## All 97 direct dependency declarations

| Declaration | Direct category |
| --- | --- |
| **Core, libraries, campaign and bridges** | **50 entries** |
| `base >= 2.1.20` | required |
| `space-age >= 2.1.20` | required |
| `razi_lib >= 1.1.0` | required |
| `PlanetsLib >= 2.0.9` | required |
| `bellicos-and-aegis >= 0.4.0` | required |
| `Krastorio2-spaced-out >= 2.0.17` | required |
| `k2-dyson-sphere-rebalance >= 0.1.2` | required |
| `Krastorio2Assets >= 2.1.0` | required |
| `planet-muluna >= 2.7.25` | required |
| `nulla >= 1.0.2` | required |
| `PlanetAthos >= 1.1.3` | required |
| `planetaris-unbounded >= 1.9.1` | required |
| `planetaris-tellus >= 1.1.11` | required |
| `planetaris-hyarion >= 1.3.23` | required |
| `planetaris-arig >= 1.1.44` | required |
| `Cerys-Moon-of-Fulgora >= 4.24.17` | required |
| `linox >= 1.8.9` | required |
| `Muria >= 1.8.6` | required |
| `corrundum >= 1.0.49` | required |
| `corrundum-krastorio-compatibility-plus >= 1.1.2` | required |
| `apia >= 0.3.1` | required |
| `Moshine >= 1.2.10` | required |
| `panglia_planet >= 0.7.2` | required |
| `tenebris-prime >= 1.3.12` | required |
| `secretas >= 1.0.37` | required |
| `maraxsis >= 1.39.1` | required |
| `rubia >= 0.69.159` | required |
| `cubium >= 1.0.31` | required |
| `Nexus-Updated >= 1.4.1` | required |
| `skewer_planet_vesta >= 2.1.27` | required |
| `castra-prime >= 0.9.2` | required |
| `castra-krastorio-compatibility-plus >= 1.1.0` | required |
| `planet-crucible >= 1.1.27` | required |
| `ribbonia >= 0.6.8` | required |
| `Paracelsin >= 1.10.2` | required |
| `k2so-cubium-compatibility-fork >= 0.3.5` | required |
| `nulls-k2so-tweaks >= 2.3.1` | required |
| `xy-k2so-enhancements-nulls-fork >= 0.8.5` | required |
| `rubia-krastorio-compatibility-plus >= 1.3.1` | required |
| `tenebris-prime-made-in-hide >= 1.1.0` | required |
| `paracelsin-krastorio-compatibility-plus >= 1.2.0` | required |
| `Igrys >= 1.5.40` | required |
| `planet-rabbasca >= 0.22.2` | required |
| `foliax >= 2.0.37` | required |
| `obsidiax >= 1.0.29` | required |
| `carna >= 0.3.22` | required |
| `Velora >= 2.2.2` | required |
| `alchemy-khemia >= 0.3.6` | required |
| `Arcanyx >= 1.1.5` | required |
| `biological-machines-planet-balack >= 1.1.2` | required |
| **Recommended companions** | **24 entries** |
| `+ aai-signal-transmission >= 0.6.0` | recommended |
| `+ planet-express >= 2.1.9` | recommended |
| `+ upgraded-rocket-turrets >= 2.1.1` | recommended |
| `+ frozeta-nuclear-winter >= 1.12.1` | recommended |
| `+ secretas-orbit-patch >= 1.1.3` | recommended |
| `+ celestial-weather-additions-updated >= 1.6.0` | recommended |
| `+ VoidProcessing-Updated` | recommended |
| `+ ArmouredBiters21Compat` | recommended |
| `+ Cold_biters >= 2.3.0` | recommended |
| `+ Explosive_biters >= 2.4.0` | recommended |
| `+ Imersite-Asteroids >= 1.3.0` | recommended |
| `+ science-tab >= 1.13.0` | recommended |
| `+ LithiumBattery >= 7.3.0` | recommended |
| `+ rabbasca-underground >= 0.10.3` | recommended |
| `+ skewer_shattered_planet >= 1.0.42` | recommended |
| `+ Solar-Halo >= 1.2.0` | recommended |
| `+ planet-ferrum >= 0.1.4` | recommended |
| `+ Big-Monsters >= 2.2.1` | recommended |
| `+ Various_Cargo_Bays >= 1.1.0` | recommended |
| `+ space-age-railway-expansion >= 0.0.18` | recommended |
| `+ shield-generators >= 0.7.0` | recommended |
| `+ CircuitLaunchableRockets >= 1.4.6` | recommended |
| `+ CargoBayLimitResearch >= 1.1.2` | recommended |
| `+ platform-logistics-overhaul >= 2.1.2` | recommended |
| **Optional side worlds** | **2 entries** |
| `? moon-eneas >= 1.0.10` | optional |
| `? shchierbin >= 0.3.19` | optional |
| **Hidden integration ordering** | **1 entries** |
| `(?) FluxWorks >= 0.2.12` | hidden-optional |
| **Excluded conflicts** | **20 entries** |
| `! AsteroidBelt` | incompatible |
| `! space-route-overlay` | incompatible |
| `! kry-asteroid-belt` | incompatible |
| `! outer-rim` | incompatible |
| `! castra` | incompatible |
| `! Redrawn-Space-Connections` | incompatible |
| `! krastorio2_extended_endgame` | incompatible |
| `! K2_spaced_out_extended_endgame` | incompatible |
| `! xy-k2so-enhancements` | incompatible |
| `! maraxis-k2so-collision-mask-fix-fix` | incompatible |
| `! lignumis` | incompatible |
| `! lignumis-cf` | incompatible |
| `! tile-upgrade-planner` | incompatible |
| `! quality-rocket-parts` | incompatible |
| `! MT-lib` | incompatible |
| `! external-rocket-parts` | incompatible |
| `! Wood_Gasification_updated` | incompatible |
| `! factorioplus` | incompatible |
| `! Hephaestus` | incompatible |
| `! biological-machines-planet-wit` | incompatible |

### New companion group (15 October 2026)

Six more non-mandatory companion mods support orbit storage and pod throughput,
nuclear/fusion railway industry, shield defenses, circuit rocket automation,
cargo bay progression and actual-pod same-orbit platform logistics. Their exact
minimum versions were checked against the public Factorio Mod Portal.
The seventh candidate, Orbital Catapult, **does not have a direct dependency**
because its author explicitly requires the special `~` mode, which would
force an install and disturb the curated map's final-fixes order. Razi
supports experimental local catapult links through a default-off startup
setting only when players install the source manually.

Source dependencies are the source mod owners' responsibility, notably
Shield Generators bringing its own migratus-orchestrus runtime and Orbital
Catapult bringing powered-machine. None of the six recommended mods
becomes a Razi hard requirement. Full recursive graph verification and
installed Factorio load testing are still release gates.

## Automated, repeatable full-graph audit

The repository now includes `scripts/audit_mod_dependencies.py`, which fetches the **native 2.1 release metadata** for every required mod from the Factorio Mod Portal, walks required dependencies recursively, and reports missing versions, conflicts, duplicate direct entries and explicit version pins. The public Mod Portal does not require authentication for the metadata endpoint. Results are cached outside the repo. It does **not** change the manifest or trigger any workflow.

```bash
python3 scripts/audit_mod_dependencies.py --json /tmp/razi-mod-deps.json --check
python3 scripts/audit_mod_dependencies.py --offline --json /tmp/razi-mod-deps-offline.json
python3 -m unittest discover -s tests -p 'test_mod_dependency_graph.py'
python3 -m unittest discover -s tests -p 'test_dependency_policy.py'
```

**Validation boundary:** The curated hard guarantees and source dependency pages above have been inspected, and manifest/policy consistency is checked statically. The *complete recursive Mod Portal API traversal has not been executed in this workspace*. A live API run, full Factorio 2.1 load with both baseline and recommended profiles, and old-save verification remain required before a stable release. Preserve manual-only GitHub Actions and back up save files before enabling or removing planet mods.

## October 15, 2026: Real startup conflict follow-up

The reported 2.1.74 enabled-mod profile would not load: Celestial Weather
Additions **1.6.0** conflicts with Celestial Weather Updated; Outer Rim 2.9
conflicts with the Secretas Orbit Patch and recommends Better Asteroid Belt
(`kry-asteroid-belt`), conflicting with Razi's own asteroid crossings.

The curated 2.1.75 profile excludes Outer Rim (`!`), retains its own two
asteroid belts, and stops recommending the weather add-on until upstream
releases are reconciled. The base weather fork remains recommended. The
upstream dependency listing of Weather Additions 1.3.0 states it requires
Weather Updated, unlike the user's installed 1.6.0, so no blanket claim
about all versions is appropriate.

Factorio cannot automatically remove incompatible already-installed mods.
Disable **Outer Rim**, **Better Asteroid Belt**, and **Celestial Weather
Additions 1.6.0** in Mod Manager. The 24 remaining recommendations have
not undergone an exhaustive Factorio-engine test together. Test high-impact
content (Shattered Planet, Void Processing, Ferrum, Solar Halo)
in a separate copied-save profile, retaining manual CI runs.

## Hephaestus exclusion (15 October 2026)

Hephaestus is now `! Hephaestus` instead of recommended. The source mod's
oversized H icon cluster and label obscure the star map, and Razi does not
need its megastructure for campaign progression. Razi's special-location
integration has been retired. An already enabled Hephaestus mod must still
be disabled in Factorio's Mod Manager; Razi cannot uninstall it.

## Staff collaboration decisions, 2.1.79

- **Frozeta: Nuclear Winter 1.12.1+** is recommended as an independent
  companion. Outer Rim requires Nuclear Winter, **not vice versa**; Razi
  still excludes Outer Rim and Better Asteroid Belt.
- **Celestial Weather Next 1.6.0** (`celestial-weather-additions-updated`)
  replaces the old `celestial-weather-updated` recommendation because Next
  combines weather and additions and expressly conflicts with the separate fork.
- **Eneas 1.0.10+** and **Shchierbin 0.3.19+** are user-selected optional
  worlds, with guarded routes but no required new science or core planets.
  Eneas retains its author-owned Unit-05 and launch gantry; Shchierbin
  receives an exterior Vibrant placement linked only to Paracelsin.
- **Historical 2.1.79 decision:** Nulla 1.0.2 and Planet Athos 1.1.3
  were blocked after their original full-pack failures. In 2.1.80 they moved
  to experimental opt-in status with guarded code (documented below);
  neither is certified by a real Factorio engine smoke test.

## 2.1.80: Experimental Nulla/Athos rescue

Both new worlds are now **manual opt-ins**: `? nulla >= 1.0.2` and
`? PlanetAthos >= 1.1.3`. They are not recommended or required.
Nulla's upstream radio-interference pass calls an energy helper with a missing
`electric-furnace` prototype; Razi attempts to make its cached source helper
nil-safe in `data-updates`, ahead of Nulla's `data-final-fixes`. It never
creates a dummy furnace or changes the author's radioactive environment.
Athos uses an early and late technology-cycle guard, which removes only an
Athos/particulate-owned arrow proven to be on a loop. Unrelated K2SO research
is untouched and logged if a conflict remains. If a source mod throws inside
its own earlier final-fixes traversal, we will need a corrected source release
or a separate earlier-loading patch. In-game testing is still outstanding.

## 2.1.81: Core Athos and Nulla science worlds

Athos and Nulla are now **required** campaign planets. Athos preserves its
original Crushing Industry, earthquakes, diamond/carbon economy and native
Particulate Science. Nulla preserves Aquilo's satellite orbit, radioactive
radio-interference ecology, hostile drones, scrap and native Robotic Science.

The new **Frontier Recovery Charter** discovers real Athos/Nulla science
unlock technologies and requires both science packs at an existing late-tier
lab before the outer-frontier mastery. Their native discovery recipes and
research are not replaced with Razi-owned science. If the author's science
technology is missing or renamed beyond recognition, the bridge is omitted
and logs the missing source ID rather than inserting an impossible gate.

This release still requires a **complete Factorio 2.1/K2SO engine startup and
copied-save validation**. Earlier versions of both required mods produced
source-stage failures, and Razi's guards have not been proven by a full load.
