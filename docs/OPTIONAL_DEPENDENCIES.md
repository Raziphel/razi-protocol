# Optional dependency audit

Razi Protocol now advertises optional dependencies only when it contains
an actual integration or compatibility patch. The `+` recommended planet
adventures remain unchanged. Removing an optional declaration does **not**
remove or block a mod the player has installed; it stops suggesting that Razi
Protocol directly integrates it or needs ordering against it.

## Removed from info.json (45)

- `assets-eneas >= 1.0.2`
- `spidertron-unit-07`
- `mferrari_lib >= 0.7.5`
- `informatron >= 0.5.0`
- `terrapalus`
- `slp-dyson-sphere-reworked`
- `celestial-weather-updated`
- `celestial-weather-additions-updated`
- `Cold_biters_K2_compatibility >= 1.0.3`
- `Explosive_biters_K2_compatibility >= 1.0.3`
- `Toxic_biters_K2_compatibility >= 1.0.3`
- `castra-prime-k2-turret-ammo-fix`
- `visible-planets >= 1.8.2`
- `Construction_Drones_Forked >= 1.1.18`
- `RPGsystem >= 2.1.3`
- `kr-air-purifier-helper`
- `rubia-minus-memes >= 1.1.0`
- `StatsGui`
- `shield-projector >= 0.3.0`
- `turret-activation-delay >= 0.3.5`
- `LogisticTrainNetwork >= 3.2.1`
- `LTN_Combinator_Modernized >= 2.5.0`
- `LtnManager >= 0.6.0`
- `NapalmArtillery >= 2.1.0`
- `Noxys_Swimming`
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
- `rocket-reusability`
- `BetterAquilo >= 7.3.0`
- `CircularColliderLab >= 7.3.0`
- `Quality-Asteroids-Expanded >= 1.2.5`
- `cargo-bay-inserters >= 1.3.0`
- `spiderbots`
- `Tenebris_plants_retexture`

## Still declared (13)

- `Arachnids_enemy`
- `ArmouredBiters21Compat`
- `Cerys-Moon-of-Fulgora`
- `Electric_flying_enemies`
- `Explosive_biters`
- `Imersite-Asteroids`
- `LithiumBattery`
- `Nexus-Updated`
- `Toxic_biters`
- `VoidProcessing-Updated`
- `dea-dia-system`
- `moon-eneas`
- `pelagos`

These are retained for work with optional planetary locations, star routes,
Cerys/Eneas, later chapter research, conditional enemy placement, the Nexus
and Void expeditions, K2SO/LithiumBattery compatibility, and Imersite asteroids.
The independent recommended planet mods remain as `+` dependencies and
need their own full-engine testing.
