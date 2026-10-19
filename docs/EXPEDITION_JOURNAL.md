# Expedition Journal: contributor overview

## The stable-scroll Journal redesign (October 2026)

The Quests navigation pane now remains alive when selecting quest entries or
opening chapter folders. Chapter sections are allocated once and toggled via
GUI visibility rather than frame rebuilds; only the right-side dossier changes.
Pinning preserves the reading pane, and chapter selection uses the same native
scrollbar. Routine event-driven story, filter and cross-view changes can still
rebuild intentionally. The presentation uses shorter chapter rows, a small
recommendation, narrower dossiers and compact science-card galleries instead
of repeated heavy frames and progress bars. The work does not introduce new
research or alter the campaign save model.

## Systems folio (3.0)

The fourth Journal folio is **Systems**. It shows source-backed, read-only status
for three optional external features without introducing a second progress
system: Planet Express fleet counts from its own per-player monitor dock,
Nexus-Updated engine-core counts and research limit, and Nexus Threat state
from its documented read-only `nexus-threat.get_state` remote interface.
Missing mods and locked techs show honest unavailable states, never invented
zeros. The Systems folio refreshes its named labels and bars every 120 ticks
**only while open**. This avoids resetting scroll position, expensive full
rebuilds and cross-force leaks. The source mods retain ownership of operations
and all original access controls. In particular, do not remove Planet Express
or Nexus Threat buttons until a supported upstream interface exists for their
full Monitor and stabilizer power controls.


The Expedition Journal is Razi Protocol's **single, coherent player-facing narrative interface**: Quests, Projects and Journal records. Its purpose is to explain what to do, why each destination matters, and what the factory has actually achieved.

**The key contract:** quest completion derives from real technology/discovery/boss events; Projects report their own genuine production, construction and delivery state; recovered transmissions are story unlocked by matching milestones. Never mark a delivery complete merely because its research was unlocked.

The opening Calidus act introduces the factory. Later system chapters tie discoveries into science and interplanetary logistics. The additional thematic chapters organize fleet engineering, side worlds, laboratories, defense, collaborations and lore without pretending they are additional star systems.

**For editors:** see [Localization](LOCALIZATION.md) for the seven split `locale/en/razi_journal_*.cfg` files, [Developer Handbook](DEVELOPER_HANDBOOK.md) for voice and design intentions, and [Architecture](ARCHITECTURE.md) for implementation ownership. Preserve existing quest IDs and source research; adding prose must not introduce imaginary unlocks.

**For UI contributors:** prioritize native Factorio readability, clear selected state, bounded scroll areas, stable viewport position when expanding chapters, lazy construction and no expensive per-tick scans. Check narrow resolutions and older saves.

**3.0 narrative pilot:** Ten RAZI Industries dispatches share the recovered
transmission archive, each unlocked by genuine existing milestones. Twelve
optional industrial opportunity briefs appear in existing planetary dossiers,
with guarded links to related real journal milestones.
See [RAZI Industries](RAZI_INDUSTRIES.md) for authoring and review. No new
quest gates, freight claims, per-tick work or second GUI were introduced.

The historical implementation notes below are preserved for context, but may describe an earlier design.

---

> **Current UI (October 2026):** The Expedition Journal has Quests, Projects and Archive. Open it with Ctrl+Shift+J. Projects follows ten real undertakings: First Space Platform, First Voyage, Skybridge, Beltbreaker, Dyson Sphere, Archive Array, Transceiver, the Ninefold Signal, Project Ark and the Convergence. Research portfolios and the recovery charter remain in their related Journal dossiers.

## October 2026: Nauvis is now a four-act expedition

Calidus now holds twenty source-backed research milestones in four
chapters of its opening act: First Machines (electricity, logistics,
automation, electronics and radar); The Growing Factory (green
science, steel, inserters, Automation 2, trains and engines); The
Chemical Age (oil, fluids, plastic, advanced circuits and chemical
science); and Into the Sky (space science, Muluna and two parallel
star-system discoveries). The chapter rail, cover and detailed quest
dossier all identify the correct Nauvis act.

Ten new quests track existing research prototypes. Five old stable
quest IDs (green science, steel, railways, oil and chemical science)
move from the supplemental Foundations index into Calidus rather than
being duplicated. Existing saves automatically register completed
technologies, missing K2 research remains safely skipped, and actual
gameplay technology prerequisites are unchanged. The later Foundations
index still contains solar, production and utility research.

No additional prototypes, item rewards, achievement flags, research
gates, inventory scans or per-tick GUI work are introduced.

## October 2026: Individual expedition chapter briefings

Every installed Journal chapter now has a native, optional briefing
frontispiece. Its chapter color and source sprite introduce a distinct
mission atmosphere; the story and field dispatch are tailored to the
system, technological discipline or expedition operation. Mission log
entries reflect real researched/available/locked objectives, with a
reliable Open Next Milestone action rather than fabricated quest awards.
The existing chapter-index / quest reader remains accessible without
a separate modal, second progress database or new tech prerequisites.
The chapter picker opens the corresponding briefing page, while
selecting a quest returns immediately to its detailed dossier.

Briefings are lazy-built on navigation and contain at most eight
milestones in the frontispiece; the full chapter index still lists
everything. Both quest reader and chapter cover use one bounded native
scroll pane, source textures and the existing theme palette. There is
no per-tick redraw work. The Journal is still navigable at reduced
resolutions and UI scales.

## October 2026: Expedition Codex dossier polish

The Codex now uses chapter-tinted editorial dossier headings, a raised
selection in the chapter rail, native technology art with fixed bounds,
and a quieter numbered cover treatment. Uncompleted prerequisite
milestones in each quest are clickable and lead directly to their real
source-backed journal entries. Their readiness meter counts completed
journal prerequisites; it does not pretend that science has been
produced or material freight shipped.

The header's ready tally opens the real Ready filter; the Projects
dossier has a compact source-owned stage summary and the selected
project gets the same visual treatment as a chosen quest. No new
runtime sprites, progress polling, simulated quest rewards, or
save-format migrations are added.

## October 2026: Expedition Codex visual language

The journal is now presented as an expedition field manual. The heading
and primary reading text use neutral ink; local chapter colors are reserved
for short navigation rules, statuses and selected milestones. An understated
folio tab row replaces a wall of competing buttons. The active chapter receives
the raised panel, while unopened chapters become entries in a compact index.

**Projects** use a project index with restrained existing game art and actual
stage completion. A separate dossier pane contains native platform accomplishments, Dyson construction,
Transceiver state and Convergence deliveries. Cargo chains remain reachable through Journal research links. Small screens use
a two-column selection grid above one scrollable reader. The original physical
game systems remain authoritative. No new sprite atlas, decorative game tick,
save migration, research technology or fake power/satellite telemetry is added.
## 2.1.62: Building the last physical Mandate

The five existing Convergence shipment objectives and saved
completion times remain unchanged. Behind the last one are
three craftable subassemblies made in original native factories.
The Galactic Operations console shows which components are
unlocked and present in your inventory, rather than treating
these as three new Codex delivery objectives.

The existing force-owned deep-space submission, twelve-second
transmission and final victory are unchanged.

> **Razi 3.0 Convergence update:** The older 2.1.56-2.1.60 notes below describe the historical twelve-second finale. The current branch requires seven powered witness stations and a powered Array Core, triples the first four Mandate totals, and transmits for two minutes. See the updated Convergence expansion section at the bottom.

## 2.1.60: Cleaner handoffs to Convergence

The Protocol Codex now labels actual physical Mandate contributions
as DELIVER or SHIP in its recommendation list. After final delivery,
its unresolved victory step is a pending SIGNAL, not a claim that
the player still needs to research Ignition. The surrounding
parallel-star recommendations remain available. The source research
requirements still come from the real Factorio technology graph.

The Galactic Operations finale panel gives a true fractional assembly
percentage and per-module progress bars, shows exactly which Mandate
recipe is unlocked, and identifies up to three actual missing native
research prerequisites for the currently active production stage.
Five native deep-space Atlas destinations now link directly to this
panel without bypassing any transport or unlock requirements.

## The Seven-Sun Array (2.1.59)

The five visible array modules, Dyson coupling readout and finale
transmission appear in Galactic Operations, alongside the existing
228 conditional Codex milestones. The displayed receiver count comes
from real force-owned entities when the installed source mod exposes
their prototypes, not a guessed launch/megawatt statistic.

The final delivery begins a persistent four-beat, twelve-second
transmission. Each beat announces meaningful progress to the
contributing force; the native win screen is displayed afterward.
Saving and reloading preserves the sequence, and existing victories
are never replayed.

## The Convergence: Resonance & Ignition (2.1.58)

The finale includes five player-carried delivery objectives and three
research milestones. Pulsar Resonance follows the existing Deep-Space
shipment, and the new Convergence Ignition Protocol opens the final
one-item accord. Its recipe combines all seven system cards plus the
Deep-Space card, and real manufactured components. The three new
Codex milestones are **convergence-resonance**,
**convergence-ignition-research** and **convergence-ignition**.
The base catalog now has **228 conditional milestones in 18 chapters**.

Delivering the fifth final shipment, not merely doing the research or
reaching the Solar System Edge, invokes Factorio's real victory screen
and allows continued play. Existing won saves from the 2.1.57
three-shipment ending retain their victory and force-wide progress.
No new lab, platform or independent industry simulation is created.

## The Convergence: post-edge finale (2.1.56)

The existing final chapter now follows the real ending past the native
transceiver. Six new Codex objectives track the commission, physical
Stellar and Industrial Mandates, final Synchronization research, physical
Deep Space delivery and actual victory. This raises the base catalog
to **225 conditional milestones in 18 chapters**.

Unlike standard Codex goals, the three shipment objectives and victory
read force-owned Convergence delivery state. Research completion alone
cannot fake a shipment. Clicking through each objective opens the
dedicated Convergence panel in Galactic Operations, even outside
Remote View. The panel displays delivered totals, materials, station
requirements, technology status and the next stage.

Partial delivered quantities, force win tick and winning contributor
are saved without changes to the previous quest IDs or their recorded
completion times. The final stage only fires the real Factorio win
screen when accepted cargo crosses the actual required threshold.
It then offers Continue so the expedition can keep exploring.

## Midfrontier industrial projects (2.1.52)

The Codex adds Fulgora capacitor, Aquilo cryogenic-controller,
Paracelsin electrocoil and Rubia craptonite-frame milestones, each with
an engineering note, a story, a real technology goal and a suggested
manufacturing world. The Paracelsin/Rubia goals count in the campaign
if their respective guarded research prototypes are installed;
Fulgora/Aquilo remain side projects.

There are now **218 conditional milestones in 18 chapters**, tracked
through genuine force research and existing Codex state checks. No
research is awarded by clicking a quest, and a modpack lacking any
optional manufacturing technology does not display that milestone.

## First-frontier workshop stories (2.1.51)

Three new optional engineering objectives in the **Industrial
Constellations** chapter connect Moshine silicon cells, Gleba carbon
fiber and Castra piercing-magazine manufacturing through actual
native supplier recipes. Each names its suggested workshop planet
and has a localized objective, story vignette and engineering hint.
The Codex derives completion from genuine research, and existing
Where This Leads links discover related quests without creating
any fabricated factory-production progress.

The core Codex catalog now contains 214 conditional milestones in
18 chapters. Unavailable optional exchange technologies are filtered
out of the current player's view.

## Campaign handoffs and the Calidus return freight (2.1.50)

The quest reader now lists up to three direct Codex successors for its
selected milestone, prioritizing active objectives and cross-chapter
handoffs. Missing optional technologies are not shown. Active, planned and
completed describe Codex story progress; Factorio's own research tree
still controls actual access. No tick-time scans are added.

The optional first-frontier relay mission follows Vulcanus, Gleba and
Moshine and returns the discoveries to Calidus industry. It appears only
when its guarded source recipe exists. The catalog now includes 211
conditional milestones across 18 chapters.

## Quest-first interface and icon normalization (2.1.49)

The Codex is intentionally a **two-view quest book**: **Quests** for
campaign chapters, objectives, search, science and requirements; and
**Journal** for transmissions recovered through genuine research. Its
separate Galactic Operations panel remains available for navigation and
trade but is not duplicated inside the Codex.

All displayed research, planet and item art now passes through
`scripts/razi_journal_icons.lua`. Factorio sprite widgets normally
size themselves to the native sprite. Large modded technology graphics
were defeating explicit width/height assignments and distorting rows.
Codex sprites now set `resize_to_sprite=false`, a fixed square image
box and `stretch_image_to_widget_size=true` so the sprite content
fits the assigned dimensions. Icon buttons use fixed native slot sizing.

Typical sizes: 18–20 UI units for navigation/priority, 26–28 for
chapters and galleries, and **36 maximum** for selected quest cover art.
Tracker and story icons follow the same rule. These are GUI units,
so Factorio's display scale still applies. The journal retains 210
source-researched milestones, all eighteen chapters, recovered signals,
search, pins, and the quest/cargo deep links. The current update changes
appearance and tab wording only, not research or unlock semantics.

The existing GUI mock and structural regression tests enforce bounded
sprite dimensions at multiple display scales. A full in-game check
with a large third-party planet sprite remains necessary.

# The Protocol Codex (Razi Expedition Journal)

The Codex is the campaign guide for Razi Protocol. It currently has 210
milestones across 18 chapters, from your first assembler to the end of
the intergalactic expedition. It reads the game's research progress
instead of tracking a second set of quest flags.

## Industrial Constellations

This chapter is for the factories that need cargo from more than one
planet. There are 24 trade and manufacturing milestones covering Moshine,
Paracelsin, Rubia, Linox, Tenebris, Vesta, Balack, Aquilo and K2SO.
The corresponding research has to exist in the current modpack for an
objective to show up. Deep-mode recipes stay out of Balanced mode.

For these missions, the Codex examines **only the selected native recipe**,
illustrating its actual input and output prototypes and identifying a suggested
workshop world. Recipe limits, machine categories, environmental restrictions,
and source-mod outputs remain authoritative. Research is *not* proof the player
has shipped, built, or manufactured a quantity.

## Chapter art direction (2.1.18)

Each chapter has its own colors, icon and short atmospheric line.
They're set in `scripts/razi_journal_themes.lua`. The icons come from
installed game sprites; if one isn't available, the Codex uses its
fallback emblem.

Chapter colors and motifs are present in the index headings, the currently
expanded chapter, chapter completion meters, selected objective text, reader
banners, objective and lore section rules, science/recipe galleries, the
recovered-transmission reader, and the pinned tracker. The interface uses
native Factorio progress bars for narrow colored rules instead of a custom
draw loop or per-tick graphics work.

The index progress numbers and bars occupy separate rows to avoid
horizontal overflow on narrow screens. Gallery artwork has a subtle native
framed tile, and the selected quest remains visually distinct from status.

**Scope:** cosmetic runtime UI only. All original 204 quest IDs plus six new return-cargo missions, 18 chapter IDs,
authoritative research completion, disabled-content filtering, localization
keys, and keyboard shortcuts remain intact. Verify with an in-game load and
at several display scales after deploying.

## Visual overhaul

The journal now appears in-game as **The Protocol Codex**, retaining all old
quest IDs, per-player preferences, completion records and timings. Goals use
native technology or space-location icons. The reading pane puts your actual
research objective and prerequisites before optional narrative sections.

When provided by installed mods, the Codex illustrates the **science packs**
needed for the selected research and shows **placeable buildings and item
recipes** unlocked by it, with buildings prioritized. These represent real
technology effects, not invented building-count quests. Missing sprites,
recipes, items and technologies are handled safely.

Search milestone IDs, technology names, planets and chapters in the left rail.
Results filter as you type and matching chapters expand automatically. Clear
search, jump chapters, or go to the previous or next entry. Icon galleries are
bounded and wrap into columns so no sideways scrolling is introduced.

## Access

- A compact book button appears in Factorio's **top GUI** during normal
  factory gameplay, on planets, and in remote view.
- **Ctrl+Shift+J** opens or closes the journal. It is rebindable.
- The expanded expedition window uses the available display area up to 1,370
  Factorio GUI units wide. Its left column is a structured **chapter index**
  with wrapped titles, progress counts, colored chapter headings, and a
  direct drop-down jump to any of the 18 chapters.
- The right-hand panel provides a full-width reading column with a separate
  research objective card and field notes, including Nexus combat and world
  weather information where available. Filter by All, Ready, Unfinished or
  Completed using a separate row from the main tabs.
- **No horizontal scrollbars.** All text is bounded and wraps inside its
  panel. Vertical scrollbars are visually hidden, but mouse-wheel scrolling
  still works when the expanded chapters or stories exceed screen height.
  Arrow buttons and the chapter jump selector remain accessible without
  scrolling. `Next entry` walks through available quests in the current
  chapter. The archive uses the same clean two-column presentation.
- Choose a chapter or quest in the left column; the right shows its
  original narrative, exact current research goal, up to four real
  unresearched Factorio technology prerequisites, and actionable tips.
  Color-coded chapter headings, chapter totals and unobtrusive progress
  bars keep the large catalogue readable.
- Pin a goal to the optional top-left objective tracker. The tracker
  starts **off** to avoid hiding gameplay or crowding a large modpack UI.
- The old map-only Galactic Operations button is unchanged.

## What counts as progress

Milestones are direct references to existing Factorio
`LuaForce.technologies`, including native K2SO and planet-mod research.
Goals are **not** separate mandatory quests. A researched technology
is complete in the journal even if it was researched before installation.
Absent or hidden goals are skipped. Missing quest prerequisites are
ignored for presentation, but the engine's actual tech prerequisites
continue to control what can be researched.

This is deliberately not a made-up completion detector for building
Dyson satellites or physically crossing the asteroid field. The journal
clearly describes those as tasks controlled by source mods. A research
goal is marked complete when its corresponding research is complete,
and nothing more.

All progress is force-shared automatically through Factorio's real
research status. Only the journal's per-player selection, pinned goal
and tracker visibility are persisted under
`storage.razi_expedition_journal`. Force merges, older saves and
new installations therefore do not require copying story completion
flags or replaying quest chains.

## Story outline

| Chapter | Focus |
| --- | --- |
| Calidus | Automation, first space science, Muluna, independent first stars |
| Solaris | Vulcanus, Castra, Arig/Hyarion, Tellus and Corrundum |
| Nyxaris | Gleba, Moshine, Apia/Carnova, Panglia |
| Vibrant | Fulgora, Cerys, Ribbonia, native asteroid belt, Shchierbin, Paracelsin |
| Vespera | Muria, Aquilo, debris survey, Rubia, Maraxsis, Project Seadragon |
| Beetlejuice | Cubium, Linox, Secretas, Frozeta |
| Umbra | Tenebris, Crucible, shattered divide, Vesta |
| Calidus Stellar Works | Native SLP Dyson research and receiver engineering |
| The Supply Web | Planet Express and two shared manufacturing components |
| The Intergalactic Signal | Outer mastery, Deep Space, singularity and transceiver |

Each milestone includes an original story vignette and a short,
context-aware engineering hint. The first two stars, Arig/Hyarion,
Vibrant/Vespera and Beetlejuice/Umbra remain free parallel branches.

## Compatibility and performance

- **Zero** new research/science packs, technologies, recipes, items,
  entity prototypes, quest reward grants or required planets.
- **No new scans.** Journal screens refresh when opened, manually
  refreshed, when their force finishes a native technology, and through
  the existing limited Nexus boss tracker update. Scripted research bursts
  remain coalesced into one deferred refresh per force.
- **One** GUI event dispatcher added alongside existing Galactic Operations.
- Existing UI events remain delegated, not replaced by separate
  competing handlers.
- Missing upstream mod or its native technology hides that chapter
  milestone without breaking other chapters.
- Research-based goals are conservative. The project intentionally
  does not impersonate actual planet landings, physical Dyson builds,
  platform route traversals or production quantities.

## Verification needed

Pure Lua and static Python tests cover source IDs, chapter branching,
missing source technologies, old-save backfill, UI hooks and lack of
new research requirements. The whole Factorio modpack must still be
loaded and tested in-game. In particular, verify UI layout/resolution,
multiplayer force progress, first-login buttons, and the actual
source technology IDs of every installed mod.

## Expanded story and recovered transmissions

The next Razi chronicle adds **103 optional native research or world-discovery
milestones** across seven additional chapters: Foundations, Expedition Fleet,
Unwritten Atlas, Seven Laboratories, Last Line, Black Laboratory and
Relay Fragments. All 54 original quest identifiers are preserved.

The Unwritten Atlas does not guess the technology identifier of its
19 extra worlds. Instead, it indexes the **real installed
`unlock-space-location` technology effect** per force on opening the
journal or finishing native research. Missing optional mods simply
do not appear. The event-driven GUI performs no periodic polling.

Fifteen substantial recovered transmission records weave an original
mystery through Calidus, Muluna, Castra, Moshine, Cerys, the asteroid
belt, Maraxsis, Tenebris, manufacturing, Dyson construction and the
final signal. They unlock after the matching **researched** native
technology, not after physically building an entity. This is
original Razi Protocol fiction, separate from the underlying mods'
canonical lore.

Side quests and transmissions do not gate travel, alter science, or
grant rewards. Original parallel star routes remain independent;
the journal reflects them rather than redefining them.

## Research storm behavior (2.1.22)

The Codex updates normally after one technology completes. When a cheat
or script researches many technologies at once, it combines the GUI work
and waits three seconds after the last relevant event before drawing
again. Quest completion is still read from the current force research,
so no progress is lost. This does not alter or slow the actual research;
it only avoids repeated GUI builds while mass research is underway.

## Industrial quest shortcuts (2.1.28)

The Protocol Codex now links 11 existing industrial milestones to the four
installed Cargo Network component families. **Inspect in Cargo Network**
opens the appropriate component's source and production details, with the
specific researched technology highlighted. The Cargo dashboard links
back to the correct Codex quest when such a quest actually exists.

Navigation does not change technologies, research completion, ship
schedules or real cargo. Existing Codex IDs and progress history are
preserved. Missing optional mods do not create fictional milestones.

## Expedition Priorities (2.1.29)

The chapter navigator now begins with a compact **Expedition Priorities**
card. Rather than choosing the first unfinished quest in the data file,
the Codex proposes one primary objective and up to two different active
chapters to pursue in parallel. Priority weighs significant discoveries,
industrial work and quests needed for later milestones.

**Researchable now** means the native technology exists, is enabled and
has no unfinished native research prerequisites; it does **not** mean the
player has stocked the science packs, built its research lab or completed
any logistical project. No items, recipes or research are granted.

The card highlights one near-term research or story roadblock when useful.
It distinguishes a missing native technology prerequisite from an
incomplete *Codex narrative milestone*, and does not select hidden,
missing or unsupported optional-mod goals. Disabled source technologies
remain in the blocked category rather than being advertised as available.

The recommended and alternative quest titles are clickable. Selecting
one opens its actual chapter, clears incompatible search/filter settings
and keeps the existing pinned objective untouched. The **Recommended
next milestone** button and fallback quest selection use the same
ranking. When an objective is chosen explicitly, the navigator scrolls
to it; otherwise the priorities remain visible at the top of the
navigator. No extra window height, horizontal scrolling, new tick work
or campaign completion state is required.

The recommendation calculation reuses the Codex's already computed
210-quest status snapshot on normal redraw, looks up live
`LuaTechnology.prerequisites`, and uses a fixed small dependency-count
index initialized when the module loads. Tests cover simultaneous star
branches, native and story blockers, disabled source technologies,
missing optional planets, empty states and deterministic tie-breaking.

## Codex navigation polish (October 2026)

The Codex status row now gives completion, ready objectives and the overall
progress bar more breathing room. The selected chapter still drives accent
colours, while a tighter reading flow, clearer expedition-priority card,
stronger chapter bars and wider header actions improve scanning at desktop
scale. Horizontal scrolling remains disabled in both reader columns.

## Frame-style safety (October 2026)

Factorio's FrameStyle cannot accept FlowStyle-only horizontal_spacing or
vertical_spacing properties. The campaign metrics header uses a horizontal
flow inside its native framed summary so the spacing remains adjustable;
the navigation priorities retain their native frame spacing. A stricter Lua
GUI mock now rejects invalid frame-style spacing and the Python suite checks
both problem locations. The quest catalog and saved progress are unaffected.

## New core expedition chapters: Athos and Nulla (2.1.81)

The Solaris chapter now records discovery of Athos and its original
Particulate Science research, resolving the native technology through the
recipe's actual unlock effect. The Vespera chapter records Nulla, its
remnant-powered electromagnetic robotics and Robotic Science. A new
Frontier Recovery Charter chapter entry in Supply Web tracks their joint
research milestone. Journal details reuse the installed technology's real
science costs, icons, recipe unlocks and blockers.

No new standalone GUI, duplicate science items or fake completion criteria
were introduced. Saved journal selection and chapter IDs remain stable.

## Complete 3.0 RAZI Industries story and archive dispatches

The Journal now contains a **25-entry corporate narrative** plus 15 legacy
recovered transmissions (74 records total). Entries open using real research,
discovery, physical Convergence stage progress or final victory. No separate
story completion flags or invented science unlocks exist.

Research and actual physical delivery events release short localized Archive
notices. Multiple records from a burst of research are summarized after
two seconds of quiet. New notices show an unread dot by the matching
Archive entry; clicking the entry clears the dot. The Archive's
**Dispatches: ON/MUTED** label is a per-player preference and does not
change access to records.

The final case, **The Right to Continue**, unlocks only when the game's
actual Convergence victory is registered. The five physical cargo stages
retain their original tracked progress and their timed last transmission.

The whole plot, editorial style and out-of-order planet rules are documented
in [Story Bible](STORY_BIBLE.md). See [Validation](VALIDATION.md)
for the notification, multiplayer and old-save test matrix.

## Hide Spoilers (ON by default)

Factorio Mod Settings > Map > **Hide Spoilers (research and journal)**
controls the shared spoiler mode. A full mod restart is not required.

- With **ON**, the quest index hides locked or nonresearchable future
  technologies, future chapters show only "Undiscovered chapter",
  and sealed Archive pages never reveal their future titles. Unreached
  Projects, including the Convergence, remain hidden until their real
  research is available.
  Active/current and completed objectives are still navigable.
- With **OFF**, the complete, original Journal index and locked
  Archive titles become visible immediately.
- This setting is independent of personal **Dispatches: ON/MUTED**
  controls; discovered lore remains readable even when notifications
  are muted.
- The basic research fog hides Razi-owned future technologies. Its
  separate expanded option may also conceal unresearchable technologies
  from other mods without changing their research prototypes. Turn the
  expanded option OFF if a planet mod uses unusual scripted unlocks.
- A force's real research achievements remain authoritative. The
  option does not reset objectives, Convergence shipments, scroll
  state or campaign completion.

The whole spoiler mode is reversible using runtime settings. The
native research-tree path must still be smoke-tested with the entire
modpack and older saves before public release.

## Additional research fog and onboarding controls

The Map-tab `razi-hide-spoilers` setting still controls Journal,
Archives and Razi research fog. A new independent
`razi-hide-other-tech-spoilers` runtime-global subsetting defaults ON
and hides future research owned by other mods while the main setting is
enabled, including techs otherwise rendered in red as locked.

Every technology with satisfied real prerequisites, and every researched
technology, remains visible and researchable; disabling research that
players can currently use would make progression impossible. Ownership
flags in save storage preserve the enabled/visible state for restoration.
The second toggle can be disabled without revealing Journal spoilers.

On a brand-new map the welcome is queued briefly while other mods print
their splash messages. Personal `razi-clean-startup-chat` (ON by
default) optionally calls `LuaPlayer.clear_console()` once before
printing our localized welcome. **It clears the entire console**, not
only messages from Nexus or Muluna, and therefore may remove important
warnings. Old saves and normal later chat are never cleared.

`razi-show-welcome` (ON by default) controls the personal welcome
message. Players can use `/razi-welcome` to replay its site/wiki/Discord,
Journal shortcut and admin-only testing tip. The welcome does not reveal
the ending or change research progression.

## Rubia unknown-technology compatibility

Rubia's own source creates temporary `rubia-unknown-technology-*`
placeholders with intentionally empty research prerequisites and an
uncraftable trigger. Rubia enables them while the real source technology
is unavailable, and it may synchronize their status again after Razi's
regular settings/research event. A generic "all prerequisites researched"
visibility rule therefore does not protect their names or the technology
list from dozens of question-mark icons.

With the expanded **Hide future technologies from other mods** option ON,
Razi explicitly treats those Rubia placeholders as presentation-only:
it hides the placeholder when its real Rubia technology is not yet
available, while **never hiding a legitimately reachable original
technology**. After a Rubia research, migration or
`on_technology_effects_reset` event, a one-shot deferred check uses
the Journal's existing 30-tick callback to reapply the placeholder
visibility filter. There is no continuous tech-tree scan.

Turning the expanded option OFF releases the Razi-managed visibility
flags, without unlocking Rubia's real research. Rubia still owns its
native per-planet scientific progression and research sync. Test new
maps, older saves, real Rubia research and setting toggles before release.

If another mod still shows Rubia placeholders after switching to this
feature-branch build, check for a third-party discovery-tree controller
that is also rewriting the same technology flags. Never modify Rubia's
source or delete its technologies as a workaround.

## Short-haul Orbital Catapult guidance

Muria, Rubia and Aquilo's existing quest dossiers now display the
**local orbital freight corridors** relevant to each world when the
required Orbital Catapult source and Razi's existing catapult link setting
are active. This is **informational**, not a new mandatory objective.

The Cargo Network reference displays a compact Vespera regional overview
with three route pairs, their actual native discovery-research status,
industrial use suggestions and source-owned equipment instructions.
Do not interpret these as live freight connections or claim the source
has placed powered catapults.

The general **Hide Spoilers** setting applies to both views. A route
is not named until both endpoints' real planet-discovery technologies
have been researched. When spoiler hiding is disabled the dossier can
preview future routes while identifying incomplete discovery research.
This introduces no separate saved completion flags or new scroll state.

## Regional Orbital Catapult expansion

The Cargo Network now groups Orbital Catapult lanes by **Solaris,
Nyxaris and Vespera** rather than only Vespera. With both startup
corridor toggles enabled, six regional pairs are listed after their
native world discoveries. The existing three Vespera pairs are
supplemented by Vulcanus–Castra, Gleba–Moshine and Rubia–Maraxsis.

The industrial dossier automatically shows discovered corridor partners
for Vulcanus, Castra, Gleba, Moshine, Muria, Rubia, Aquilo and Maraxsis.
New industry notes introduce Vulcanus's foundry logistics and
Maraxsis's underwater supply requirements. There is no new research
task, invented delivery contract or hidden progress counter.
Individual transport operation stays within the required source mod.

The two separate startup switches are
`razi-orbital-catapult-local-links` (legacy Vespera) and
`razi-orbital-catapult-regional-links` (new regional additions);
both default ON. Hide Spoilers continues to gate presentation of
undiscovered neighbors, not the underlying native researches.

## Regional Freight Desk

The Cargo Network reference now contains an interactive **Freight Desk**
beneath the source-backed orbital route overview.

Click the directional buttons of any corridor whose **both endpoint
discovery technologies are researched**. Choose a real item, enter a
whole number between 1 and 1,000,000, then **Add packing order**.
A per-player packing queue displays item names, directed endpoints,
the exact number of inventory stacks, and the number currently in
that player's inventory. Players can manually **Mark packed**,
**Unpack** or **Remove** an order.

The Freight Desk is independent of source machine state and does not
promise a launch or track a delivery. It is a guided preparation tool
for the mod's actual source-owned catapult machinery. Up to 20 saved
packing orders are permitted per player to minimize save growth.
A player whose route becomes undiscovered or disabled cannot add to it;
its saved order reappears when the route is valid again.

The usual Journal refresh control updates the player's inventory
comparison; research unlocks use existing refresh handling. Packets
or physical cargo are **never** inferred from checklist completion.

## 3.0: Field correspondence, archive reading and terminal welcome

The recovered Archive now holds **74 files** (15 legacy
transmissions, 25 original formal corporate files and 34
personal field accounts). The personal accounts carry recurring
human signatures across unrelated factories, letters and manifests;
their unlocks rely exclusively on existing gameplay milestones.

With **Hide Spoilers ON**, sealed entries are summarized with a
count and do not clutter the Archive with repetitive hidden titles.
Turning spoiler mode OFF restores previews. Opened field accounts
carry a FIELD ACCOUNT classification in the reading pane. Completed quests that recovered a field account provide a **Recovered Correspondence** button for that specific unlocked file. When
unread records exist, **Read next unread** lets a player open
the next recovered document and clears only that page's unread mark.
Personal notification muting still does not prevent recovering lore.

Research-driven dispatches distinguish new human correspondence
from ordinary recovered corporate archives and real Convergence
transmissions, without spamming repeated unlocks. The genuine
victory-only epilogue remains the last story record.

The startup welcome is an in-world RAZI Industries operations
terminal. It reports only previously **researched** operational
readiness (new local industry, space platforms, interplanetary
logistics or the Commission), and the number of *that player's*
unread transmissions. It never names hidden future systems. The
Journal shortcut is Ctrl+Shift+J. Razi's website, wiki, Discord
and the two explicit welcome commands are still available.

## The Witness Archive: browse the growing story (3.0)

There are now **74 archived documents** (15 legacy transmissions,
25 formal continuity case files, 34 personal field accounts).
Every record unlocks from an existing source milestone. Sixteen
additional personal accounts give Arig, Hyarion, Apia, Ribbonia,
Abacayba, Crucible, Vesta, Frozeta and other worlds specific human
perspectives without forcing a fixed expedition order.

The Journal's Archive navigator reports three recovered-file totals
and adds four filters: **All recovered**, **Expedition**, **Corporate**
and **Personal**. These are personal UI preferences. With
Hide Spoilers ON, filters never display unrecovered titles or
unavailable source records. Each opened Archive document includes
a **View discovery** button that returns to its actual completed
quest, with no future quest shortcuts.

We also refreshed 23 existing quest-story passages so the main
dossiers continuously foreshadow the Continuity Protocol's deeper
question without giving away the answer. Source planet mechanics
remain unchanged.

The RAZI welcome now has one additional current-research-driven
field directive, an accurate unread count and a real spoiler-cover
ON/OFF status. Both startup cleanup and message visibility remain
separate personal settings; `/razi-welcome clear` still explicitly
clears the user's entire chat, never selectively suppressing
other mod warnings.


## Projects: ten physical undertakings (Razi 3.0)

The **Projects** tab is reserved for physical accomplishments, major construction, or the endgame transmission. It is not a collection of ordinary research portfolios. The ten dossiers appear in expedition order:

1. **First Space Platform:** Build a genuine Space Age platform hub after launching a starter pack. Research alone or a platform placeholder is not enough. The record remains complete if the platform is later destroyed.
2. **First Voyage:** Guide a real space platform through at least one completed trip between space locations. The engine-reported completed-trip counter is authoritative; fuel production, a plotted route or an unfinished crossing do not count.
3. **Skybridge Initiative:** Use Razi's existing, explicitly configured directed Orbital Catapult links. Build actual native devices on both endpoint planets, issue a signed consignment with 20 real processing units at the origin, and physically carry its sealed receipt to the target. The native catapult mod does not expose trustworthy proof of which transport carried the item, so Razi states this limitation explicitly.
4. **Operation Beltbreaker:** Physically cross both Vibrant's Inner/Outer Rim route and Umbra's Shattered Divide. The platform must be seen entering the actual route, then complete the trip and reach a corresponding endpoint. Visiting rim worlds via other paths does not count.
5. **Dyson Sphere:** Develop the actual Calidus stellar research and construct source-owned satellites, repeaters and energy receivers. The existing research bar measures research only, never an invented percentage of physical construction.
6. **Archive Array:** Research and craft a dedicated powered RAZI Archive Relay, using native radar artwork. Place and power at least one station in each of three distinct star systems. Each live site reveals a recovered fragment, which remains permanently accessible from the Journal Archive once unlocked.
7. **Transceiver:** Build and activate the original K2SO intergalactic machine. Research alone does not mark the project complete.
8. **The Ninefold Signal (Nexus Boss Trials):** The required [Nexus Bosses](https://mods.factorio.com/mod/nexus-bosses) adds nine real source-owned summon encounters in three circles. Progress comes exclusively from the stable `remote.call("nexus-bosses","get_state").defeated[force.name]` flags for all nine canonical boss IDs. No trophies or research can spoof it, and native boss mechanics, lairs, Codex, Silence and warp-key unlocks remain intact. The new Project dossier displays each circle and offers source-owned Codex buttons.
9. **Project Ark:** Build a heavy (at least 1,000,000 kg), armed factory ship with 3+ thrusters, 4+ ammunition turrets and 2+ assembling machines. Then complete an actual trip to an approved Deep Space destination with that qualifying vessel. Weight or research alone is insufficient.
10. **Convergence:** Manufacture and physically deliver all five actual mandates and finish the real Convergence victory transmission. The save continues afterward.

### Preserved industrial references

**Cargo Network** is now an **Industrial Reference** opened through the existing Codex research links. Its component technologies, production chains, Orbital Catapult integration and interactive freight board are preserved, just no longer misrepresented as a major Project. The embedded scroll panel has a **Return to Projects** button.

**Frontier Recovery** remains an ordinary Athos/Nulla research charter in the existing Journal network chapter. Its original six research/discovery milestones and quest IDs are untouched; it no longer occupies a Projects card. Old direct project links redirect to the corresponding Codex milestones. Old saved project preferences default to **First Space Platform** when pointing to a retired item.

### Correctness and performance

The Space Age 2.1 `LuaForce.platforms` collection exposes real platforms, and each platform's built hub and `completed_trips` count determine the first two achievements. A very small force-level record persists attained milestones through platform destruction, reload and force merges. Event callbacks observe actual platform construction and state changes; the Journal also reconciles existing platforms on initial load, upgrades and opening the view. There is **no global per-tick platform scan**, no fabricated source-mod telemetry and no modifications to base-game platform schedules. The Great Projects add one optional RAZI Archive Relay technology, recipe and entity, plus a one-off source-issued freight receipt item. The 300-tick fallback only inspects forces with an actual pending crossing. An old save where the only historical platform has already been destroyed before Razi is installed cannot prove the lost achievement; the next live built platform or trip is needed.

The first platform is always visible. First Voyage becomes discoverable after a platform has been built; Skybridge and Beltbreaker unlock naturally with interplanetary exploration. The Archive Array is hidden until its own research is accessible, and Ark until the transceiver era. Dyson, Transceiver and Convergence still respect spoiler-relevant research. Source research and delivery IDs remain unchanged.

Regression source checks: `tests/test_first_platform_projects.py`, `tests/test_journal_projects.py`, `tests/test_journal_visual_polish.py`; Lua fixtures: `tests/lua/test_razi_platform_projects.lua`, `tests/lua/test_razi_project_spoilers.lua`, `tests/lua/test_projects_runtime_require.lua`. Full Factorio 2.1 in-game testing is still required for space-platform events, completed-trip timing, force merges, old saves and responsive GUI.

### Convergence expansion: the Seven-Sun Witness Accord

The physical endgame has a new mandatory seven-system building phase. Players research Independent Witness Accord (3200 research units), manufacture **seven or more 10 MW Witness Anchors**, keep one powered in each founding star system, then forge a **50 MW Seven-Sun Array Core** from additional late-game Convergence frames, matrices and lenses. The Core must be energized on the actual force-owned deep-space platform accepting the final shipment. Existing Dyson coupling is retained.

The first four Mandates now require **24 / 30 / 18 / 12** accepted units, up from 8 / 10 / 6 / 4. Research costs rise for Commission / Synchronization / Ignition, and the final two-minute signal includes the revealed BLACKOUT-SEVEN executive directive and the independent witnesses' rejection. Research and mandate materials alone cannot end the campaign. All prior recorded winners retain their existing victory and Archive epilogue.

The revelation comes in two installments unlocked by actual Deep-Space and Resonance deliveries, then a final epilogue. The original catastrophe was genuine; RAZI executives deliberately ordered the long quarantine afterward to keep assets under corporate control. The distributed physical Accord refuses the restoration of corporate ownership without transferring it to another solitary executive. The ending still permits continued play, preserving all player builds, native planet mechanics and original source-owned factories.

### Convergence: visit every reachable Deep Space destination

Before the final **Ignition Mandate** can be submitted, at least one **real player character** from the force must have personally arrived at every navigable and connected Deep Space location present in the installed modpack. Visits are tracked in `storage.razi_deep_space_visits`, per force, by actual physical arrivals aboard a valid, force-owned platform with a built hub and completed journey. Simply researching a location, flying an uncrewed platform there, Remote View, or looking at the Galactic Atlas does not count. Multiplayer teammates can collectively complete the route; visit receipts survive player logout, platform destruction, reloading and force merges.

The **Outer Expedition** checklist in the Convergence dossier shows every applicable destination, including Solar System Edge, Shattered Planet, Nexus, Black Hole Approach, Black Hole, Oort Cloud, Sol, the extended Deep Space Edge, optional Shattered Planet/Skewer expeditions and optional Aegis/Bellicos endpoints **when installed and actually connected to the Solar System Edge network**. A location is a mandatory requirement only when its runtime prototype exists, is navigable, is not hidden or decorative, and has a real connecting path. This prevents removed mods and dangling route markers from hard-locking the finale. Conversely, deliberately not researching or visiting an installed accessible optional destination cannot bypass the requirement.

If the installed route graph is missing or invalid, Ignition fails closed with clear guidance instead of treating an empty target list as completion. A completed victory from an older save remains complete; earlier unrecorded visits cannot be invented retroactively, but an ongoing voyage can be credited from a player physically present at its actual destination. The check occurs only at a platform-state or player-location change, sparse reconciliation, or the final delivery read, not every tick.

### Prevent competing mod endings

Razi Protocol's victory guard disables the native Space Age Edge,
K2/K2SO transceiver and legacy silo victory conditions through their
documented supported remote interfaces. Each source may continue
operating, generating discoveries, powering structures and completing
its own optional challenges; no boss trophy, research, platform journey,
transceiver activation or cargo side quest should invoke the Factorio
campaign victory ahead of Convergence.

The guard is reasserted at initialization, modpack configuration change,
and during normal play. The `/razi-victory-audit` admin command shows
the opt-out state of all three sources, plus how many unsupported native
victory events were recovered. An 'unverified' entry means the source
supports suppression but does not provide a read-back method. A missing
or unsupported interface is a compatibility issue, **not proof that
victory is blocked**.

A source mod that directly invokes `game.set_game_state` and has no
opt-out cannot be prevented by a general Factorio event hook. The
safety net recovers a newly triggered unintended ending only once the
simulation proceeds. It does **not** reset a victory screen that
was already shown on an imported save, or a genuine Convergence win.
For this reason a full installed-modpack victory-trigger regression
test remains required before release.

### Mandatory Nexus trial victory gate

Convergence's **final Ignition** shipment requires **all nine** native Nexus Bosses force victories: Arachnid Queen, Watcher, Rogue Spidertron; Twin Maws, Colossus, Plague Hulk; Storm Guardian, Devourer and Last Commander. The source mod exposes a read-only `get_state().defeated[force_name][boss_id]` API, available since version 2.0.0. Razi uses that authority directly and shows a three-circle progress dossier, individual defeat status and the original boss Codex. Nexus's `nexus-silence` warp key is valuable progression but never substitutes for boss records. This is a dedicated real-world combat Project, not a technology tick.

`info.json` uses `~ nexus-bosses >= 2.4.0`, a **required dependency with no load-order constraint**, because Nexus Bosses itself lists `? razi-protocol` and a normal hard dependency would produce a circular load order. Nexus Bosses supplies its own threat, enemy and soundtrack dependencies; Razi does not copy or override its bosses. The gate fails closed if the source API is missing or malformed, and existing completed Razi victories remain completed.
