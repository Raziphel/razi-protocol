# The Protocol Codex (Razi Expedition Journal)

A completely original 204-milestone, 18-chapter guided journey written
for the seven-system Factorio 2.1 K2SO campaign. Inspired by the *idea*
of an in-game journal, but not dependent on Quest Book or a fork of its
source code, UI, texts or reward engine.

## Industrial Constellations (new chapter)

Eighteen optional industry missions now interpret existing guarded recipe
technologies as source-backed research milestones. They span K2SO, Moshine,
Paracelsin, Rubia, Linox, Tenebris, Vesta, Panglia's neighbouring trade
network, Balack, Aquilo, and other specialist sources. Each mission records a
real existing technology; absent alternatives (including Deep-only recipes in
Balanced mode) do not appear or impede main progression.

For these missions, the Codex examines **only the selected native recipe**,
illustrating its actual input and output prototypes and identifying a suggested
workshop world. Recipe limits, machine categories, environmental restrictions,
and source-mod outputs remain authoritative. Research is *not* proof the player
has shipped, built, or manufactured a quantity.

## Chapter art direction (2.1.18)

All **18 chapters** now have a unique, contrast-minded primary color, a softer
text accent, a source-artwork sigil, and a localized atmospheric subtitle.
These are declared in `scripts/razi_journal_themes.lua` and do not touch
gameplay, recipe prototypes, or saved progress. Icons are selected from real
installed technology, item, or space-location sprites with a safe Razi Codex
fallback when source assets are missing.

Chapter colors and motifs are present in the index headings, the currently
expanded chapter, chapter completion meters, selected objective text, reader
banners, objective and lore section rules, science/recipe galleries, the
recovered-transmission reader, and the pinned tracker. The interface uses
native Factorio progress bars for narrow colored rules instead of a custom
draw loop or per-tick graphics work.

The index progress numbers and bars occupy separate rows to avoid
horizontal overflow on narrow screens. Gallery artwork has a subtle native
framed tile, and the selected quest remains visually distinct from status.

**Scope:** cosmetic runtime UI only. All 204 stable quest IDs, 18 chapter IDs,
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
