# Source Asteroids in Razi Protocol Dev

## Verified mod families

- **Imersite Asteroids** (Imersite-Asteroids 1.3.0): harvestable
  Imersite/Imersium chunk, crushing retained from its source mod.
- **Secretas and Frozeta** (secretas 1.0.37): Auric debris and
  small, medium, big and huge Auric hostiles, retaining Secretas'
  original processing and child-splitting behavior.
- **Foliax**: charged Promethium asteroid chunks are manufactured by a
  factory chain, so Razi deliberately does not introduce natural spawns.

## Appropriate route placement

| Area | Asteroid family | Style |
| --- | --- | --- |
| Fulgora orbit / routes | Imersite | Tiny first traces |
| Vibrant physical belt | Imersite | Main midgame harvest |
| Vibrant rim / Paracelsin / Ribbonia | Imersite | Secondary pockets |
| Routes toward Aquilo | Imersite | Advanced harvest |
| Umbra's Shattered Divide belt | Imersite | Rare remnants |
| Cubium/Linox approaches to Secretas | Auric | Chunks, small to big encounters |
| Secretas–Frozeta | Auric | Richer local fields |
| Secretas–Solar System Edge | Auric | Large and rarely huge enemies |

`prototypes/system/modded_asteroid_distribution.lua` executes after the
final authoritative route reconciliation, and before quality-asteroid
proxy conversion and route tooltips.

**Safety:** all source-owned definitions win; all added entries are
prototype-guarded and idempotent, and existing spawn tables are detached
before appending. The distribution uses the real native connections
rather than rebuilding old source shortcuts. Source mechanics, mining,
recipes, native route distances, science and technology are unchanged.
The custom prototype audit logs detected asteroid families to help
identify future supported mods without seeding unknown/craft-only items.

Validation: `lua5.2 tests/lua/test_modded_asteroid_distribution.lua`
and `python3 -m unittest tests.test_modded_asteroid_distribution`.
Requires in-game testing with installed source mods before stable release.

Sources:
- https://mods.factorio.com/mod/Imersite-Asteroids
- https://github.com/ZacharyDK/Secretas
