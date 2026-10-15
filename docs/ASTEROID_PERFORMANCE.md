# Optional Asteroid Performance Profiles (Razi Protocol Dev 2.1.106)

All four performance settings are **OFF by default** and are independent
startup options in **Performance Experiments**. Nothing is installed from
another mod or enabled without player consent. Every pass runs once at
data-final-fixes, after the source asteroid integrations and Razi's
Level 1–10 quality-carrier setup. Zero event handlers or timers are added.

## Research and decisions

These are original guarded implementations **inspired by**, not copies
of, external Factorio mods.

| Reference | Key technique | Razi integration | Caveat |
| --- | --- | --- | --- |
| UPS Friendly Asteroids (RockPaperKatana, MIT, 2.0) | Reduces spawned fragment entities in exchange for lower harvest/entity cost | Reduced native fragmentation, optional | Its author declined a 2.1 port, noting improved chunk performance. Expect smaller benefits and reduced resource yields. |
| Remove Asteroid Particles / Remove Asteroid Particles 2.1 (RockPaperKatana/Valoneu) | Suppresses cosmetic asteroid shrapnel | Reduce asteroid particles, optional | Original was deprecated after engine offscreen optimizations; mostly an FPS-oriented switch. |
| Remove Weapon Particles / its 2.1 continuation (RockPaperKatana/Valoneu) | Removes visual particle spam from projectiles | Reduce weapon particles, optional | Does not remove physical projectile entities, weapon damage, source explosions or gameplay effects. |
| Particle Free Disposal (abucnasty, Factorio 2.1) | Selective visual effect suppression | Conservative selected particle filters | It primarily removes chest/railgun and biter effects; unrelated effects are intentionally excluded here. |
| Safer Asteroids and Disable All Asteroids (Kryzeth) | Changes asteroid spawn size/frequency | Reduce hostile density only on Level 8–10 areas, optional | Does not remove ALL asteroids or downgrade the challenge scale: those would break Razi's progression/harvest loops. |
| UPS Friendly Pulse Collectors (deprecated) | Replaces engine collectors with scripted ones | NOT transplanted | The mod author reports native collectors became competitive in Factorio 2.0.26; script-based replacement is especially risky in 2.1. |

### Four settings

1. **Reduce asteroid destruction particles**: removes cosmetic
   `create-particle` and `create-trivial-smoke` effects from hostile
   asteroids and collectible chunks. No drop trigger, script trigger,
   collision or damage effects are removed.
2. **Reduce weapon impact particles**: removes only the same cosmetic
   effect kinds from projectiles, artillery projectiles and beams.
   Missile damage, hitboxes, explosion entities and gameplay visuals
   with special meaning remain untouched.
3. **Fewer native asteroid fragments**: for Big/Huge vanilla metallic,
   carbonic, oxide and promethium hostile asteroids, halves the chance
   of native `create-asteroid-chunk` effects. This *does reduce mined
   fragment yields*. Imersite chunks and Secretas's custom Auric
   asteroid fragmentation are excluded. Do not use when trying to
   maximize Promethium harvest.
4. **Reduce deep-space hostile density**: scales actual hostile spawn
   probabilities to 72% only for Level 8–10 connection/orbit regions.
   It does NOT alter pre-existing collectible chunk spawn probabilities
   or the per-enemy quality grade, and does not lower the campaign's
   ten-level danger labels. It does change the number of enemies
   attacking and therefore makes some late-game routes easier.

Unlike the 2.0 fragment mods, Razi does **not** modify chunk mining
items, source crusher recipes, quality tiers, chest behavior, or
collector animation timings. There is no promise of UPS gains:
benchmark a repeatable save with F4 debug timings, 60-second idle/flight
samples, and identical active platforms before adopting a switch.

## Compatibility safeguards

- The default path exits without touching prototypes or registering
  runtime events.
- Visual-only effects are deep-copied before removal so source-mod shared
  trigger tables retain their contents.
- Cosmetic-only wrappers are removed completely instead of leaving
  broken trigger structures. Damage, script, generated asteroid
  chunks and real entity effects survive.
- Modded/Auric fragmentation and natural Imersite resource fields retain
  source-author intent. Full Level 10 Legendary encounter logic still
  exists when hostile-density reduction is active.
- Hostile density edits copy asteroid spawn definitions first, never
  write into the source mod's shared table.
- All changes require restarting Factorio. Existing saves keep IDs,
  recipe progression, planets, starmap routes and technology.
- For safety, avoid enabling simultaneously with external mods that
  mutate the same asteroid triggers. Razi does not force or declare
  these mods as dependencies.

## Validation

`lua tests/lua/test_asteroid_performance.lua`
`python3 -m unittest tests.test_asteroid_performance`

A real Factorio 2.1 modpack startup and repeated gameplay benchmark
are still required to check prototype acceptance and measure whether
these settings improve the actual ship's UPS/FPS. Do not interpret
a shorter route spawn table as a measured engine optimization.

External references:
- https://mods.factorio.com/mod/UPS_Friendly_Asteroids
- https://mods.factorio.com/mod/RemoveAsteroidParticles2_1
- https://mods.factorio.com/mod/RemoveWeaponParticles2_1
- https://mods.factorio.com/mod/particle_free_disposal
- https://mods.factorio.com/mod/kry-safer-asteroids
- https://mods.factorio.com/mod/UPS_Friendly_Pulse_Collectors
