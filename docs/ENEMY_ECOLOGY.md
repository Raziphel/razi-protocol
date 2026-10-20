# Razi Protocol 3.0: planet-scoped hostile ecology (2.1.130)

## Principles

- **Additive, not replacement:** introducing a modded biter nest never removes
  vanilla biters, worms, or a destination's source-native fauna.
- **No shared-spawner terrain mutation:** a newly placed hostile species uses
  a `razi-<planet>-<source-spawner>` clone with the original sprites, result
  units, attacks and AI. Only its static mapgen expression and tile restriction
  are changed for its target planet.
- **Validated source content only:** required mod must be installed, source
  entity must have valid natural autoplace, destination planet must exist,
  and that planet must expose registered solid terrain tiles. Missing mods and
  missing/invalid prototypes are skipped, without placing broken nest records.
- **Sparse specializations:** non-Nexus worlds get regular and small/medium
  specialty worms; huge worm tiers are reserved for Nexus, not freely
  distributed on early-game planets. Native density and RP3 difficulty keep
  their authority, with each added family using low probability weights.
- **World-generation only:** nothing is spawned in runtime on every tick.
  New territory requires unexplored chunks in an existing save; prototype
  updates cannot repopulate already-generated empty or explored areas.

## Intended new locations

| Family | Planet placements (when installed) |
|---|---|
| Armoured | Hyarion, Crucible, Castra, Athos, Ferrum, Obsidiax, Nexus |
| Cold | Aquilo, Frozeta, Shchierbin, Vesta, Muria, Balack, Nexus |
| Explosive | Moshine, Cubium, Corrundum, Crucible, Obsidiax, Nexus |
| Toxic | Cubium, Vesta, Paracelsin, Rabbasca, Foliax, Gleba, Velora, Khemia (`alchemy-planet`), Crucible, Nexus |
| Arachnids | Arig, Crucible, Castra, Athos, Panglia, Tenebris, Nexus |
| Electric | Corrundum, Ribbonia, Fulgora, Ferrum, Cerys, Khemia (`alchemy-planet`), Nexus |

*Native fauna and source mod destination controls remain in place.
Do not attach additional nests to space locations or moons without a
`planet.map_gen_settings` terrain map.*

## Nexus

Nexus remains the endgame **combined ecosystem**, not an exclusive
replacement biter planet. Its world generation includes native biter/spitter
and worm types through isolated nesting variants, all available installed
specialist families, source-derived Gleba pentapod egg rafts, and Vulcanus
demolisher territory rules only if the required segmented-unit prototypes
exist and the destination has no conflicting territory settings.

The copied demolisher noise/territory fields need to be inspected in a real
Factorio world because some Vulcanus noise definitions may depend on
Vulcanus-only map expressions. No fake segmented-unit autoplace or
per-tick spawning fallback is installed.

## Compatibility and performance checks

- The original enemy pack's nest `autoplace` definition is not changed by
  final RP3 ecology; its home-world biome remains independent.
- Existing source-owned controls are not overwritten when multiple
  integrations share a world.
- Water, lava, void, empty space and other non-land map tiles are excluded.
  If a planet introduces new tile names, only its actual registered land
  can be considered for placement.
- Validate a fresh chunk on representative planets (Ferrum, Obsidiax,
  Panglia, Gleba, Aquilo and Nexus), especially terrain-specific noise and
  species balance. Watch chunk-generation time and UPS with Nexus's full
  enemy roster. Avoid increasing density until these checks pass.
