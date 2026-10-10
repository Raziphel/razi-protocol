# K2SO integrations across the seven-system expedition

This is a cross-mod integration pass, not a replacement for the original
authors' mechanics. Razi uses **Krastorio 2 Spaced Out (K2SO)** as a research
and production backbone, while keeping each world recognizably its own.

## Planetary research-data deliveries

These existing K2SO items are now ingredients in existing Razi System Tech
Cards. They represent genuine logistics and science deliveries from worlds
already accessible by the time each card is needed. The change is applied only
if K2SO, the destination planet, the card item/recipe, and an actual K2SO
research-data production recipe all exist.

| System card | Original K2SO research data | Producer origin |
| --- | --- | --- |
| Solaris | `kr-metallurgic-research-data` | Vulcanus |
| Nyxaris | `kr-agricultural-research-data` | Gleba |
| Vibrant | `kr-electromagnetic-research-data` | Fulgora |
| Vespera | `kr-cryogenic-research-data` | Aquilo |
| Beetlejuice | `kr-matter-research-data` | Aquilo's matter research chain |
| Umbra | `kr-matter-research-data` | Aquilo's matter research chain |
| Deep Space | `kr-promethium-research-data` | Space near the Shattered Planet |

Calidus remains a standalone starting chapter: no off-world-only K2SO
research data should prevent opening Solaris or Nyxaris. The next chapter
does not demand a resource from the planet it unlocks.

These dependencies complement, rather than replace, native Planetaris,
Moshine, Castra, Paracelsin, Muria, Rubia, Crucible, and other science that
already feeds into the cards. The `campaign_weave.lua` research graph is
still responsible for planet-by-planet discovery requirements.

## K2SO material standardization across *all* planets

K2SO's upstream `enforce-k2-items.lua` standardizes oxygen, hydrogen,
chlorine, sand, glass, silicon, lithium, and ammonia. Since some independent
planet-mod compatibility passes run after that file, Razi checks the **final**
recipe ingredients/results, resource/minable output and liquid tiles.

Razi switches a stale original name to the K2SO name **only** when the
original item/fluid is hidden and the corresponding K2SO prototype is
present and visible. This avoids overwriting the common fluids deliberately
restored by Null's K2SO Tweaks. Unrecognized planet-specific resources,
machine categories, custom recipe properties and native source effects are
left alone.

## Validation and remaining work

Lua fixtures prove the name reconciliation, presence guards, compatibility
with Null's chosen common gases, no forced K2SO-on behavior, and repeat-run
safety. CI runs the compatibility/prototype audits as before.

Full `--dump-data-raw` and game validation remain essential. In particular,
check that every K2SO research-data recipe is **actually unlockable,
craftable on a reachable surface, and collectible** in the correct chapter,
and that Razi's system-card crafting category can assemble it. The repo's
tests cannot confirm these complete modpack interactions.

The integration applies to all enabled planet mods at the prototype level,
but that does **not** imply we have individually playtested every planet or
finished integrating every unique native mechanic. Source-owner changes
should remain upstream where practical.

## References

- K2SO upstream: https://github.com/Polka37/Krastorio2-spaced-out
- K2SO enforced names:
  `prototypes/final-fixes/enforce-k2-items.lua` in the upstream repository
- Integration: `prototypes/compat/k2so_planet_integration.lua`
- Fixture: `tests/lua/test_k2so_planets.lua`
