## Recommended optional companions (2.1.64)

Factorio 2.1 supports a `+ ` prefix in `info.json` for
**recommended dependencies**. This is different from a hard requirement:
players can still use Razi Protocol without the companion mod.

The first curated recommendations are:

| Mod | Why it is recommended | Required minimum |
| --- | --- | --- |
| AAI Signal Transmission | Integrated cross-planet circuit networks, guarded Razi industry research, Cargo Network guidance and an optional Codex objective | 0.6.0 |
| Imersite Asteroids | Source-owned K2SO asteroid mining integrated with Razi's original asteroid corridors and mid/late-game Imersite access | 1.3.0 |

The two current Mod Portal releases support Factorio 2.1, and their
version floors exist publicly. No new recipes, worlds, dependencies,
save data or Razi code paths are introduced by this change.
Disabling either recommended mod must remain supported.

**Not yet recommended:** FluxWorks requires `>= 0.2.12` in Razi
Dev but its latest publicly listed release at the time of this review
is 0.2.10 and its companion integration still needs end-to-end
testing. Dea Dia and Pelagos remain 2.0-only Mod Portal releases.
The Secretas/Frozeta orbit patch is optional because of Outer Rim
compatibility, and Solar Halo / the larger optional planets need a
full 2.1 route-and-research validation pass before promotion.

Recommended means a curated suggestion, not a claim that adding or
removing a mod is save-safe. Always back up an active game before
changing the enabled mod set.

## Restored optional integration in 2.1.53

`aai-signal-transmission >= 0.6.0` is again declared as an **optional**
dependency because this release now contains an actual guarded research
handoff, source-research-tracked Codex goal and Cargo Network guidance.
It is not downloaded automatically as a required dependency, and no
AAI transmission code or art is redistributed. The retired dependency
list further below records the previous audit and is historical.

# Optional dependency audit

Razi Protocol now advertises optional dependencies only when it contains
an actual integration or compatibility patch. The `+` recommendations listed above are deliberate;
additional optional planets remain opt-in. Removing an optional declaration does **not**
remove or block a mod the player has installed; it stops suggesting that Razi
Protocol directly integrates it or needs ordering against it.

## Removed from info.json or explicitly blocked (46)

- `assets-eneas >= 1.0.2`
- `moon-eneas >= 1.0.10` (blocked as incompatible)
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

## Still declared (12)

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
- `pelagos`

These are retained for work with optional planetary locations, star routes,
Cerys, later chapter research, conditional enemy placement, the Nexus
and Void expeditions, K2SO/LithiumBattery compatibility, and Imersite asteroids.
The independent recommended planet mods remain as `+` dependencies and
need their own full-engine testing.
