# Razi Protocol: Planet quality audit

**Reviewed:** 12 October 2026 for Razi Protocol 2.1.11. This is a curated **source-code, mod-description and campaign-integration audit**, not a claim to have visited and completed every world in a live Factorio game.

## Quality standard

A required planet must justify its place in the galaxy with a memorable environment, an industrial puzzle beyond processing a single new ore, distinct mechanics or hazards, an export/science purpose that matters outside the world, and a maintained compatible version. A large world count is not itself a design achievement. Small planets with a *genuinely different* challenge may stay. Optional worlds do not block the core storyline.

## Planet-by-planet decisions

| Campaign region | Planet or expedition | Decision | Reason |
| --- | --- | --- | --- |
| Calidus | Nauvis, Vulcanus, Fulgora, Gleba | **Keep** | Vanilla Space Age foundations, uniquely different science loops |
| Calidus | Muluna | **Keep** | Lunar infrastructure and the early off-world transport challenge |
| Calidus | Cerys, Eneas | **Optional** | Distinct side expeditions; version compatibility must be checked |
| Deep Space | Aegis and Bellicos pulsar | **Keep** | Stargates, enemy encounters, long-range engineering, pulsar science |
| Solaris | Castra Prime | **Keep** | Military frontier and battlefield science |
| Solaris | Arig | **Keep** | Desert material compression and sand processing |
| Solaris | Hyarion | **Keep** | Crystals, polishing and precision production |
| Solaris | Tellus | **Keep** | Bioengineering and living-industry production |
| Solaris | Corrundum | **Keep** | Electrochemical industry and interstellar research junction |
| Nyxaris | Apia and Carnova | **Keep** | Two contrasting worlds and distinctive apicultural biology |
| Nyxaris | Moshine | **Keep** | Desert thermal engineering, artificial intelligence and recovered data |
| Nyxaris | Panglia | **REMOVE** | Source author marks the planet BETA and not completely finished; unfinished clone/root-defense direction should not block a polished campaign |
| Nyxaris | Pelagos | **Optional** | Ocean-island logistics, ships and pollution mechanics; check 2.1 compatibility |
| Nyxaris | Dea Dia, Lemures, Prosephina | **Optional** | Multi-world branch; remains nonessential when source mod unavailable |
| Vibrant | Ribbonia | **Keep** | Strange constrained ringworld logistics and hostile AI |
| Vibrant | Paracelsin | **Keep** | Cryovolcanic zinc production and freezing |
| Vibrant | Muria | **Keep** | Chlorine industry, corrosion and fungal countermeasures |
| Vibrant | Aquilo | **Keep** | Cryogenics and freezing challenges |
| Vibrant | Rubia | **Keep** | Biofusion production and biological manufacturing |
| Vibrant | Maraxsis | **Keep** | Submerged construction and hydraulic science |
| Vibrant | Shchierbin | **REMOVE** | Vanadium processing offers a comparatively modest, safe detour with insufficient original hazard or production identity relative to existing material worlds |
| Beetlejuice | Cubium | **Keep** | Gas manipulation and constrained production |
| Beetlejuice | Tenebris | **Keep** | Darkness and bioluminescence-based industry |
| Beetlejuice | Crucible | **Keep** | High-pressure metallic hydrogen, gravity and costly launch logistics |
| Beetlejuice | Vesta | **Keep** | Atmospheric gas-giant industry and algae; it is not a volcano planet |
| Beetlejuice | Secretas and Frozeta | **Keep** | Outer-system resource processing and frozen salvage |
| Beetlejuice | Linox | **Keep** | Very hot, tiny surface plus a tight underground-facility puzzle; moved closer to its system star |
| Deep Space | Nexus, black hole, Oort Cloud and Sol | **Optional** | Extended late-game physics and scientific work |
| Deep Space | Void Processing | **Optional** | Late-game special processing, subject to compatibility |

## Changes made

- Removed Panglia and Shchierbin from the required list, and added explicit incompatible dependencies so they cannot silently return in the intended curated installation.
- Removed their custom route integrations, research dependencies, enemy assignment, planet dossiers and first-landfall quests.
- Nyxaris retains a viable Apia-Carnova and Moshine core. When optional Pelagos is present, its route connects from Moshine. Optional Dea Dia remains its own branch.
- Replaced the Panglia-based three-way research objective with an Apia + Moshine science milestone. Kept the older Adaptive Network and Alchemical Cousins quest IDs to preserve existing recorded milestones.
- Paracelsin and Muria now form the chemical side objective and optional Tech Card exchange instead of requiring Shchierbin's vanadium science.
- Corrected multiple Chronicle world descriptions and moved Linox closer to Beetlejuice for astronomical consistency.

## Save migration and limitations

**Back up an existing save before removing the source mods.** Removing a Factorio planet mod may destroy that world's surfaces, infrastructure, resources, items and technologies. Move players and recover valuable equipment first. Test the update on a copied save before migrating permanently.

This audit does not certify mod-load validity, route connectivity or final technology reachability inside Factorio 2.1; these must still be tested with the full K2SO loadout and optional-mod permutations. The workflow remains manual-only to conserve GitHub Actions usage.

## Mod Portal references

- https://mods.factorio.com/mod/panglia_planet
- https://mods.factorio.com/mod/shchierbin
- https://mods.factorio.com/mod/linox
- https://mods.factorio.com/mod/Muria
- https://mods.factorio.com/mod/apia
- https://mods.factorio.com/mod/Moshine
- https://mods.factorio.com/mod/planetaris-unbounded
- https://mods.factorio.com/mod/ribbonia
- https://mods.factorio.com/mod/skewer_planet_vesta
- https://mods.factorio.com/mod/pelagos
