# Optional community expansion compatibility, October 2026

> **October 2026 update:** Razi now requires supported Factorio 2.1
> conventional worlds from this earlier optional list, including Cerys.
> See [Required Worlds & Bridge Roadmap](PLANETARY_BRIDGES_AND_MASTERY.md)
> for current dependency policy and the three unresolved compatibility blockers.
> The historical details below document the earlier integration pass.


This document reviews community planets and their integrations. Wit remains excluded because it conflicts with required Muluna. Athos and Nulla are now required and linked through a post-arrival Frontier Recovery Charter. Their former data-stage crashes still require real Factorio validation.
The active integrations are side-content and optional sources of unique materials and gameplay.
Abacayba remains a recommended **alpha** addition, not a requirement:
its latest source mod also requires UMR, UFP and multiple Ultimate Core
packages. The code rehomes the existing world but does not vend those
packages, import graphics or duplicate the infestation planet.
**No optional planet is required for any of the eight Razi system tech cards,
the seven-system campaign, or the base endgame.** None is allowed to replace
another mod's native science, enemy control, landing mechanic or specialized
factory. A successful static test does not prove that all mods load together.

| Mod portal ID | Status | Home or treatment | Safety and intended role |
| --- | --- | --- | --- |
| `Igrys` | Already integrated, required install | Solaris | Native magical/glass industry, Razi local route and discovery. |
| `planet-rabbasca` | Already integrated, required install | Gleba moon, Nyxaris | Preserves unique energy field, native orbit, hop limits, and research. |
| `foliax` | Already integrated, required install | Nyxaris | Botany/arcane production stays source-authored. |
| `obsidiax` | Already integrated, required install | Exterior Umbra beside Vesta | Frozen lava world retains rock growing and thermal mechanics. |
| `rabbasca-underground` | Registered, native-only | Hidden Rabbasca stabilizer | A *non-space-accessible* traveling underground environment. Never add a launch corridor or reveal on the starmap. |
| `skewer_shattered_planet` | Registered, native-only | Original Shattered Planet endgame | Do not duplicate the Shattered Planet location, isotopes, or native science gates. Combined endgame requires live validation. |
| `planet-ferrum` | Guarded side-world integration | Western Beetlejuice, Slip Stream spur | Remote-view-only artificial planet. Preserve choice-driven tech and native rare-earth bridges with Linox/Moshine; no forced landing. |
| `Velora` | Guarded moon integration | Gleba moon, Nyxaris | Original moon orbit, native enemy population, science and resource chain. Add a short connection only if missing. |
| `shchierbin` | **Optional** | Exterior Vibrant near Paracelsin | Original vanadium gameplay preserved, no asteroid-belt bypass. |
| `nulla` | **Required** | Aquilo moon in Vespera | Source-owned Robotic Science, radioactive scrapyards and combat drones now feed shared recovery research. |
| `alchemy-khemia` | Guarded side-world integration | Vibrant chemistry branch | Source-authored glyphs, chemistry, brine tanks and crate logistics. Optional link to Paracelsin when no native in-system route exists. |
| `Arcanyx` | Guarded side-world integration | Umbra experimental branch | Voidcraft/Iridescent Industry and prism production untouched. Connect toward Tenebris only if no native local route exists. |
| `Hephaestus` | **Excluded** | Removed from the curated galaxy | Giant H markers and labels obscure the Razi starmap; no integration remains. |
| `PlanetAthos` | **Required** | Solaris stone/diamond world | Particulate Science and Crushing Industry join the new Frontier Recovery Charter, without changing native production. |
| `biological-machines-planet-wit` | **Excluded** | Competing Nauvis moon | Conflicts with required Muluna; no route or science integration remains. |
| `biological-machines-planet-balack` | Guarded high-risk side-world integration | Vespera after Aquilo | Preserve original enormous asteroid traffic, promethium technology, fabrication and dangerous enemies. |

### Why these dependencies are optional

Rabbasca's original high-energy restriction, Ferrum's remotely controlled
factories, Arcanyx's Voidcraft
dependency tree and alternative Shattered Planet gameplay are significant.
Requiring every mod in the core dependency list before confirming full game
load would risk making **Razi Protocol itself impossible to install**.
The five previously admitted mods keep their existing dependency status;
the eleven new additions are declared as Factorio optional dependencies
with known 2.1-compatible minimum versions. Download/enable any desired
side module in Factorio's Mod Manager. Razi then detects its prototypes.

### How travel and research are reconciled

For conventional worlds, the late data stage checks that the mod, source
planet, target system and relevant existing star technology are present.
It adds only an appropriate side connection when no native in-system
route exists. It adds the corresponding system/planet discovery prerequisite
to the **original unlock-space-location technology**, not a fabricated
replacement technology; preexisting/indirect prerequisites and cycles are
respected. A non-existent prototype is never instantiated.

Ferrum's native Fulgora and Vulcanus source routes are no longer part
of the public network. The route authority migrates their unique native
asteroid spawns to the new Ferrum–Beetlejuice Slip Stream connection
before pruning the two obsolete cross-system shortcuts. Ferrum's remote
industrial mechanics, research choices and original rare-earth science
remain source-owned; its discovery now follows Beetlejuice instead of
Vibrant. The moon Velora keeps its
original orbital relationship. Balack keeps its original, hard
Aquilo-side hazardous path. Special worlds (Rabbasca Underground and
Shattered) retain their native mechanics and routes.

Late research naturally remains late: source original tech may require
promethium, an Aquilo visit or its own local production chain. Razi
never gives those ingredients or discoveries earlier. No new Razi science
pack requires items from these optional worlds.

### Source-specific compatibility risks

1. **Balack:** Source's native promethium requirements and Shattered
   discovery changes interact with our Outer Frontier Mastery. Verify
   post-load research graphs; do not change its technology by guessing.
2. **Ferrum:** Its recipe unlock order depends on in-game choices; avoid
   injecting generic science or rewriting those choice rules. It already
   integrates with Linox and Moshine.
4. **Rabbasca Underground:** Underground warp surfaces cannot receive
   platforms. No orbital route is created.
5. **Arcanyx:** Voidcraft, Iridescent Industry and associated assets
   are substantial. Treat it as optional until K2SO recipe collision
   tests pass.
6. **Shattered Planet extension:** It expands the existing endgame
   surface; do not duplicate it or assume its high-tier resources
   are compatible with Razi's singularity victory.

### Validation before an all-modpack release

Run Factorio 2.1 with just the required pack, then with each optional
world, then the remaining supported options together. Export `data.raw`, run
`scripts/audit_prototypes.py`,
`scripts/audit_supply_chains.py`, and
`scripts/audit_route_distances.py`; confirm tech unlock names, visually
inspect the star map, and fly representative routes. Test a backed-up
late save as well as a fresh save. Check especially the science routes
noted above. Only then should a new entry be promoted from optional
to recommended or required.

### Sources

The requested mod pages and their original source links are at
`https://mods.factorio.com/mod/<mod-ID>`. Confirmed upstream source
repositories include:
- `benlaflen/planet-ferrum`
- `PizzaPlanner/rabbasca-underground`
- `bradythehuman/Biological-Machines`

All installed mod-specific art, recipes, resource tables and sound
files remain owned by their respective mods; none is copied into Razi.

## Community industrial integration: Ferrum and Balack

The next production pass adds **two more modded-world-to-modded-world
manufacturing bridges**, independent of the earlier seven new exchanges.
They are gated alternate recipes, not modifications to the original mods.

| Factory | Exports shipped to the factory | Native process still required | New output |
| --- | --- | --- | --- |
| **Ferrum** | 3 Linox rare-earth powders, 4 Moshine optical cables | 15 Ferrum rare-earth oxide, 30 electrolyte, 60 molten iron across three native magnet batches | **4 Ferrum rare-earth magnets** rather than 3 |
| **Balack** | 2 Rubia craptonite frames, 2 Tenebris chitosan | Two native bio-cube shielding batches, including **2 promethium asteroid chunks and 20 heavy oil** | **12 radiation shielding** rather than 10 |

These exchanges preserve Ferrum's branching remote robotics and Balack's
promethium-based biofabrication. Both keep their native research gates,
source-appropriate crafting categories and original recipes. Muluna's
lunar science remains untouched; Wit is explicitly incompatible.

A new recipe requires the exact source mod, its source recipe and research
unlock, *every* imported material's native producer recipe and unlock,
all destination and exporter world discovery techs, and available
Vibrant/Vespera tech cards in at least one real lab. No optional item
appears in mandatory Razi science or discovery tech. The variants do not
support productivity, auto recycling, or recursive self-catalysis and
take **30% longer per native production batch**; the output premiums of
20–33% are therefore not automatically better than optimized vanilla
factories. They are intended to reward players who already operate
the relevant planets.

Source files inspected:
- `benlaflen/planet-ferrum/prototypes/rare-earth.lua` and
  `prototypes/techs.lua`
- `bradythehuman/Biological-Machines/biological-machines-planet-balack/
  prototypes/recipes.lua` and `prototypes/technologies.lua`

The `tests/lua/test_community_industry_exchanges.lua` fixture verifies
native resource costs, bonuses, original recipe preservation, late
research unlocks, optional mod absence, missing supplier materials,
source machine fluid ports and the existing mod-settings toggle.
Factorio 2.1 full-modpack validation remains necessary.

### Retired in 2.1.82

Solar Halo and Eneas no longer receive dependencies, chart integration,
scientific shortcuts, or Razi-authored routes. Factorio users who previously
enabled them should disable the external mods themselves and protect old
saves before removing their orbital surfaces.

### 2.1.87 system balance

Ferrum now makes Beetlejuice's fifth industrial destination while Obsidiax
joins Umbra as a sixth planet when the curated roster is installed.
Shchierbin, if opted in, stays a remote outer-Vibrant vanadium spur and
Athos occupies a clean western Solaris lane. No extra planet mods are
required merely to balance the two outer star systems.
