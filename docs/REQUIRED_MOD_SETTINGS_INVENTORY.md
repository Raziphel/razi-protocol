# Razi v3 required-mod setting inventory

All 51 direct hard requirements from `info.json`.
This is a **source-ID mapping inventory** for the optional external
synchronizer, not a claim that every mod has writable settings.

| Hard-required mod | Curated setting IDs | Coverage |
| --- | ---: | --- |
| `base` | 0 | No curated mapping yet |
| `space-age` | 0 | No curated mapping yet |
| `razi_lib` | 0 | No curated mapping yet |
| `razi-rocket-reusability` | 1 | Mapped source setting IDs |
| `PlanetsLib` | 0 | No curated mapping yet |
| `bellicos-and-aegis` | 0 | No curated mapping yet |
| `Krastorio2-spaced-out` | 1 | Mapped source setting IDs |
| `slp-dyson-sphere-reworked-fork` | 0 | No curated mapping yet |
| `k2-dyson-sphere-rebalance` | 0 | No curated mapping yet |
| `Krastorio2Assets` | 0 | No curated mapping yet |
| `planet-muluna` | 5 | Mapped source setting IDs |
| `planetaris-unbounded` | 0 | No curated mapping yet |
| `planetaris-tellus` | 0 | No curated mapping yet |
| `planetaris-hyarion` | 0 | No curated mapping yet |
| `planetaris-arig` | 0 | No curated mapping yet |
| `Cerys-Moon-of-Fulgora` | 2 | Mapped source setting IDs |
| `linox` | 0 | No curated mapping yet |
| `Muria` | 0 | No curated mapping yet |
| `corrundum` | 0 | No curated mapping yet |
| `corrundum-krastorio-compatibility-plus` | 0 | No curated mapping yet |
| `apia` | 0 | No curated mapping yet |
| `Moshine` | 0 | No curated mapping yet |
| `panglia_planet` | 0 | No curated mapping yet |
| `tenebris-prime` | 4 | Mapped source setting IDs |
| `secretas` | 0 | No curated mapping yet |
| `maraxsis` | 0 | No curated mapping yet |
| `rubia` | 2 | Mapped source setting IDs |
| `cubium` | 0 | No curated mapping yet |
| `Nexus-Updated` | 0 | No curated mapping yet |
| `skewer_planet_vesta` | 0 | No curated mapping yet |
| `castra-prime` | 0 | No curated mapping yet |
| `castra-krastorio-compatibility-plus` | 0 | No curated mapping yet |
| `planet-crucible` | 0 | No curated mapping yet |
| `ribbonia` | 0 | No curated mapping yet |
| `Paracelsin` | 0 | No curated mapping yet |
| `k2so-cubium-compatibility-fork` | 0 | No curated mapping yet |
| `nulls-k2so-tweaks` | 0 | No curated mapping yet |
| `xy-k2so-enhancements-nulls-fork` | 0 | No curated mapping yet |
| `rubia-krastorio-compatibility-plus` | 0 | No curated mapping yet |
| `tenebris-prime-made-in-hide` | 0 | No curated mapping yet |
| `paracelsin-krastorio-compatibility-plus` | 0 | No curated mapping yet |
| `Igrys` | 0 | No curated mapping yet |
| `foliax` | 0 | No curated mapping yet |
| `obsidiax` | 0 | No curated mapping yet |
| `carna` | 0 | No curated mapping yet |
| `Velora` | 0 | No curated mapping yet |
| `alchemy-khemia` | 0 | No curated mapping yet |
| `Arcanyx` | 0 | No curated mapping yet |
| `biological-machines-planet-balack` | 0 | No curated mapping yet |
| `nulla` | 0 | No curated mapping yet |
| `PlanetAthos` | 0 | No curated mapping yet |

The 6 mapped mods define
15 currently curated settings. Of those,
12 are startup
settings and 3
are Map/runtime defaults (opt-in, new saves only).

**Important:** No source-mod settings are rewritten by Razi's native Lua
difficulty code. The `tools/razi_settings_sync.py` program acts only
when manually invoked after Factorio closes, with `--apply`, after
verifying installed mod files, and only for curated setting IDs.

A mod marked "No curated mapping yet" might expose no difficulty
controls, source settings that are unsuitable for difficulty automation,
or controls that have not yet been source-verified. No names are guessed.

## Mapping sources

- Muluna: `nicholasgower/planet-muluna/settings.lua`
- Tenebris Prime: `nicholasgower/tenebris-prime/settings.lua`
- Rubia: `LoupAndSnoop/rubia/settings.lua`
- Cerys: `danielmartin0/Cerys-Moon-of-Fulgora/settings.lua`
- K2SO: `Polka37/Krastorio2-Spaced-Out/settings.lua`
- Razi Rocket Reusability: `Raziphel/razi-rocket-reusability/settings.lua`

Mapping real values requires checking the *installed* mod version. See
[foreign settings sync instructions](FOREIGN_MOD_SETTINGS.md).
