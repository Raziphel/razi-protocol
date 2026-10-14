> **Current UI (October 2026):** The Protocol Codex now has Quests, Projects, and Journal views. Open it with Ctrl+Shift+J. Projects contains Dyson Sphere, Cargo Network, Transceiver, and Convergence. Ctrl+Shift+G opens Projects directly. The separate Galactic Operations window and floating starmap button are retired. Older sections below describe the prior interface.

## October 2026: Expedition Codex visual language

The journal is now presented as an expedition field manual. The heading
and primary reading text use neutral ink; local chapter colors are reserved
for short navigation rules, statuses and selected milestones. An understated
folio tab row replaces a wall of competing buttons. The active chapter receives
the raised panel, while unopened chapters become entries in a compact index.

**Projects** use a project index with restrained existing game art and actual
stage completion. A separate dossier pane contains native Dyson construction,
cargo chains, Transceiver state and Convergence deliveries. Small screens use
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
