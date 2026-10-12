# Razi Protocol

Razi Protocol is a large progression, compatibility, and starmap overhaul for *Factorio: Space Age* built around a huge Krastorio 2 Spaced Out modpack. Its goal is simple: turn a massive pile of excellent planet mods into one coherent campaign.

Instead of leaving every planet on its own island, Razi Protocol rebuilds the run into a chaptered, multi-system expedition with cleaner discovery flow, system milestone cards, routed enemy themes, better map structure, and a longer late-game path into the intergalactic transceiver finale. When Nexus is installed, its black-hole and Sol content becomes an additional Deep Space branch.

## Maintainer Documentation

- [Architecture and data-stage layout](docs/ARCHITECTURE.md): module ownership, loading order, Chronicle storage, and compatibility boundaries.
- [Repository health and cleanup decisions](docs/CODE-HEALTH.md): findings, safe removals, and remaining game-test risks.
- [Chronicle game QA](docs/CHRONICLE-QA.md): save migration, multiplayer and GUI checks.
- [Planet quality gate](docs/PLANET-QUALITY-AUDIT.md): curated roster, removals, design criteria and save-upgrade guidance.
- Run `python3 tools/audit_repository.py` locally for a no-dependency, read-only static check. The GitHub Actions workflow remains manual-only.

## Why It Exists

Big Space Age planet packs are fun, but they also tend to suffer from the same problems:

- Too many disconnected discovery technologies.
- Too many duplicate or overlapping routes on the starmap.
- Too many late researches that ask for walls of unrelated science packs.
- Too many endgame add-ons fighting over the same progression space.
- Too many optional enemy and compatibility mods that do not naturally land where they make thematic sense.

Razi Protocol is the layer that turns that chaos into an intentional galaxy route.

## What It Changes

- Rebuilds the starmap into named progression chapters: Calidus, Solaris, Nyxaris, Vibrant, Beetlejuice, and Deep Space, with the Aegis/Bellicos pulsar expedition isolated far beyond the solar-system edge.
- Adds system discovery technologies for the major custom systems.
- Adds system tech cards so later progression can ask for chapter mastery instead of giant science-pack soups.
- Rehomes many planets so they sit in a cleaner route and unlock order.
- Integrates optional Eneas support plus Linox and Muria directly into the intended campaign flow, while retiring unfinished or redundant planet branches.
- Cleans up a large amount of route clutter from source mods that were not designed around one shared starmap.
- Reworks endgame flow around the solar-system edge and intergalactic transceiver, with an expanded black-hole route when optional Nexus is installed.
- Replaces Nexus omega-science clutter with a more readable Deep Space card-driven endgame when Nexus is present.
- Routes optional custom enemy mods onto planets that fit their theme, while suppressing default biter noise where appropriate.
- Adds Science Tab cleanup so system cards, planet science, and research-data items land in more readable groups.
- Adds Vehicles & Infrastructure as a dedicated crafting tab to reduce early Logistics bloat.
- Includes narrow compatibility fixes for K2SO enhancement/tweak mods, route assumptions, late prototype edge cases, and overlapping planet content.

## Starmap Beauty and Regional Expeditions

The custom Solaris, Nyxaris, Vibrant and Beetlejuice stars now use **original transparent corona artwork** layered underneath their existing portraits. Each star has its own palette (amber industrial light, teal-violet biohazard, exotic magenta-green, and distant ember-blue). These are native `starmap_icons`, so they do not add route-blocking decorative sprites.

Razi Protocol now adds native tooltip labels for routes and destinations: **regional lanes, slipstream approaches, interstellar crossings and deep-space corridors**. Existing custom route art is preserved, while unspecified long-haul Razi connections use Factorio 2.1's straight-line representation. Their lengths, asteroid fields and unlock conditions are untouched.

Beetlejuice's orbital spacing is adjusted for readability: Vesta moves closer to the star, while Frozeta is now a distant independent icy planet rather than appearing next to Secretas. The remaining two branches have more breathing room. Four additional **system-convergence Chronicle projects** represent the combined planet research of Solaris, Nyxaris, Vibrant and Beetlejuice. These are optional documentation milestones, not gameplay locks.

The System Atlas now distinguishes route types and shapes. The vanilla starmap remains the navigation interface; native Factorio does not expose a general-purpose backdrop texture or arbitrary route colors, so this update intentionally avoids claiming those unsupported effects.


### Matching Chronicle star portraits

The Chronicle Overview and System Atlas now render the same four corona graphics used in the native starmap. A compact Deep Space landmark panel shows any installed edge, shattered-planet, black-hole and Oort Cloud destinations and their actual discovery state. These are navigational references, not additional world spawns.

## Cross-System Research Exchanges

After reaching later star systems, the expedition can research **five optional Research Exchanges** that convert combinations of sciences from different planet mods into more efficient versions of existing Tech Cards. Each exchange unlocks a crafting recipe producing **three system cards** from **two complete batches** of its original ingredients plus **one additional science pack from each of two specialist planetary disciplines**. The original card recipe remains unchanged, and no new recipe is required to progress through the story.

| Researched after | Exchange output | Planet-science partnership |
| --- | --- | --- |
| Nyxaris discovery | Calidus Tech Cards | Planetaris compression + Corrundum electrochemistry |
| Vibrant discovery | Solaris Tech Cards | Moshine thermodynamics + Apia biological research |
| Beetlejuice discovery | Nyxaris Tech Cards | Ribbonia alien science + Rubia biofusion |
| Cubium and Tenebris discovery | Vibrant Tech Cards | Tenebris bioluminescence + Cubium gas manipulation |
| Intergalactic Singularity Theory | Beetlejuice Tech Cards | Promethium + Crucible research |

When their science packs exist, additional **optional research exchange recipes** bring in Cerys/Muluna, Dea Dia/Pelagos, Moshine/Dea Dia-related science, Muria/Paracelsin, and Promethium-882/Pulsar projects without blocking the base exchanges. The recipe inputs are built from the final installed card recipes, not hardcoded guesses about missing mod packs.

The five exchange discoveries are also Chronicle side quests. These are **production optimizations**, not shortcuts to a new star system. More advanced discoveries feed back into early-system research, rewarding planet-to-planet supply lines.

## Expedition Chronicle

Razi Protocol includes an in-game **Expedition Chronicle**, opened from its own **Expedition Chronicle** button at the top of the game screen. It is a story-driven journal, not a parallel set of unlocks. Its missions follow the actual Space Age and K2SO research milestones from the opening rocket all the way through activating the intergalactic transceiver.

- Six ordered chapters: **Calidus**, **Solaris**, **Nyxaris**, **Vibrant**, **Beetlejuice** and **Deep Space**.
- **A chapter-spanning quest roster** with research milestones, operational spaceflight objectives, first landings and interplanetary research projects. Planetary arrival quests only appear when the planet and its discovery technology are installed.
- Chapter introductions and epilogues tell a continuous expedition story. Optional-mod missions appear only when their technology exists. Branch labels do not promise that installed mods have no research prerequisites: the real technology tree remains authoritative.
- Quest and chapter status comes from the force's research progress. The journal adds **no new research locks**, completion rewards or planet-access shortcuts.
- **Cross-planet projects** check several researched technologies across different worlds, show the required research and progress count, and give the expedition a narrative reason to combine its discoveries. Missing optional technologies are skipped, and a project needs at least two real technologies to appear.
- **First landfalls** record the first time a player physically reaches a planet surface, separately from the planet's discovery research. Arrival events are shared with the force and survive save/reload and force merges. Existing saves cannot reconstruct where someone landed before tracking began.
- The journal includes a **Refresh** button so players can update live durations without the interface constantly rebuilding and jumping to the top while they read.
- A saved first-reached tick and first-completed tick for each quest and chapter, with **time to reach**, **time to beat** and live progress durations displayed as HH:MM:SS of simulation time.
- A **shared force record** for multiplayer. Timings are persisted in the map save, including across reconnects and reloads. There is no background or real-world-clock timer.
- In an existing save, previously completed research is recognised, but earlier completion timestamps cannot be reconstructed. Such entries honestly show **historical time unavailable**. Timers that start after adding the journal are clearly marked as partial.

A chapter finishes when its final research gate is completed. Landing expeditions and cross-planet research projects are additional campaign objectives, not invisible requirements for travel. They can be completed after a chapter's main story ends. In this pass there are **no changes to item recipes, research dependencies or planet access**; the additional integrations are story, exploration and research tracking.

## Chronicle UI and Expedition Atlas (2.1.6)

The Chronicle is now a complete campaign dashboard rather than a single quest list. It uses a shared Factorio-native GUI theme with chapter colors, science icons, progress bars, status badges, modular mission cards, responsive sizing and per-player preferences.

Seven views are available from the same window:

- **Overview:** current chapter story, overall completion, live statistics and the next open objectives.
- **Missions:** all recorded quests with All, Active, Completed and Branch filters, with a compact or expanded card layout.
- **Planets:** planet dossiers with researched discovery state, confirmed first landfall, environmental context, relevant science and linked expedition roles.
- **Projects:** combined planetary research goals, chapter grouping and per-technology completion markers.
- **Timeline:** an ordered first-hand history of recorded quests, system chapters, first landings and platform milestones. Events from before tracking existed are not backdated.
- **Records:** chapter timing records and progress statistics, plus personal popup and compact-view settings.
- **System Atlas:** inspect installed route prototypes, route lengths, destination unlock states and friendly orbital platform counts for chapter planets. This complements the native starmap rather than modifying its travel rules.

The Chronicle also tracks a force's **first built operational space platform** and **first completed space-platform trip**, bringing the total to **86 defined missions** (54 milestones, including platform objectives, plus 24 landings and 8 multi-world projects).

**Short completion notifications** appear for major project, chapter, landing and spaceflight milestones, then disappear automatically. You can disable them in Records. The GUI retains selected chapter, tab, mission filter and personal UI options across saves. It only renders on relevant events or when you request a refresh, never every tick.

The shared theme module is reusable by future Razi Protocol custom GUIs. The existing native planet selector, platform management screens and starmap are **not** directly replaced by this release: overriding those without stable anchors risks clashes with other UI mods.

## Campaign Structure

Razi Protocol treats the galaxy like a sequence of chapters instead of a flat bucket of planets.

### Calidus

Calidus is the early foundation chapter. It covers the base Space Age setup and the first inner-system layer, including Muluna, optional Cerys, and optional Eneas support. This is where the pack establishes the first milestone card: Calidus Tech Card.

### Aegis and Bellicos

The Aegis expedition no longer crowds the inner campaign map. Its precursor stargate sits beyond the solar-system edge, and the enormous Bellicos pulsar occupies a remote, otherwise unused deep-space bearing. The complete Aegis route remains intact, while Lightweight and Pulsar Science now contribute to Deep Space mastery.

### Solaris

Solaris is the first major custom-system branch. It brings Castra Prime, Arig, Hyarion, Tellus, and Corrundum into a single connected route. This is where the campaign stops feeling like vanilla Space Age and starts feeling like a true multi-system pack.

### Nyxaris

Nyxaris is the shared mid-tier chapter. Apia-Carnova and Moshine form its biological and technological research partnership, with optional Dea Dia and Pelagos branches when compatible.

### Vibrant

Vibrant is the exotic science chapter. It holds Ribbonia, Paracelsin, Muria, Aquilo, Rubia, and Maraxsis. It is the point where the campaign starts leaning into stranger science packs, more specialized planets, and stronger thematic enemy placements.

### Beetlejuice

Beetlejuice is the harsh outer-system chapter. It includes Cubium, Tenebris, Crucible, Vesta, Secretas, Frozeta, and the route toward the solar-system edge. Linox also lives here now as a later side branch, instead of remaining attached to Vulcanus or Solaris.

### Deep Space

Deep Space is the final chapter. Its required route culminates in the intergalactic transceiver chain. Optional Nexus expands that chapter through the black-hole approach, black hole, Oort Cloud, and Sol, while optional Void Processing can add another late branch.

## System Cards

System cards are the backbone of the technology cleanup.

Without Razi Protocol, late-game research in a giant planet pack often becomes unreadable because every technology demands huge walls of planet-specific science packs. Razi Protocol compresses earlier system mastery into milestone cards:

- Calidus Tech Card
- Solaris Tech Card
- Nyxaris Tech Card
- Vibrant Tech Card
- Beetlejuice Tech Card
- Deep Space Tech Card

That keeps the tree readable while still preserving the feeling that every chapter matters. You still have to conquer the system. You just do not have to stare at fifteen separate science icons every time you open the tech screen.

## Planet Integrations

Several planets are not just "supported"; they are deliberately placed into the campaign.

- Bellicos and Aegis retain their complete internal stargate, Warden, asteroid, and pulsar route, but enter the wider campaign beyond the solar-system edge. Their original direct Nauvis and Fulgora links are removed to avoid bypassing Razi Protocol's chapter structure.

- Eneas stays an optional early Calidus moon branch when installed.
- Muria is integrated into the Vibrant chapter ahead of Aquilo.
- Linox is moved into the hot inner orbit of Beetlejuice as a later Cubium-side branch.

These are not cosmetic placements only. Razi Protocol also adjusts their route assumptions, discovery placement, and nearby progression gates so the starmap and tech tree tell the same story.

## Endgame Philosophy

Razi Protocol intentionally provides its own late-game structure.

When Nexus is installed, Razi Protocol hides its omega-science clutter from normal play and swaps its role into a cleaner Deep Space card-driven progression. Without Nexus, the solar-system edge still leads into the transceiver singularity sequence without leaving a missing prerequisite.

That singularity sequence is a major part of the pack identity:

- Intergalactic Singularity Theory
- Intergalactic Singularity Test Fire
- Stable Intergalactic Singularity
- Intergalactic Signal Lock

The result is a longer, cleaner, and more intentional endgame than simply unlocking the vanilla K2SO transceiver as soon as it appears.

Optional Void Processing is still supported, but it is treated as a late Deep Space branch rather than mandatory core pack content.

## Enemy Routing

Razi Protocol supports several optional enemy packs and places them where they fit best.

- Arachnids: Arig, Nexus, Crucible
- Armoured biters: Hyarion, Nexus, Crucible
- Cold biters: Aquilo, Paracelsin, Frozeta, optional Cerys, Nexus
- Electric flying enemies: Corrundum, Ribbonia, Nexus, plus their native Fulgora theme
- Explosive biters: Moshine, Nexus
- Toxic biters: Cubium, Vesta, Nexus, Crucible

Where Razi Protocol assigns a themed enemy faction, it can also suppress vanilla biter and worm autoplace so the custom threat actually defines the planet. If you want original enemy behavior instead, the `razi-enable-enemy-routing` startup setting can disable the Razi routing layer.

## Crafting Cleanup

Large modpacks tend to crush the Logistics tab under belts, trains, poles, tiles, vehicles, bots, and random infrastructure from twenty different planets.

Razi Protocol keeps Logistics focused on the normal logistic core, then adds a dedicated `Vehicles & Infrastructure` tab for:

- Vehicles, trains, wagons, and spider-type hardware
- Rails, signals, train stops, ramps, and supports
- Power poles, substations, switches, lightning gear, and collectors
- Floors, landfill, scaffolding, foundations, and platform pieces

It also includes a few narrow balance passes for overlapping unlocks where two planets solve a similar problem in nearly the same way.

## Compatibility Focus

Razi Protocol is not just a route mod. It is also a cleanup layer for a very busy dependency stack.

It includes targeted fixes for:

- K2SO transceiver and endgame flow
- Optional Nexus omega-science replacement
- Science Tab grouping and lab input behavior
- Vehicles & Infrastructure crafting cleanup
- `xy-k2so-enhancements-nulls-fork`
- `nulls-k2so-tweaks`
- Maraxsis drill/collision edge cases
- Tellus settings that would otherwise move Maraxsis out of the intended layout
- Imersite asteroid route distribution in the late game
- Prototype load issues caused by missing place results, next-upgrade targets, or source-mod overlap assumptions

The philosophy is to patch at the seam, not to rename every source mod into something new.

## Main Content Stack

Razi Protocol is designed for a large content pack, not a tiny minimalist setup.

Core content in the intended experience includes:

- RAZI Library
- Krastorio2 Spaced Out
- PlanetsLib
- Muluna
- Linox
- Muria
- Dea Dia (optional)
- Corrundum
- Apia
- Moshine
- Pelagos (optional)
- Tenebris Prime
- Secretas
- Maraxsis
- Rubia
- Cubium
- Nexus (optional)
- Vesta
- Castra Prime
- Crucible
- Ribbonia
- Paracelsin

Panglia (unfinished beta) and Shchierbin (lightweight vanadium detour) are no longer part of the curated pack. Disable these mods before enabling this revision. Optional supported branches include Dea Dia, Pelagos, Nexus, Celestial Weather and its additions, Eneas, Cerys, Void Processing, a range of enemy packs, and a variety of quality-of-life and compatibility helpers listed in `info.json`.

## Modpack Guidance

For the best results:

- Use the dependency list in `info.json` as the source of truth.
- Install RAZI Library 1.0.0 or newer; it is now a required shared foundation used directly by Razi Protocol's data-stage compatibility code.
- Factorio 2.1 migration status and optional third-party compatibility gaps are tracked in [FACTORIO-2.1-COMPATIBILITY.md](FACTORIO-2.1-COMPATIBILITY.md). The required dependency path now consists entirely of native Factorio 2.1 releases.
- Treat unsupported route overhauls as incompatible unless explicitly patched.
- Be cautious with collision-layer-heavy add-ons.
- Expect Razi Protocol to disagree with mods that try to define their own parallel late game.

This is especially true for large combat, terrain, water, vehicle, and planet expansions that can collectively push Factorio near its collision-layer cap.

## Support

If you enjoy the mod and want to support future updates:

- Discord: https://discord.gg/fTEtu64whV
- Patreon: https://www.patreon.com/cw/Raziphel
- Foundry community: https://discord.gg/Dn5p7GZpKu

## Credits

Razi Protocol exists because of the wider Factorio modding community. The planets, enemies, mechanics, art, sounds, and icons used by the pack belong to their respective authors and contributors.

Please see [Credits.txt](Credits.txt) for the full acknowledgement list. If you are a mod author and want credit wording adjusted or content removed, contact Raziphel on Discord.
