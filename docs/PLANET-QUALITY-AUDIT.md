# Planet Quality Gate (2026-10-12)

**Current curated dev version:** Razi Protocol 2.1.5.

This is a source-code, campaign integration, and publicly described mod-mechanics review. It is **not** proof that the entire Factorio 2.1 + K2SO stack has loaded or that every saved-game path is completable.

## Curation rules

A mandatory planet must offer a distinctive factory puzzle, an environment or logistics problem that matters, enough original content to justify its starmap space, and an actual role in shared technology and resource progression. The developer's installation must be able to load. Optional branches must not become required for the next chapter.

| System | Curated content | Decision |
| --- | --- | --- |
| Calidus | Nauvis, **Muluna**, Eneas, Calidus Drift | Retain. Muluna is mandatory. |
| Calidus | Biological Machines: Planet Wit | **Exclude.** Muluna declares it incompatible; do not make the player remove Muluna. |
| Solaris | Vulcanus, Castra, Arig, Hyarion, Tellus, Corrundum, Igrys, Athos | Retain the mechanical variety and existing discoveries. |
| Nyxaris | Gleba, Moshine, Apia/Carnova, Foliax, Rabbasca, Velora; Pelagos/Dea Dia when installed | Retain contrasting biological/computational/optional expeditions. |
| Nyxaris | Panglia | **Exclude.** Unfinished beta quality and redundant required progression. |
| Vibrant | Fulgora, Ribbonia, Paracelsin, Ferrum and Khemia where installed | Retain their electrical/ringworld/cryogenic and specialty industries. |
| Vibrant | Shchierbin | **Exclude.** Comparatively limited vanadium detour; preserve the larger asteroid belt's gameplay by connecting its outer side directly to Paracelsin. |
| Vespera | Muria, Aquilo, Rubia, Maraxsis, Obsidiax, Nulla, Balack | Retain the cold, corrosive, submerged and high-risk challenges. Balack does not require Wit. |
| Beetlejuice | Cubium, Linox, Secretas, Frozeta | Retain specialized constrained factories and salvage. |
| Umbra | Tenebris, Crucible, Vesta, Carna, Arcanyx | Retain darkness, extreme pressure, gas-giant and outer industry. |
| Deep Space | Aegis/Bellicos, optional Nexus and Void Processing | Retain as the transceiver and postgame frontier. |

## Integration implemented

- The required `info.json` dependencies no longer include `biological-machines-planet-wit`, `panglia_planet` or `shchierbin`. Explicit Factorio incompatibilities prevent these mods silently rejoining the curated stack.
- Muluna remains mandatory; Wit-specific discoveries, routes, production exchanges, atlas catalog entries and quests are removed. Balack's independent integration remains.
- Nyxaris's compulsory milestones no longer use Panglia, and standalone Pelagos reconnects through Moshine.
- Vibrant's native AsteroidBelt retains its hazardous source-owned inner/outer crossing. The outer waypoint now routes to Paracelsin, which still requires belt research. Shchierbin science, route, dossiers, quests and prerequisite gates are gone.
- Campaign pair gateways and later Beetlejuice/Umbra access use their remaining actual predecessor worlds. New system and technology names are preserved to avoid unnecessary save migration.
- Affected regression fixtures, locale labels, science cards, production validation and route-distance expectations are updated.

## Upgrading an existing save

**Back up the save before disabling planet mods.** Any factories and surfaces belonging to Wit, Panglia or Shchierbin may be lost by Factorio when their mods disappear. Recover items and move characters out first, then validate on a copied save. Users of the Biological Machines Modpack should also disable that package if it requires Wit.

The normal game engine and final full-modpack tests are **not** available through the current GitHub connector. Run Factorio with the entire curated loadout, test a new and old save, and verify Calidus (Muluna), Nyxaris, the Vibrant asteroid belt, Vespera, Beetlejuice, Umbra, and transceiver research; test optional Pelagos, Dea Dia, and Nexus permutations separately. GitHub Actions remain manual-only.

## Mod Portal

- https://mods.factorio.com/mod/planet-muluna
- https://mods.factorio.com/mod/biological-machines-planet-wit
- https://mods.factorio.com/mod/panglia_planet
- https://mods.factorio.com/mod/shchierbin
- https://mods.factorio.com/mod/biological-machines-planet-balack
