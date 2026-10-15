# Source Asteroids in Razi Protocol Dev

## Verified mod families

- **Imersite Asteroids** (Imersite-Asteroids 1.3.0): harvestable
  Imersite/Imersium chunk, crushing retained from its source mod.
- **Secretas and Frozeta** (secretas 1.0.37): Auric debris and
  small, medium, big and huge Auric hostiles, retaining Secretas'
  original processing and child-splitting behavior.
- **Foliax**: charged Promethium asteroid chunks are manufactured by a
  factory chain, so Razi deliberately does not introduce natural spawns.

## 2.1.105: Vibrant and Secretas encounter polish

The first distribution pass used a symmetric mid-route peak for both
source mods. That works for the **physical Vibrant belt**, but not
Secretas: the original Auric spawn ratios grow toward the gas giant.

- **Imersite:** maintain Fulgora trace rates (~0.001), Aquilo-bound
  advanced harvesting (~0.008), and a primary mid-belt seam (~0.013).
  Aquilo takes precedence when a route connects Fulgora to Aquilo.
- **Auric:** new (previously missing) chunks and hostile entries are
  now concentrated toward the Secretas end of a route. The sampling
  curve reverses automatically on a source connection authored in
  the opposite direction.
- **Frozeta:** the short Secretas–Frozeta passage keeps at least 52%
  of its Auric field across the connection instead of leaving half
  the return trip barren.
- **Existing source values win:** no replacement of any Imersite or
  Secretas spawn record supplied by the original mod.
- **Diagnostic audit:** Factorio's startup log now includes a stable
  sorted list of modified route IDs and the number of entries added:
  `[Razi Protocol/custom-asteroids] Modified routes:`.

The ten-stage asteroid-quality progression is unchanged; no new
difficulty scale, crafting recipes or route edges are introduced.
The next verification must be a full modpack start and a platform trip.

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
