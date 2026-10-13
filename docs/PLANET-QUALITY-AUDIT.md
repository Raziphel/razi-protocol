# Planet Quality Gate (2026-10-12)

**Current curated dev version:** Razi Protocol 2.1.11.

This is a source-code, campaign integration, and publicly described mod-mechanics review. It is **not** proof that the entire Factorio 2.1 + K2SO stack has loaded or that every saved-game path is completable.

## Curation rules

A mandatory planet must offer a distinctive factory puzzle, an environment or logistics problem that matters, enough original content to justify its starmap space, and an actual role in shared technology and resource progression. The developer's installation must be able to load. Optional branches must not become required for the next chapter.

| System | Curated content | Decision |
| --- | --- | --- |
| Calidus | Nauvis, **Muluna**, Calidus Drift | Retain. Muluna is mandatory. |
| Calidus | Biological Machines: Planet Wit | **Exclude.** Muluna declares it incompatible; do not make the player remove Muluna. |
| Solaris | Vulcanus, Castra, Arig, Hyarion, Tellus, Corrundum, Igrys | Retain the mechanical variety and existing discoveries. |
| Solaris | Athos | **Exclude.** Planet Athos 1.1.3 creates a cyclic technology graph during full-pack data loading. |
| Nyxaris | Gleba, Moshine, Apia/Carnova, Foliax, Rabbasca, Velora; Pelagos/Dea Dia when installed | Retain contrasting biological/computational/optional expeditions. |
| Nyxaris | Panglia | **Restore, required (0.7.2+)**. Timewarp-powered industry, DNA sampling, cloning, and simulation create a substantial post-Moshine industrial puzzle; keep its native tech costs and test beta stability. |
| Vibrant | Fulgora, Ribbonia, Paracelsin, Ferrum and Khemia where installed | Retain their electrical/ringworld/cryogenic and specialty industries. |
| Vibrant | Shchierbin | **Exclude.** Comparatively limited vanadium detour; preserve the larger asteroid belt's gameplay by connecting its outer side directly to Paracelsin. |
| Vespera | Muria, Aquilo, Rubia, Maraxsis, Obsidiax, Balack | Retain the cold, corrosive, submerged and high-risk challenges. Balack does not require Wit. |
| Vespera | Nulla | **Exclude.** Nulla 1.0.2 dereferences a missing vanilla electric-furnace prototype in its radio-interference final-fixes pass and prevents the curated full pack from loading. |
| Beetlejuice | Cubium, Linox, Secretas, Frozeta | Retain specialized constrained factories and salvage. |
| Umbra | Tenebris, Crucible, Vesta, Carna, Arcanyx | Retain darkness, extreme pressure, gas-giant and outer industry. |
| Deep Space | Aegis/Bellicos, optional Nexus and Void Processing | Retain as the transceiver and postgame frontier. |

## Integration implemented

- The required `info.json` now includes `panglia_planet >= 0.7.2`; `nulla`, `PlanetAthos`, `biological-machines-planet-wit` and `shchierbin` are explicitly incompatible. Muluna stays required.
- Muluna remains mandatory; Wit-specific discoveries, routes, production exchanges, atlas catalog entries and quests are removed. Balack's independent integration remains.
- Nyxaris's late chapter now requires Panglia discovery after Moshine and Apia-Carnova, preserving the native datacell/foundry costs. Panglia has cargo routes to Moshine and Apia-Carnova; optional Pelagos remains accessible from Moshine and receives an additional Panglia cargo link.
- Vibrant's native AsteroidBelt retains its hazardous source-owned inner/outer crossing. The outer waypoint now routes to Paracelsin, which still requires belt research. Shchierbin science, route, dossiers, quests and prerequisite gates are gone.
- Campaign pair gateways and later Beetlejuice/Umbra access use their remaining actual predecessor worlds. New system and technology names are preserved to avoid unnecessary save migration.
- Affected regression fixtures, locale labels, science cards, production validation and route-distance expectations are updated.

## Upgrading an existing save

**Back up your save before enabling or disabling planet mods.** Reintroducing Panglia restores its surface and researches only after Factorio loads its source mod; factories and surfaces belonging to retired Athos, Wit, Shchierbin or Nulla may be lost when removed. Recover items and move characters out first, then validate on a copied save. Users of the Biological Machines Modpack should also disable that package if it requires Wit.

Panglia is still beta; its full data-stage load, source dependency compatibility, Moshine datacell bootstrap, long-running DNA acquisition and saved-game migration require a real Factorio 2.1 playtest. The normal game engine and final full-modpack tests are **not** available through the current GitHub connector. Run Factorio with the entire curated loadout, test a new and old save, and verify Calidus (Muluna), Nyxaris, the Vibrant asteroid belt, Vespera, Beetlejuice, Umbra, and transceiver research; test optional Pelagos, Dea Dia, and Nexus permutations separately. GitHub Actions remain manual-only.

## Mod Portal

- https://mods.factorio.com/mod/planet-muluna
- https://mods.factorio.com/mod/PlanetAthos
- https://mods.factorio.com/mod/nulla
- https://mods.factorio.com/mod/biological-machines-planet-wit
- https://mods.factorio.com/mod/panglia_planet
- https://mods.factorio.com/mod/shchierbin
- https://mods.factorio.com/mod/biological-machines-planet-balack

## Post-load research and manufacturing check (2.1.23)

The full campaign audit now checks every installed planet's discovery
science, rather than just a preset list of endgame planets. Panglia's
data-cell manufacturing joins the focused checks for Aquilo, Linox,
Crucible and Vesta. Multiple possible native discoveries are evaluated
individually, so a valid alternative can prevent a false deadlock report.

Use `python3 scripts/audit_full_campaign.py <data-raw-dump.json>
--output full-campaign-audit.json` and review the blocked, unverified and
isolated-route sections separately. A complete unmodified Factorio
prototype dump is required. A full 80-hour campaign cannot be certified
from synthetic fixtures.
