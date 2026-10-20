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

## Difficulty-aware habitat coverage (2.1.131)

There are now **six startup habitat settings**, one for each enemy family.
Each defaults to **Follow difficulty** and also allows **Off / Limited / Curated / Expanded / All**.
The overarching RP3 difficulty maps to these levels automatically:

| Master difficulty | Habitat reach |
|---|---|
| Easy | Limited: 1 primary world per family |
| Normal (default) | Curated: 2–4 logical worlds per family |
| Hard | Expanded: most eligible planets |
| Nightmare | All: every planet in each family roster |

Nexus remains an eligible **all-families endgame** planet for any enabled
level. The explicit Off mode disables RP3's extra placements for a family,
including Nexus, but **never deletes original source-mod spawn definitions**.
Manual family settings count as Custom difficulty, without modifying other
mod settings. Preset/worldgen decisions happen when Factorio loads prototypes;
existing chunks are not retroactively filled.

The original early integration scripts no longer pre-register extras on
planets, so lower difficulties do not accidentally inherit all families.
If a source mod naturally registers an enemy on a world, that original
spawn remains regardless of RP3 habitat selection.

### Exact tier rosters, excluding Nexus

| Family | Easy (Limited) | Normal (Curated) | Hard (Expanded) | Nightmare (All) |
|---|---|---|---|---|
| Armoured | Hyarion | Hyarion, Castra, Athos | +Crucible, Ferrum | +Obsidiax |
| Cold | Aquilo | Aquilo, Frozeta, Shchierbin | +Vesta, Muria | +Balack |
| Explosive | Moshine | Moshine, Cubium | +Corrundum, Crucible | +Obsidiax |
| Toxic | Cubium | Cubium, Vesta, Paracelsin, Gleba | +Rabbasca, Foliax, Crucible, Velora | +Khemia |
| Arachnids | Arig | Arig, Castra, Athos | +Crucible, Panglia | +Tenebris |
| Electric | Fulgora | Fulgora, Ribbonia, Corrundum | +Cerys, Ferrum | +Khemia |

Each tier includes all destinations from the previous tier. Nexus is eligible
for every family on every enabled tier. The setting controls only **RP3-added**
planet-local nests; source-owned enemy placements remain untouched.

### Recommended per-family default: Follow difficulty

All six dropdowns now default to **Follow difficulty** (Auto), avoiding an
apparently fixed Curated display even while Hard or Nightmare is selected.
Manual tiers override **only that family** while the other Auto families
continue following the selected master difficulty, even though the overall
effective game difficulty displays Custom after an override.

### Source ownership and prototype allocation (2.1.132)

The Armoured Biters adapter no longer edits the original
`biter-spawner.result_units`, even when it finds a valid dedicated
armoured nest. This retains fauna from source mods and respects Off.

Before allocating a `razi-<planet>-<nest>` prototype, the final
ecology pass checks whether the source mod already registered a
native nest on that world, or the Razi clone was already installed.
This avoids orphaned prototypes and duplicate density, while
retaining native spawners on all difficulties.
