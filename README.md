# Razi Protocol

Razi Protocol is a large progression, compatibility, and starmap overhaul for *Factorio: Space Age* built around a huge Krastorio 2 Spaced Out modpack. Its goal is simple: turn a massive pile of excellent planet mods into one coherent campaign.

Instead of leaving every planet on its own island, Razi Protocol rebuilds the run into a chaptered, multi-system expedition with cleaner discovery flow, system milestone cards, routed enemy themes, better map structure, and a longer late-game path into the intergalactic transceiver finale. When Nexus is installed, its black-hole and Sol content becomes an additional Deep Space branch.

## Why It Exists

Big Space Age planet packs are fun, but they also tend to suffer from the same problems:

- Too many disconnected discovery technologies.
- Too many duplicate or overlapping routes on the starmap.
- Too many late researches that ask for walls of unrelated science packs.
- Too many endgame add-ons fighting over the same progression space.
- Too many optional enemy and compatibility mods that do not naturally land where they make thematic sense.

Razi Protocol is the layer that turns that chaos into an intentional galaxy route.

## What It Changes

- Rebuilds the starmap into named progression chapters: Calidus, Solaris, Nyxaris, Vibrant, Vespera, Beetlejuice, Umbra, and Deep Space, with the Aegis/Bellicos pulsar expedition isolated far beyond the solar-system edge.
- Adds system discovery technologies for the major custom systems.
- Adds system tech cards so later progression can ask for chapter mastery instead of giant science-pack soups.
- Rehomes many planets so they sit in a cleaner route and unlock order.
- Integrates optional Eneas support plus Linox, Muria, and Shchierbin directly into the intended campaign flow.
- Cleans up a large amount of route clutter from source mods that were not designed around one shared starmap.
- Reworks endgame flow around the solar-system edge and intergalactic transceiver, with an expanded black-hole route when optional Nexus is installed.
- Replaces Nexus omega-science clutter with a more readable Deep Space card-driven endgame when Nexus is present.
- Routes optional custom enemy mods onto planets that fit their theme, while suppressing default biter noise where appropriate.
- Adds Science Tab cleanup so system cards, planet science, and research-data items land in more readable groups.
- Adds Vehicles & Infrastructure as a dedicated crafting tab to reduce early Logistics bloat.
- Includes narrow compatibility fixes for K2SO enhancement/tweak mods, route assumptions, late prototype edge cases, and overlapping planet content.

## Mod Settings

Razi Protocol's startup settings are organized into three color-coded groups inspired by FluxWorks: **Worlds & Encounters**, **Production Integration**, and **Quality of Life**. Each option includes a clear Yes/No explanation and recommended default. See [Settings guide](docs/SETTINGS.md) for every option and its effects.

The optional K2SO and modded-planet production exchanges can be controlled independently. Their normal defaults leave the existing Razi experience unchanged, and disabling them never removes the native recipes supplied by planet mods.

## Faster Loading for Large Modpacks

Razi Protocol depends on many planet mods. For players with long startup times,
Factorio already offers optional **prototype-data** and **sprite-atlas**
disk caches. These must be enabled **on each player's computer**, rather than
through Razi's mod settings. The first startup builds the caches; subsequent
unchanged launches may be much faster. See our
[Faster Startup & Troubleshooting Guide](docs/STARTUP_PERFORMANCE.md) for
setup steps, trade-offs, and how to identify the slow phase from Factorio logs.

## Campaign Structure

Seven solar systems are arranged as three outward pairs after the Calidus home system. Unlock both systems in a pair, choose which planet chains to tackle first, then master **both** to move to the next frontier.

| Tier | System | Planets | Identity |
| --- | --- | --- | --- |
| Home | **Calidus** | Nauvis, Muluna, Calidus Drift salvage anchorage; optional Eneas | Familiar Space Age industry, the first system card |
| Frontier 1 | **Solaris** | Vulcanus, Castra Prime, Arig, Hyarion, Tellus, Corrundum; Igrys, optional Athos | Military and advanced industrial science |
| Frontier 1 | **Nyxaris** | Gleba, Moshine, Apia/Carnova, Panglia; Foliax and Rabbasca | Computation, exotic biology, environmental challenges |
| Frontier 2 | **Vibrant** | Fulgora, Ribbonia, Paracelsin, Shchierbin; optional Cerys | Alien chemistry and galvanization |
| Frontier 2 | **Vespera** | Muria, Aquilo, Rubia, Maraxsis; Obsidiax | Extreme environments, cryogenics, research-data production |
| Frontier 3 | **Beetlejuice** | Cubium, Linox, Secretas, Frozeta | Outer-rim manufacturing and specialist resources |
| Frontier 3 | **Umbra** | Tenebris, Crucible, Vesta; Carna | Unusual and dangerous late-game experimentation |
| Finale | **Deep Space** | Aegis/Bellicos, the solar-system edge, Shattered Planet; optional Nexus/black-hole branches | Pulsar science, Promethium, transceiver |

### The interstellar routes

    Calidus
      |---- Solaris ----|
      |                 |---- Vibrant ----|
      |---- Nyxaris ----|                 |---- Beetlejuice --|
            \           |---- Vespera ----|                   |---- Deep Space
             \---- (local system crosslinks) ---- Umbra -------|

This sketch represents **choices**, not all physical connections. Full interstellar route and local-spoke details are in [Seven-System Design](docs/SEVEN_SYSTEMS.md) and [Asteroid Hazard Guide](docs/ASTEROID_ROUTES.md).

Calidus keeps Nauvis and Muluna. Vulcanus and Gleba anchor the first frontier, while Fulgora anchors Vibrant. Solaris and Nyxaris are independent first-frontier entry choices. Vibrant and Vespera require mastery of both first-frontier systems; Beetlejuice and Umbra likewise require mastery of both second-frontier systems. An outer-frontier mastery technology gates the final edge journey.

### Optional regions

- **Eneas** remains with Calidus; **Cerys** follows Fulgora to Vibrant and **Rabbasca** follows Gleba to Nyxaris.
- **Dea Dia and Pelagos** remain optional Nyxaris expansions. The Dea Dia sub-system's native internal connections are preserved.
- **Nexus-Updated and VoidProcessing-Updated** remain optional Deep Space expansions, never prerequisites to reach the main transceiver finale.
- Aegis/Bellicos is **required** by the current pack and retains its own internal pulsar and stargate routes.

### Progression principles

Different planets in the same system should provide genuine early travel choices, while the system's research prerequisites determine when advancing to the next frontier makes sense. Science ingredients are compressed into chapter cards, which can be automated and transported between systems without making every lab universal.

Changes to existing discovery technology effects, route placement and science cards are intended to preserve prototype IDs for old saves. This revamp is not yet validated against a full Factorio runtime load; test a copy of your save before upgrading.

## System Cards

Eight cards now connect the scientific ladder:

1. Calidus Tech Card
2. Solaris Tech Card
3. Nyxaris Tech Card
4. Vibrant Tech Card
5. Vespera Tech Card
6. Beetlejuice Tech Card
7. Umbra Tech Card
8. Deep Space Tech Card

The first pair of frontiers uses Calidus science. The second pair consumes Solaris and Nyxaris cards. The third pair uses Vibrant and Vespera cards. **Beetlejuice and Umbra** cards converge at the Outer Frontier mastery gate and the singularity finale.

Vespera and Umbra currently tint existing icon assets, rather than introducing unsupported or unapproved new artwork. Dedicated star and card art are a separate polish pass. The card recipes contain only science expected from their required core planets, rather than injecting science from optional integrations.

## Expanded Community Planet Compatibility

The October 2026 optional modpack expansion now recognizes additional planets and atypical space destinations, including Ferrum, Velora, Nulla, Khemia, Arcanyx, Wit, Balack, Solar Halo, Rabbasca Underground, and the Shattered Planet extension. Each remains optional; Razi integrates them only when their actual mod and world prototypes exist.

The current scope protects original moon orbits, underground-only surfaces, specialized travel hazards, native recipe progression, and the original discovery technologies. See [Community Expansion Compatibility](docs/COMMUNITY_EXPANSIONS.md) for the complete sixteen-mod audit and the important full-pack validation requirements.

## Calidus Dyson Sphere megaproject

Razi includes the maintained Factorio 2.1
[SLP Dyson Sphere Reworked port](https://mods.factorio.com/mod/slp-dyson-sphere-reworked-fork)
and [K2 Dyson Rebalance](https://mods.factorio.com/mod/k2-dyson-sphere-rebalance).
Solar-orbit destinations become a distinct Calidus home-system
construction project. Razi ties its six native research technologies to
existing planet-industry milestones, while preserving source-owned plasma,
satellite launches, receiver power caps and planetary repeaters.

Galactic Operations now has a read-only **Stellar Works** page.
See [Calidus Stellar Engineering](docs/CALIDUS_DYSON.md) for progression,
configuration, remaining source-limitations and save compatibility.

## Shared interplanetary factory components

Razi now adds **two craftable shared engineering components** based on
proven source materials rather than another batch of science requirements:

- **Precision Control Matrix**: Moshine optical cable, Paracelsin zinc,
  Fulgoran holmium and Vulcanus K2SO rare metals. Consumed by
  manufacturing alternatives on Aquilo, Rubia and Linox.
- **Extreme-Environment Lattice**: a precision matrix with Rubia
  craptonite, Tenebris chitosan, Linox rare earths and stable Gleba
  carbon fiber. Supports high-end Vesta factories and Deep Balack.

They are optional, unlock after the native suppliers, require shipping,
and never enter compulsory science cards or the original source recipes.
The Galactic Operations Cargo Network page shows their research status.

See [Shared Factory Components](docs/SHARED_FACTORY_COMPONENTS.md).

## Multi-world industrial partnerships

The optional Galactic Industrial Network adds **14 extra recipes** joining
three to five existing planetary industries. Ten become available in
Balanced mode; four more are Deep-only. Each requires the participating
worlds, their genuine supplier recipes and original research. The native
manufacturing recipe remains available with no new science requirements.
New bonuses are limited to 25% output at 15–20% longer crafting time,
with additional imported ingredients and no productivity/recycling bonus.
See [Galactic Industrial Network](docs/GALACTIC_INDUSTRIAL_NETWORK.md).

## Connected research across every frontier

Razi's focused tech-tree pass now guards science prerequisites against
late-only supply recipes, corrects Shchierbin's science handoff, and
adds five cross-system research links. It uses native Igrys and Foliax
research to connect the first frontier to the middle systems, and native
Cerys and Obsidiax research to connect the middle to the outer systems,
only where verified cycle-safe in the installed technology graph.

The compact **Show only essential technologies** view now includes
installed Razi planets' original discovery research, not only the
main star-system milestones. No new mandatory science pack, technology
prototype or research cost is introduced. Details are in
[Focused Tech Tree Rework](docs/FOCUSED_TECH_TREE_REWORK.md).

## Required planetary campaign and non-planet bridges

Cerys, Eneas and twelve other formerly optional or recommended 2.1 worlds
are now part of the required installation. Existing destination technologies
are woven into the **final** stable-singularity milestone where reachable
without tech cycles. Native recipes and moon puzzles remain untouched.

Dea Dia and Pelagos currently have only Factorio 2.0 portal releases, and
Ferrum's documented 2.1 build has a version-floor mismatch. Those three
remain guarded optional worlds until compatible releases can be validated.
No new non-planet mod is installed merely for its ideas.

See [Required Worlds & Bridge Roadmap](docs/PLANETARY_BRIDGES_AND_MASTERY.md).

## Planet Integrations

Some world relationships need particular care:

- **Muria** now serves as the entry point to Vespera: Muria -> Aquilo -> Rubia -> Maraxsis. It is no longer entered through Vibrant.
- **Ribbonia -> Paracelsin -> Shchierbin** is Vibrant's core science chain.
- **Cubium -> Linox / Secretas -> Frozeta** stays in Beetlejuice, while **Tenebris -> Crucible Orbit -> Vesta** is now in Umbra. Crucible's native landing route is preserved.
- **Castra** branches into Arig and Hyarion, converging again at Tellus and Corrundum.
- **Moshine, Apia/Carnova and Panglia** open independently from Nyxaris, with Pelagos and Dea Dia remaining optional.
- **Aegis and Bellicos** keep their complete internal pulsar/stargate expedition beyond the solar-system edge.

The last data-stage route pass removes unintended cross-chapter shortcuts among the systems Razi owns, without deleting internal source-mod networks.

## Endgame Philosophy

Deep Space is a genuine finale after **both** outer-frontier chapters.

Outer Frontier Mastery requires science from Beetlejuice and Umbra and is inserted ahead of the existing outer-edge research when that native technology is available. The transceiver sequence then proceeds through:

- Intergalactic Singularity Theory
- Intergalactic Singularity Test Fire
- Stable Intergalactic Singularity
- Intergalactic Signal Lock

All seven main chapter cards participate in the singularity research ladder. Deep Space remains a separate endgame card, especially for Nexus.

When optional Nexus is installed, its Omega science is condensed into the Deep Space card. Nexus, Oort Cloud, Sol and optional black-hole content are additional Deep Space adventures, not mandatory prerequisites for the campaign's primary victory.

## Compatibility and Modpack Quality

This development branch includes a cross-mod compatibility registry, focused
engine-free regression tests, and two complementary audits for final prototype
dumps. These tools help us integrate community fixes without rewriting other
authors' mods or making unverified assumptions about their mechanics.

- [Compatibility policy and upstream patch registry](docs/COMPATIBILITY.md)
- [Planet Field Guide](docs/PLANET_FIELD_GUIDE.md)
- [Six new planet expeditions](docs/OPTIONAL_PLANETS.md)
- [Seven-System Galaxy Design](docs/SEVEN_SYSTEMS.md)
- [Factorio prototype validation guide](docs/VALIDATION.md)
- [Next-pass implementation checklist](docs/INTEGRATION_ROADMAP.md)

After loading the real required modpack with Factorio 2.1 and exporting a
`--dump-data-raw` snapshot, run:

```bash
python3 scripts/audit_prototypes.py /path/to/data-raw-dump.json
python3 scripts/audit_compatibility.py /path/to/data-raw-dump.json
```

The second command reports hard errors and review-only warnings for
system-card ingredients, incompatible research triggers, recycling,
surface conditions, and the known water-loop issue.

**Development status:** automated GitHub checks do not launch Factorio or
verify the full dependency pack. Do not publish or migrate a long-running
save until the real engine and all optional combinations have been tested.

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
- Shchierbin
- Muria
- Dea Dia (optional)
- Corrundum
- Apia
- Moshine
- Panglia
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

Optional supported branches include Dea Dia, Pelagos, Nexus, Celestial Weather and its additions, Eneas, Cerys, Void Processing, a range of enemy packs, and a variety of quality-of-life and compatibility helpers listed in `info.json`.

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


## Interstellar cargo and defense integration

Two required non-planet mods extend the factory network without adding any
new planet: [Planet Express](https://mods.factorio.com/mod/planet-express)
(v2.1.9+) dispatches actual cargo platforms using real rockets, and
[Rocket Turrets Upgraded](https://mods.factorio.com/mod/upgraded-rocket-turrets)
(v2.1.1+) adds a four-tier defense manufacturing ladder across Vulcanus,
Fulgora, Aquilo and space platforms. Razi safely anchors their source-owned
technologies to matching planet research where valid. It never overwrites
Planet Express schedules or turret damage/recipes.

The Galactic Operations map-window gains **Research & Campaign** and
**Cargo Network** pages, including technology prerequisites, card-unlock
readiness and the source mod's actual fleet configuration guidance.
The new tech-graph audit works on an exported Factorio data-raw dump.
See [Cargo & Research Integration](docs/CARGO_AND_RESEARCH.md).

## Galactic Operations UI

A first-party, seven-system-aware planet and space-platform dashboard is included. Open the **Galactic Ops** button in Remote View on the space map, or optionally press **Ctrl+Shift+G** while viewing the map. It never occupies the shortcut bar. Search, filter, favourite, review platform status, and jump safely into Remote View without generating surfaces or replacing the vanilla selector. See [Galactic Operations guide](docs/GALACTIC_OPERATIONS.md).


## Razi Universe Background

The original, static seven-system starmap now has a galaxy-wide starfield, distinct coloured nebulae for each system and Deep Space, a connecting dust current, and three subtle asteroid-belt halos. Change the **Custom universe background** setting between Off, Subtle (default) and Cinematic, and independently toggle nebulae or belt atmosphere. Assets are 1024px or smaller and keep all native route and planet artwork. See [background notes](docs/STARMAP_BACKGROUND.md).


### Expanded Galactic Scenery

The star map also includes finer spiral nebula filaments, additional dust currents, scattered distant star clusters, atmospheric debris around all three belts, and Deep Space lensing. **Detailed galactic scenery** is on by default; disable it for the earlier minimalist backdrop. For a navigational-astronomy look, the optional **Observatory constellation ring** starts off so it will never be mistaken for a travel route. All sprites remain 1024px or smaller.
