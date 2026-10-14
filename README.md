# Razi Protocol

Razi Protocol started as my attempt to make an absurdly large Space Age planet pack feel like one game. It's built for Factorio 2.1 and Krastorio 2 Spaced Out.

The planets still have their own machines, recipes and quirks. What changes is how you get between them, what you research along the way and why those separate factories are worth connecting. The transceiver now opens the journey into Deep Space, while The Convergence is the real ending that gives those connected factories a reason to exist. Nexus retains its native late-game branch.

**2.1.60: Finale readability and integration polish.** Convergence
construction displays fractional partial deliveries, stage-specific
colors, and immediate next-action guidance using the installed
technologies and real recipe unlocks. The Protocol Codex now clearly
labels freight deliveries and live transmissions instead of treating
them as technology research. Unlocked Deep Space locations in the
Galactic Atlas include practical expedition dossiers and direct links
to the finale console. None of these panels creates a route, laboratory,
surface, recipe unlock or fake Dyson energy data.

**2.1.59: The Seven-Sun Array is visible in Galactic Operations.**
Its five construction modules light up as your force delivers physical freight.
The final phase can require a placed Dyson energy receiver from the original
Dyson Sphere mod, if a compatible receiver entity is exposed. This is a
real placed entity, not an invented satellite or energy-production statistic.
Once the final accord reaches the expedition platform, the transmission
unfolds in four force-wide updates over twelve seconds, ending with
Factorio's native victory screen. The sequence survives save/reload and
previous winners remain victorious.

**2.1.58: The ending now has five physical phases.** After the original
Stellar, Industrial and Deep-Space shipments, engineers prepare four
Pulsar Resonance Mandates, research Convergence Ignition Protocol and
deliver one final Ignition Mandate containing all seven system cards.
Native Dyson distribution technologies contribute to the final research
when safely present. The native ending fires only after the last
shipment, not when research finishes, and older Convergence victories
remain recognized.

The Convergence's Stellar and Industrial freight unlocks at the
Commission; its Deep-Space and Pulsar Resonance freight unlock at
Synchronization. The final Ignition freight unlocks with its own
dedicated research.
Galactic Operations shows each phase's delivered total, physical cargo
in your inventory, and an active/locked/completed status. Victory still
requires real delivery aboard a force-owned expedition platform.

## Planet quality gate

Panglia is back as a **required** late Nyxaris planet (0.7.2+). Its timewarp, DNA, and simulation progression is source-owned; Razi connects it after Moshine and Apia/Carnova and supplies a small, optional two-way industry loop. Muluna remains mandatory; Planet Wit and Shchierbin are still excluded. Back up existing saves before changing planetary mods. See [Planet Quality Audit](docs/PLANET-QUALITY-AUDIT.md).

## Nexus and Celestial Weather (2.1)

Nexus-Updated, Nexus Rebalanced and Nexus Bosses are now part of the curated endgame, with the Nexus Threat fork and its original boss-enemy dependencies. **Nexus Bosses owns all nine battles, trophies, the native warp key, Silence and its route unlocks.** Razi now tracks all **nine individual boss victories** from the source mod's read-only per-force snapshot, as well as Whisper, Chorus, Convergence, bearings and Silence. Six preparation milestones follow photon electronics, storm prediction, shielding, and omega power. Both the Journal and Galactic Atlas can open the original Nexus Codex. No duplicate bosses, trophies or rewards are added. Rebalanced keeps its authored omega-lab, production costs, quality and Oort/Sol warp-drive protections.

Celestial Weather (Updated) and Celestial Weather Additions (2.1) provide configurable visuals on the supported planets, including Panglia, Rubia, Vesta, Muria and Paracelsin. The Paracelsin permanent winter stays **off by default** in the upstream add-on. An **Atmospheric Field Guide** now appears in the Expedition Journal and planetary Atlas, showing each source setting and relevant environment notes. Razi does not add separate weather loops.

Outer Rim remains **optional and experimental**. Its 2.9.x update redraws routes and distributes research between worlds in different Razi systems, while its own author flags K2SO integration as unreliable. Do not make it a prerequisite for the seven-system campaign. See [Nexus and Atmosphere Integration](docs/NEXUS-ATMOSPHERE-INTEGRATION.md) for source-owned systems, quality gates and the testing plan.

## Muluna compatibility

**Muluna remains the required Nauvis moon.** The independent Biological Machines planet **Wit** is incompatible with Muluna and is explicitly excluded (`! biological-machines-planet-wit`). Razi Protocol does not require or integrate Wit; keep Muluna enabled and disable Wit in Factorio's mod manager. Do not enable the complete Biological Machines Modpack because it requires Wit. **Balack remains supported independently** and does not depend on Wit.

## Why I Made It

Big Space Age planet packs are fun, but they also tend to suffer from the same problems:

- Too many disconnected discovery technologies.
- Too many duplicate or overlapping routes on the starmap.
- Too many late researches that ask for walls of unrelated science packs.
- Too many endgame add-ons fighting over the same progression space.
- Too many optional enemy and compatibility mods that do not naturally land where they make thematic sense.

I wanted a galaxy you can actually navigate, with different ways through it and reasons to revisit earlier factories.

## What's Different

- Rebuilds the starmap into named progression chapters: Calidus, Solaris, Nyxaris, Vibrant, Vespera, Beetlejuice, Umbra, and Deep Space, with the Aegis/Bellicos pulsar expedition isolated far beyond the solar-system edge.
- Adds system discovery technologies for the major custom systems.
- Adds system tech cards so later progression can ask for chapter mastery instead of giant science-pack soups.
- Rehomes many planets so they sit in a cleaner route and unlock order.
- Integrates Linox and Muria into the campaign without retaining redundant or unfinished planets.
- Cleans up a large amount of route clutter from source mods that were not designed around one shared starmap.
- Uses K2SO's real intergalactic transceiver as the **gateway into Deep Space**. The solar-system edge, Aegis/Bellicos, Shattered Planet, Nexus and other late expeditions remain for the proper final act.
- Replaces Nexus omega-science clutter with a more readable Deep Space card-driven endgame when Nexus is present.
- Routes optional custom enemy mods onto planets that fit their theme, while suppressing default biter noise where appropriate.
- Adds Science Tab cleanup so system cards, planet science, and research-data items land in more readable groups.
- Adds Vehicles & Infrastructure as a dedicated crafting tab to reduce early Logistics bloat.
- Includes narrow compatibility fixes for K2SO enhancement/tweak mods, route assumptions, late prototype edge cases, and overlapping planet content.

## FluxWorks industrial companion (experimental)

FluxWorks 0.2.12+ is an optional expansion to Razi's manufacturing. Its four Flux spectra, specialized machines, phase logistics, and K2SO production are now compatible with Razi's seven-system campaign. FluxWorks does **not** replace the Shattered Planet space location, victory, global planet resources, or chapter research in companion mode.

The four FluxWorks science packs remain optional mastery research instead of mandatory costs for ordinary industrial technologies. Four additional production recipes are attached to the Solaris, Nyxaris, Vibrant, and Vespera chapters. Rift Exchange transfers require Outer Frontier Mastery so the logistics system cannot skip the main campaign.

See [FluxWorks Integration](docs/FLUXWORKS_INTEGRATION.md) for the exact responsibilities, test matrix and important existing-save warnings. This is still experimental until tested in the actual Factorio engine.

### Seven-System Industrial Atlas

With FluxWorks installed, seven **optional regional industry technologies** offer specialized production for Calidus, Solaris, Nyxaris, Vibrant, Vespera, Beetlejuice and Umbra. The Codex adds a matching violet **FluxWorks | Industrial Atlas** chapter with seven engineering missions, suggested factory worlds and short narrative briefings. Nothing becomes a travel requirement.

See [FluxWorks Industrial Atlas](docs/FLUXWORKS_INDUSTRY_ATLAS.md) for details and validation notes.

### Linked FluxWorks factory networks

Five optional industry exchanges connect pairs of FluxWorks system workshops, from Calidus–Solaris aerospace framing to Nyxaris–Umbra living phase technology. The FluxWorks Codex chapter has twelve research-tracked objectives, and duplicate FluxWorks technology arrows are simplified without lifting research requirements. Source-mod recipes and the campaign gates stay intact.

See [FluxWorks Industrial Exchanges](docs/FLUXWORKS_INDUSTRIAL_EXCHANGES.md).

### FluxWorks machine progression and Codex previews

When FluxWorks is enabled, the Industrial Atlas now shows each specialization's actual factory recipe, ingredient and output quantities, recommended machine, and suggested production world. Its twelve optional research goals have their own chapter progress and no longer inflate the main campaign's completion totals or distract from higher-priority story research.

Selected FluxWorks engineering technologies also have lighter research costs in **Razi companion mode only**. All requirements and rewards remain intact; standalone FluxWorks is unchanged.

See [FluxWorks Progression and Usability Audit](docs/FLUXWORKS_PROGRESSION_AUDIT.md) for the exact changes and playtest checklist.

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
| Home | **Calidus** | Nauvis, Muluna, Calidus Slip Stream departure corridor | Familiar Space Age industry, the first system card |
| Frontier 1 | **Solaris** | Vulcanus, Castra Prime, Arig, Hyarion, Tellus, Corrundum; Igrys | Military and advanced industrial science |
| Frontier 1 | **Nyxaris** | Gleba, Moshine, Apia/Carnova, Panglia; Foliax and Rabbasca | Computation, exotic biology, environmental challenges |
| Frontier 2 | **Vibrant** | Fulgora, Ribbonia, Paracelsin; optional Cerys | Alien chemistry and galvanization |
| Frontier 2 | **Vespera** | Muria, Aquilo, Rubia, Maraxsis; Obsidiax | Extreme environments, cryogenics, research-data production |
| Frontier 3 | **Beetlejuice** | Cubium, Linox, Secretas, Frozeta | Outer-rim manufacturing and specialist resources |
| Frontier 3 | **Umbra** | Tenebris, Crucible, Vesta; Carna | Unusual and dangerous late-game experimentation |
| Gateway → Deep Space | **Solar System Edge** | Transceiver activation opens the Aegis/Bellicos and Shattered Planet expeditions, with Nexus/black-hole branches | Seven system cards, native K2SO transceiver; Deep Space science afterward |

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

- **Cerys** follows Fulgora to Vibrant and **Rabbasca** follows Gleba to Nyxaris.
- **Dea Dia and Pelagos** remain optional Nyxaris expansions. The Dea Dia sub-system's native internal connections are preserved.
- **Panglia** has direct Moshine and Apia/Carnova freight routes, a distinct Nyxaris orbit, new Chronicle research objectives, and guarded Moshine optical-cable / Panglite-glass production exchanges. Neither bonus recipe replaces native manufacturing.
- **Nexus and Void-related endgame branches** remain beyond the transceiver gateway, not required for the seven-star arrival sequence.
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

The first pair of frontiers uses Calidus science. The second pair consumes Solaris and Nyxaris cards. The third pair uses Vibrant and Vespera cards. **Beetlejuice and Umbra** cards converge at Outer Frontier Mastery, enabling the transceiver expedition gateway rather than ending the game.

Vespera and Umbra currently tint existing icon assets, rather than introducing unsupported or unapproved new artwork. Dedicated star and card art are a separate polish pass. The card recipes contain only science expected from their required core planets, rather than injecting science from optional integrations.

## Expanded Community Planet Compatibility

The October 2026 optional modpack expansion now recognizes additional planets and atypical space destinations, including Ferrum, Velora, Khemia, Arcanyx, Balack, Solar Halo, Rabbasca Underground, and the Shattered Planet extension. Each remains optional; Razi integrates them only when their actual mod and world prototypes exist. Nulla is excluded because its final-fixes compatibility pass crashes in the curated full pack.

The current scope protects original moon orbits, underground-only surfaces, specialized travel hazards, native recipe progression, and the original discovery technologies. See [Community Expansion Compatibility](docs/COMMUNITY_EXPANSIONS.md) for the complete sixteen-mod audit and the important full-pack validation requirements.

## The Protocol Codex

A built-in **210-milestone Protocol Codex across eighteen original story
chapters** guides the full seven-system K2SO campaign. Open it during
normal gameplay using the small top-row book button or **Ctrl+Shift+J**;
pin a goal to a compact optional tracker. Every milestone has original
narrative and practical engineering notes, plus fifteen recovered
story transmissions, collapsible chapters, filters and a next-milestone
navigator. Progress uses native
force research, supports existing saves and parallel worlds, and skips
unavailable mod technologies. It introduces no rewards, extra research
gates or dependency on the unrelated Quest Book mod.

The large-format Journal has a dedicated chapter navigator, an expanded story reader, warm chapter color accents, a research-objective card, and **no horizontal scrollbars**. Use the chapter dropdown to jump instantly or the mouse wheel to browse without visible vertical scrollbar clutter. The window scales to your Factorio UI size and keeps all original quests and research logic.

See [Expedition Journal](docs/EXPEDITION_JOURNAL.md).

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
Modern bonuses are capped at 25% output, generally at 10–20% longer crafting time,
with additional imported ingredients and no productivity/recycling bonus.
See [Galactic Industrial Network](docs/GALACTIC_INDUSTRIAL_NETWORK.md).

## Connected research across every frontier

Razi's focused tech-tree pass now guards science prerequisites against
late-only supply recipes, preserves the asteroid-belt-to-Paracelsin science handoff, and
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

Cerys and ten other formerly optional or recommended 2.1 worlds are now
part of the required installation. Eneas is explicitly incompatible because
its source mod forces unrelated Construction Drones and RPG System dependencies.
Existing destination technologies
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
- **Ribbonia -> Asteroid Belt -> Paracelsin** is Vibrant's core science chain.
- **Cubium -> Linox / Secretas -> Frozeta** stays in Beetlejuice, while **Tenebris -> Crucible Orbit -> Vesta** is now in Umbra. Crucible's native landing route is preserved.
- **Castra** branches into Arig and Hyarion, converging again at Tellus and Corrundum.
- **Moshine and Apia/Carnova** feed into **Panglia**, whose original Moshine data cells, DNA analysis, timewarp research and cloning remain essential. Pelagos and Dea Dia remain optional.
- **Aegis and Bellicos** keep their complete internal pulsar/stargate expedition beyond the solar-system edge.

The last data-stage route pass removes unintended cross-chapter shortcuts among the systems Razi owns, without deleting internal source-mod networks.

## Endgame Philosophy

The first seven star systems are the **preparation**, not the ending.

Outer Frontier Mastery requires real Beetlejuice and Umbra research. It
leads to Intergalactic Singularity Theory, Test Fire and Stable
Singularity, then the original K2SO transceiver must be constructed,
charged and activated. Razi observes that real activated machine to
research **Intergalactic Signal Lock**. When the native technology chain
is safe, that research is required to unlock the Solar System Edge.

All seven system tech cards now feed this gateway. Promethium and
Deep Space cards remain **after** arrival rather than circular
ingredients needed to reach the edge. The source transceiver's
activation remains unchanged; its independent victory condition is
suppressed through K2SO's supported remote interface when available.

**The Convergence** is now the playable post-transceiver ending. After
reaching the Solar System Edge and undertaking the native late-game
expeditions, research the Convergence Commission. Three physical
factory-built manifests then turn prior research and materials into
something the galaxy can ship together:

- **Stellar Mandate:** 8 Calidus/Solaris/Nyxaris research payloads and
  orbital electronics. Native Dyson Sphere research is a prerequisite
  when installed and compatible.
- **Industrial Mandate:** 10 Vibrant/Vespera payloads with rare metals,
  Gleba bioflux and suitable existing supplier-world components.
- **Deep-Space Mandate:** 6 Beetlejuice/Umbra/Deep Space payloads,
  incorporating genuine native post-edge science materials where present.

Manufacture the manifests in original assembling machines. Carry them
physically onto a platform owned by your force, parked at the Solar
System Edge or a supported deeper destination. Open **The Convergence**
from Galactic Operations or from its linked Codex objective; submit
real items from your character inventory. Team contributions persist
by force, including partial shipments and force merges. The final
submission requires Deep-Space Synchronization research and displays
Factorio's genuine victory screen, with Continue enabled. Razi also
suppresses the source K2SO transceiver and vanilla Space Age
Solar System Edge victory triggers where their supported
`set_no_victory` interfaces are available.

This ending **does not** add a new planet, laboratory, artificial cargo
teleportation, replacement transceiver, or boss. It works with optional
source content when that content exists, but never pretends to have
shipped cargo merely because research was completed.

**Laboratory tiers** reuse the installed native machines instead of
adding custom Razi labs. Existing 2.1.54 custom lab items and entities
migrate back to ordinary vanilla Labs when upgrading saves.

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

## Factorio 2.1 K2SO planetary compatibility

Corrundum Compatibility+ 1.1.2+ joins the required K2SO integrations with
Castra, Rubia, Paracelsin, Cubium, Null's Tweaks and xyrc's Null Fork. Corrundum
owns its electrochemical research-data and tech-card conversion; Razi already
consumes the native electrochemical science in the Solaris system card and must
not create duplicate conversion recipes.

Secretas/Frozeta Krastorio Compatibility+ currently targets Factorio 2.0,
so it cannot be required in our Factorio 2.1 pack. The separate 2.1
Secretas/Frozeta Orbit Patch is optional because Outer Rim excludes it.
See [the source ownership matrix](docs/K2SO_PLANET_INTEGRATION.md#community-k2so-compatibility-ownership).

## Razi-owned space route network

Starting with 2.1.47, Razi enforces **one authoritative travel catalog**
across all seven systems. Native planet mods no longer add conflicting
local shortcuts or duplicate links between Razi-managed worlds. Native
moons, the original belt crossing, Dyson infrastructure and special
external dimensions stay connected through explicit exceptions. The
cleanup is on by default; a startup setting can temporarily disable it
for diagnosis. More in [route authority documentation](docs/ASTEROID_ROUTES.md#authoritative-route-catalog-2147).

## Solaris system readability

Version 2.1.46 pulls Solaris's planetary chart in from a 54-unit outer
orbit to a compact 35-unit extent. Seven purposeful local routes replace
the old ring: a southern/eastern industrial journey and a separate
Igrys expedition directly from the Slip Stream. The central Solaris
corona and busy first-frontier background dust are softer, and Balanced
orbit settings retain a single reference ring. Original discoveries and
source planet behavior remain unchanged.

## Space route coloring

Razi Protocol Dev includes its **own native-route hazard overlay** from
2.1.45. It colors actual Factorio 2.1 paths using the existing asteroid
threat calculations without altering connections or the research tree.
Two startup settings choose threat or chapter colors and whether to show
major/belt routes only or every verified local route. The previous
disconnected color strips have been replaced with short, consistent-width
segments. No extra mod is required; Space Route Overlay is incompatible to
avoid drawing the same route twice.

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

Optional supported branches include Dea Dia, Pelagos, Nexus, Celestial Weather and its additions, Void Processing, a range of enemy packs, and a variety of quality-of-life and compatibility helpers listed in `info.json`.

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

### Calidus Stellar Works: live infrastructure and galaxy presentation

Stellar Works now reports native placed Dyson receiver entities where the
source mod exposes placeable receiver prototypes, plus the receiving
surfaces and real research prerequisites. True satellite and MW telemetry
are intentionally shown as unavailable until a source API exists.
Its five research-phase portraits do **not** impersonate physical
satellite construction progress. The space map gets ten quiet nebula
and star accents using already bundled art. Both changes have safe
startup controls and no recurring game scans.

### Razi Asteroid Frontier (2.1.14)

Razi now owns the physical Vibrant, Vespera and Umbra asteroid belts rather
than depending on the original AsteroidBelt mod. Four existing long-distance
corridors include concentrated midroute asteroid fields, with corresponding
faint starmap details. The legacy Vibrant rim names and survey technology are
retained for save migration. **Back up older saves and disable AsteroidBelt**
before upgrading. See [Asteroid Routes](docs/ASTEROID_ROUTES.md).

## Discord Rich Presence (optional)

Razi Protocol Dev can now show the actual Expedition Journal chapter,
pinned or active quest, campaign progress and optional planet/platform
location on a custom **Playing Razi Protocol** Discord card. Per-player
sharing is **off by default**. A small original Node.js desktop helper
reads the local exported state and connects to Discord. No bot or
in-game HTTP traffic. See
[Discord Presence setup](docs/DISCORD_PRESENCE.md) for the required
Discord application ID, desktop helper and preview commands.
