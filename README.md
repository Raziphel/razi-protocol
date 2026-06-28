# Razi Protocol

Razi Protocol is a large progression, compatibility, and starmap overhaul for *Factorio: Space Age* built around a huge Krastorio 2 Spaced Out modpack. Its goal is simple: turn a massive pile of excellent planet mods into one coherent campaign.

Instead of leaving every planet on its own island, Razi Protocol rebuilds the run into a chaptered, multi-system expedition with cleaner discovery flow, system milestone cards, routed enemy themes, better map structure, and a longer late-game path into Nexus, black-hole research, Sol, and the intergalactic transceiver finale.

## Why It Exists

Big Space Age planet packs are fun, but they also tend to suffer from the same problems:

- Too many disconnected discovery technologies.
- Too many duplicate or overlapping routes on the starmap.
- Too many late researches that ask for walls of unrelated science packs.
- Too many endgame add-ons fighting over the same progression space.
- Too many optional enemy and compatibility mods that do not naturally land where they make thematic sense.

Razi Protocol is the layer that turns that chaos into an intentional galaxy route.

## What It Changes

- Rebuilds the starmap into named progression chapters: Calidus, Solaris, Nyxaris, Vibrant, Beetlejuice, and Deep Space.
- Adds system discovery technologies for the major custom systems.
- Adds system tech cards so later progression can ask for chapter mastery instead of giant science-pack soups.
- Rehomes many planets so they sit in a cleaner route and unlock order.
- Integrates optional Eneas support plus Linox, Muria, and Shchierbin directly into the intended campaign flow.
- Cleans up a large amount of route clutter from source mods that were not designed around one shared starmap.
- Reworks endgame flow around Nexus, the solar-system edge, the black-hole chain, and the intergalactic transceiver.
- Replaces Nexus omega-science clutter with a more readable Deep Space card-driven endgame.
- Routes optional custom enemy mods onto planets that fit their theme, while suppressing default biter noise where appropriate.
- Adds Science Tab cleanup so system cards, planet science, and research-data items land in more readable groups.
- Adds Vehicles & Infrastructure as a dedicated crafting tab to reduce early Logistics bloat.
- Includes narrow compatibility fixes for K2SO enhancement/tweak mods, route assumptions, late prototype edge cases, and overlapping planet content.

## Campaign Structure

Razi Protocol treats the galaxy like a sequence of chapters instead of a flat bucket of planets.

### Calidus

Calidus is the early foundation chapter. It covers the base Space Age setup and the first inner-system layer, including Muluna, optional Cerys, and optional Eneas support. This is where the pack establishes the first milestone card: Calidus Tech Card.

### Solaris

Solaris is the first major custom-system branch. It brings Castra Prime, Arig, Hyarion, Tellus, and Corrundum into a single connected route. This is where the campaign stops feeling like vanilla Space Age and starts feeling like a true multi-system pack.

### Nyxaris

Nyxaris is the shared mid-tier chapter that also absorbs Dea Dia-style progression. It groups Nyxaris, Dea Dia access, Apia Carnova, Moshine, Panglia, and Pelagos into one broader progression stage and collapses their science into Nyxaris Tech Card.

### Vibrant

Vibrant is the exotic science chapter. It holds Ribbonia, Paracelsin, Muria, Aquilo, Rubia, Maraxsis, and Shchierbin. It is the point where the campaign starts leaning into stranger science packs, more specialized planets, and stronger thematic enemy placements.

### Beetlejuice

Beetlejuice is the harsh outer-system chapter. It includes Cubium, Tenebris, Crucible, Vesta, Secretas, Frozeta, and the route toward the solar-system edge. Linox also lives here now as a later side branch, instead of remaining attached to Vulcanus or Solaris.

### Deep Space

Deep Space is the final chapter. It pushes beyond the solar-system edge into Nexus, the black-hole approach, the black hole, Oort Cloud, and Sol. This is where the pack transitions into the true late game: promethium, antimatter, black-hole research, optional Void Processing, and the intergalactic transceiver chain.

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

- Eneas stays an optional early Calidus moon branch when installed.
- Muria is integrated into the Vibrant chapter ahead of Aquilo.
- Shchierbin now branches from Paracelsin instead of hanging directly off the Vibrant slipstream.
- Linox is moved into Beetlejuice as a later Cubium-side branch.

These are not cosmetic placements only. Razi Protocol also adjusts their route assumptions, discovery placement, and nearby progression gates so the starmap and tech tree tell the same story.

## Endgame Philosophy

Razi Protocol intentionally provides its own late-game structure.

Nexus often arrives with a large amount of omega-science clutter. Razi Protocol hides that clutter from normal play and swaps its role into a cleaner Deep Space card-driven progression. The solar-system edge becomes the gate out of Beetlejuice, and the final research flow runs through the black-hole chain and the transceiver singularity sequence.

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
- Armoured biters: Panglia, Hyarion, Nexus, Crucible
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
- Nexus omega-science replacement
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

- Krastorio2 Spaced Out
- PlanetsLib
- Muluna
- Linox
- Shchierbin
- Muria
- Dea Dia
- Corrundum
- Apia
- Moshine
- Panglia
- Pelagos
- Tenebris Prime
- Secretas
- Maraxsis
- Rubia
- Cubium
- Nexus
- Vesta
- Castra Prime
- Crucible
- Ribbonia
- Paracelsin

Optional supported branches include things like Eneas, Cerys, Void Processing, a range of enemy packs, and a variety of quality-of-life and compatibility helpers listed in `info.json`.

## Modpack Guidance

For the best results:

- Use the dependency list in `info.json` as the source of truth.
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
