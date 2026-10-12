# The Razi Expedition Journal

A completely original 157-milestone, 17-chapter guided journey written
for the seven-system Factorio 2.1 K2SO campaign. Inspired by the *idea*
of an in-game journal, but not dependent on Quest Book or a fork of its
source code, UI, texts or reward engine.

## Access

- A compact book button appears in Factorio's **top GUI** during normal
  factory gameplay, on planets, and in remote view.
- **Ctrl+Shift+J** opens or closes the journal. It is rebindable.
- Choose one of 17 expandable chapters. The left column shows just the
  open chapter so 157 milestones do not crowd a small screen. Filter by
  All, Ready, Unfinished or Completed.
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
- **No periodic scans.** Journal screens refresh when opened, manually
  refreshed or when the player's force finishes a real technology.
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

Twelve substantial recovered transmission records weave an original
mystery through Calidus, Muluna, Castra, Moshine, Cerys, the asteroid
belt, Maraxsis, Tenebris, manufacturing, Dyson construction and the
final signal. They unlock after the matching **researched** native
technology, not after physically building an entity. This is
original Razi Protocol fiction, separate from the underlying mods'
canonical lore.

Side quests and transmissions do not gate travel, alter science, or
grant rewards. Original parallel star routes remain independent;
the journal reflects them rather than redefining them.
