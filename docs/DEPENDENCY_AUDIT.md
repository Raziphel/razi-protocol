# Razi Protocol: full dependency audit (2.1.65)

Reviewed 14 October 2026. Every direct manifest declaration is registered with type, group, version floor and justification in [`compat/dependency_policy.json`](../compat/dependency_policy.json).

| Type | Entries | Intent |
| --- | ---: | --- |
| required | 49 | Essential engine, curated campaign and K2SO compatibility |
| recommended | 10 | Useful but removable companions |
| optional | 14 | Experimental or conditional content |
| incompatible | 22 | Known competing or broken mods |

## Classification decisions

K2SO, its source assets, the physical transceiver, Razi Library, PlanetsLib, the Dyson network, and the currently curated campaign worlds remain required. Some worlds have guarded code but are still required by campaign design, so a smaller playable profile would need separate progression changes.

Nexus-Updated remains part of the curated required world set. Nexus Threat and Big Monsters are recommended; the separate Nexus Bosses mod brings in its own required monster/enemy dependencies when enabled. Do not add a direct Nexus Bosses declaration while that addon has an optional dependency on Razi Protocol.

The weather pair, Planet Express, upgraded rocket turrets, Science Tab and Frost Biters are recommended. Science Tab's previously unconditional science item-group assumption was removed, allowing Razi's system cards to use Intermediate Products when Science Tab is absent.

FluxWorks, Dea Dia, Pelagos, alternate routes and other experimental side worlds remain optional. Incompatible route overlays, outdated planet forks and conflicting engines stay explicitly blocked. A '+' recommendation never overrides another mod's hard dependencies.

## Every direct manifest entry

| Declaration | Audit category |
| --- | --- |
| **Engine** | **2 entries** |
| `base >= 2.1.20` | required |
| `space-age >= 2.1.20` | required |
| **Direct libraries** | **2 entries** |
| `razi_lib >= 1.1.0` | required |
| `PlanetsLib >= 2.0.9` | required |
| **K2SO core** | **2 entries** |
| `Krastorio2-spaced-out >= 2.0.17` | required |
| `Krastorio2Assets >= 2.1.0` | required |
| **Dyson project** | **2 entries** |
| `slp-dyson-sphere-reworked-fork >= 1.0.5` | required |
| `k2-dyson-sphere-rebalance >= 0.1.2` | required |
| **Deep Space curated** | **2 entries** |
| `bellicos-and-aegis >= 0.4.0` | required |
| `Nexus-Updated >= 1.4.1` | required |
| **K2SO compatibility** | **8 entries** |
| `corrundum-krastorio-compatibility-plus >= 1.1.2` | required |
| `castra-krastorio-compatibility-plus >= 1.1.0` | required |
| `k2so-cubium-compatibility-fork >= 0.3.5` | required |
| `nulls-k2so-tweaks >= 2.3.1` | required |
| `xy-k2so-enhancements-nulls-fork >= 0.8.5` | required |
| `rubia-krastorio-compatibility-plus >= 1.3.1` | required |
| `tenebris-prime-made-in-hide >= 1.1.0` | required |
| `paracelsin-krastorio-compatibility-plus >= 1.2.0` | required |
| **Required campaign planets** | **31 entries** |
| `planet-muluna >= 2.7.25` | required |
| `planetaris-unbounded >= 1.9.1` | required |
| `planetaris-tellus >= 1.1.11` | required |
| `planetaris-hyarion >= 1.3.23` | required |
| `planetaris-arig >= 1.1.44` | required |
| `Cerys-Moon-of-Fulgora >= 4.24.17` | required |
| `linox >= 1.8.9` | required |
| `Muria >= 1.8.6` | required |
| `corrundum >= 1.0.49` | required |
| `apia >= 0.3.1` | required |
| `Moshine >= 1.2.10` | required |
| `panglia_planet >= 0.7.2` | required |
| `tenebris-prime >= 1.3.12` | required |
| `secretas >= 1.0.37` | required |
| `maraxsis >= 1.39.1` | required |
| `rubia >= 0.69.159` | required |
| `cubium >= 1.0.31` | required |
| `skewer_planet_vesta >= 2.1.27` | required |
| `castra-prime >= 0.9.2` | required |
| `planet-crucible >= 1.1.27` | required |
| `ribbonia >= 0.6.8` | required |
| `Paracelsin >= 1.10.2` | required |
| `Igrys >= 1.5.40` | required |
| `planet-rabbasca >= 0.22.2` | required |
| `foliax >= 2.0.37` | required |
| `obsidiax >= 1.0.29` | required |
| `carna >= 0.3.22` | required |
| `Velora >= 2.2.2` | required |
| `alchemy-khemia >= 0.3.6` | required |
| `Arcanyx >= 1.1.5` | required |
| `biological-machines-planet-balack >= 1.1.2` | required |
| **Recommended companions** | **10 entries** |
| `+ aai-signal-transmission >= 0.6.0` | recommended |
| `+ planet-express >= 2.1.9` | recommended |
| `+ upgraded-rocket-turrets >= 2.1.1` | recommended |
| `+ celestial-weather-updated >= 1.5.1` | recommended |
| `+ celestial-weather-additions-updated >= 1.3.1` | recommended |
| `+ Cold_biters >= 2.3.0` | recommended |
| `+ Imersite-Asteroids >= 1.3.0` | recommended |
| `+ science-tab >= 1.13.0` | recommended |
| `+ Nexus-Threat-Updated >= 1.1.0` | recommended |
| `+ Big-Monsters >= 2.2.1` | recommended |
| **Opt-in extras** | **14 entries** |
| `? FluxWorks >= 0.2.12` | optional |
| `? dea-dia-system` | optional |
| `? pelagos` | optional |
| `? secretas-orbit-patch >= 1.1.3` | optional |
| `? outer-rim` | optional |
| `? VoidProcessing-Updated` | optional |
| `? ArmouredBiters21Compat` | optional |
| `? Explosive_biters >= 2.4.0` | optional |
| `? LithiumBattery >= 7.3.0` | optional |
| `? rabbasca-underground >= 0.10.3` | optional |
| `? skewer_shattered_planet >= 1.0.42` | optional |
| `? Solar-Halo >= 1.2.0` | optional |
| `? planet-ferrum >= 0.1.4` | optional |
| `? Hephaestus >= 0.3.7` | optional |
| **Excluded conflicts** | **22 entries** |
| `! AsteroidBelt` | incompatible |
| `! space-route-overlay` | incompatible |
| `! kry-asteroid-belt` | incompatible |
| `! moon-eneas` | incompatible |
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
| `! nulla` | incompatible |
| `! PlanetAthos` | incompatible |
| `! biological-machines-planet-wit` | incompatible |
| `! shchierbin` | incompatible |

## Compatibility and acceptance

This review covers all direct dependencies, not the complete recursive graph of every installed mod. Supported sources and the Mod Portal were checked for high-impact companions. A full Factorio 2.1 game-engine load and a copied existing-save playtest are still outstanding.

Run the offline checks locally, without triggering GitHub Actions:

```bash
python3 -m unittest discover -s tests -p 'test_dependency_policy.py'
python3 -m unittest discover -s tests -p 'test_source_ownership.py'
python3 -m unittest discover -s tests -p 'test_nexus_weather_pack.py'
```

Always back up existing saves before changing enabled mods, even if a dependency is optional. The exact version floors and compatibility declarations are preserved.
