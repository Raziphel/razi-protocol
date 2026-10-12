# Factorio 2.1 compatibility audit

Audit date: 21 September 2026 (PlanetsLib minimum updated 8 October 2026)

Razi Protocol now declares Factorio 2.1. Every direct dependency was checked against the official Factorio Mod Portal, and the required dependency graph was followed recursively. A release counts as compatible here only when its own `info.json` declares `factorio_version` 2.1; a 2.0 release was not assumed to work.

## Result

- 94 direct positive dependencies were audited: 77 have native Factorio 2.1 releases and 17 do not.
- 190 portal mods were inspected across the direct dependency set and its required transitive dependencies.
- 102 portal-hosted mods remain on the required load path, and all 102 have native 2.1 releases. Factorio's bundled `quality` and `recycler` feature modules are also reached transitively.
- Built-in `base` and `space-age` are supplied by Factorio 2.1 and remain required.
- Incompatible (`!`) declarations were retained, with duplicate declarations removed.

The required pack now has a fully native Factorio 2.1 dependency path, including RAZI Library 1.0.0 as a required shared code foundation. Five formerly required 2.0-only integrations are retained as optional dependencies, so their compatibility support remains available if they publish 2.1 releases later.

## Direct dependencies with native 2.1 releases

The minimum versions below are now recorded in `info.json`.

### Required

- `PlanetsLib >= 2.0.0`
- `bellicos-and-aegis >= 0.4.0`
- `Krastorio2-spaced-out >= 2.0.17`
- `Krastorio2Assets >= 2.1.0`
- `planet-muluna >= 2.7.25`
- `planetaris-unbounded >= 1.9.1`
- `planetaris-tellus >= 1.1.11`
- `planetaris-hyarion >= 1.3.23`
- `planetaris-arig >= 1.1.44`
- `linox >= 1.8.9`
- `shchierbin >= 0.3.19`
- `Muria >= 1.8.6`
- `corrundum >= 1.0.49`
- `apia >= 0.3.1`
- `Moshine >= 1.2.10`
- `panglia_planet >= 0.6.1`
- `tenebris-prime >= 1.3.12`
- `secretas >= 1.0.37`
- `maraxsis >= 1.39.1`
- `rubia >= 0.69.159`
- `cubium >= 1.0.31`
- `skewer_planet_vesta >= 2.1.27`
- `castra-prime >= 0.9.2`
- `castra-krastorio-compatibility-plus >= 1.1.0`
- `planet-crucible >= 1.1.27`
- `ribbonia >= 0.6.8`
- `Paracelsin >= 1.10.2`
- `Cold_biters >= 2.3.0`
- `k2so-cubium-compatibility-fork >= 0.3.5`
- `nulls-k2so-tweaks >= 2.3.1`
- `xy-k2so-enhancements-nulls-fork >= 0.8.5`
- `science-tab >= 1.13.0`
- `rubia-krastorio-compatibility-plus >= 1.3.0`
- `tenebris-prime-made-in-hide >= 1.1.0`
- `paracelsin-krastorio-compatibility-plus >= 1.2.0`

### Optional

- `Cerys-Moon-of-Fulgora >= 4.24.17`
- `moon-eneas >= 1.0.10`
- `assets-eneas >= 1.0.2`
- `mferrari_lib >= 0.7.5`
- `informatron >= 0.5.0`
- `Arachnids_enemy >= 1.2.1`
- `Electric_flying_enemies >= 0.2.0`
- `Explosive_biters >= 2.4.0`
- `Toxic_biters >= 2.1.0`
- `Imersite-Asteroids >= 1.3.0`
- `Cold_biters_K2_compatibility >= 1.0.3`
- `Explosive_biters_K2_compatibility >= 1.0.3`
- `Toxic_biters_K2_compatibility >= 1.0.3`
- `visible-planets >= 1.8.2`
- `Construction_Drones_Forked >= 1.1.18`
- `RPGsystem >= 2.1.3`
- `rubia-minus-memes >= 1.1.0`
- `shield-projector >= 0.3.0`
- `turret-activation-delay >= 0.3.5`
- `LogisticTrainNetwork >= 3.2.1`
- `LTN_Combinator_Modernized >= 2.5.0`
- `LtnManager >= 0.6.0`
- `NapalmArtillery >= 2.1.0`
- `bullet-trails >= 0.8.0`
- `even-distribution >= 2.1.0`
- `squeak-through-2 >= 0.2.0`
- `robot_attrition >= 0.7.0`
- `CleanedConcrete >= 2.1.0`
- `better-victory-screen >= 2.1.0`
- `Aircraft-space-age >= 2.3.5`
- `aai-signal-transmission >= 0.6.0`
- `aai-industry >= 0.7.4`
- `assembler-group >= 1.2.0`
- `AutoDeconstruct >= 1.1.2`
- `enemy-alert >= 1.2.0`
- `UPSFriendlyNixieTubeDisplay >= 0.4.1`
- `BetterAquilo >= 7.3.0`
- `LithiumBattery >= 7.3.0`
- `CircularColliderLab >= 7.3.0`
- `Quality-Asteroids-Expanded >= 1.2.5`
- `cargo-bay-inserters >= 1.3.0`

## Direct dependencies without native 2.1 releases

These declarations intentionally remain in `info.json` without invented 2.1 version constraints.

### Formerly required integrations, now optional

| Mod | Latest portal release | Declared Factorio version | Required 2.0-only dependencies |
| --- | ---: | ---: | --- |
| `dea-dia-system` | 0.36.0 | 2.0 | `bioprocessing-tab` 1.5.0, `Robocharger-Updated` 0.0.1 |
| `pelagos` | 0.59.0 | 2.0 | `lubrication_tower` 0.4.0, `pirateship` 0.0.4; `lubrication_tower` requires `zzz-nonstandard-beacons` 1.4.2 |
| `Nexus` | 1.3.4 | 2.0 | `Nexus-Graphics` 0.0.8, `Nexus-Threat` 1.0.6 |
| `celestial-weather` | 1.4.0 | 2.0 | None beyond the listed direct blocker |
| `celestial-weather-additions` | 1.2.1 | 2.0 | `celestial-weather` 1.4.0 |

### Other optional blockers

| Mod | Latest portal release | Declared Factorio version |
| --- | ---: | ---: |
| `ArmouredBiters` | 2.0.2 | 2.0 |
| `castra-prime-k2-turret-ammo-fix` | 1.0.0 | 2.0 |
| `kr-air-purifier-helper` | 2.0.6 | 2.0 |
| `Noxys_Swimming` | 0.5.3 | 2.0 |
| `rocket-reusability` | 1.0.7 | 2.0 |
| `slp-dyson-sphere-reworked` | 1.0.4 | 2.0 |
| `spiderbots` | 0.3.2 | 2.0 |
| `spidertron-unit-07` | 0.1.0 | 2.0 |
| `StatsGui` | 1.6.1 | 2.0 |
| `Tenebris_plants_retexture` | 1.0.0 | 2.0 |
| `terrapalus` | 0.2.8 | 2.0 |
| `VoidProcessing` | 2.0.3 | 2.0 |

## Loader validation

A required-only installation containing all 103 native dependencies plus Factorio's built-in dependencies was staged under Factorio 2.1.19. `--dump-data` completed successfully through settings, every data stage, final prototype validation, and data dump generation.

That validation exposed two Razi-owned compatibility issues, which are now fixed:

- Recipe rewrites now use Factorio 2.1's `categories` schema and clear conflicting legacy `category` / `additional_categories` fields.
- Regular labs explicitly accept the normal system tech cards, so removing Nexus does not leave required discovery technologies with no compatible lab.

The optionalization pass added presence checks around Dea Dia and Pelagos starmap changes, a standalone Pelagos technology fallback, and a non-Nexus Deep Space card unlock fallback. Nexus runtime migration code was already correctly guarded through `script.active_mods`.

### Optional integration diagnostics

Temporary diagnostic copies of the 2.0-only optional integrations were also staged under Factorio 2.1.19 by bypassing their version declarations. Those copies were not committed or treated as compatible releases.

The diagnostic run found these third-party problems after bypassing version declarations:

- Nexus uses the removed global `assembler2pipepictures`; in 2.1 the helper must be imported from the base assembler-picture module.
- Pelagos imports the removed `__base__.prototypes.entity.biter-ai-settings` module and reads the removed `defines.default_icon_size` value.
- Pelagos requires both `barreling-group2` and `barreling_machines`, while the current `barreling_machines` release declares `barreling-group2` incompatible.
- `cargo_crates` 0.12.0 crashes while ordering recipes when a recipe category is missing from `data.raw["recipe-category"]` in this combined stack.
- After a diagnostic guard for that crash, the composed Dea Dia/Paracelsin/Krastorio/Maraxsis/Rigor recipe stack leaves `engine-unit` with both the old `category` and `additional_categories` fields, which Factorio 2.1 requires to be represented by `categories`.

These third-party failures cannot be fixed safely in Razi Protocol without maintaining forks. They no longer block the required pack because the affected integrations are optional, but those optional branches should not be enabled on Factorio 2.1 until compatible upstream releases or maintained replacements exist.
