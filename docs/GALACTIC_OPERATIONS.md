> **Historical guide (October 2026):** Galactic Operations is now integrated into the Expedition Journal's Projects tab. Its old floating starmap button and standalone window have been removed. Ctrl+Shift+G opens Journal Projects. Source-backed construction, logistics, and Convergence state remain intact, while native Remote View handles fleet/world navigation. The sections below document the prior implementation.

# Galactic Operations

Razi Protocol's independent, native Factorio 2.1 planet and space-platform dashboard, designed for campaigns with dozens of modded destinations and fleets. Inspired by the organisational needs identified by [Space Platform Organizer - Enhanced](https://mods.factorio.com/mod/SpacePlatformOrgUI-Enhanced), but independently implemented and not derived from its source code.

## Opening

- Enter **Remote View** and open the space map. A dedicated **Galactic Ops** button appears at the upper-right edge of the map, independent of the Factorio shortcut bar.
- While viewing the map, you can optionally press **Ctrl+Shift+G** (rebind under Controls).
- The map button hides automatically when returning to normal gameplay. It updates within half a second after a map view change; it does not poll the fleet or planet list.
- The original Space Age planet and platform selector stays available.
- The panel is draggable and scales to the player's display resolution.
- At narrow UI resolutions, the five main tabs use compact captions and
  two rows, while search and system filters stack instead of overflowing.
- The destination and platform directories use vertically arranged cards,
  each with a verified native planet/space-location icon when available,
  a visible star-system label, current status and accessible actions.
- A four-cell summary highlights the available records, filtered matches,
  ships in transit and fleet warnings.
- Planet-name search accepts translated, player-visible names after the
  game's native asynchronous translation completes. Internal IDs and
  star-system names remain searchable. Translations are cached per player
  and locale, and batched into a single refresh on the existing 30-tick
  map-button check. No additional on-tick polling is added.

## Worlds and destinations

- Razi's seven campaign star systems appear in their progression order, with unrecognised optional mod worlds collected under **Other & Optional Systems**.
- Search by the visible translated name, destination internal ID or star
  system. The **Clear** button resets search without clearing favourites.
  Narrow to one system and switch between all, accessible, favourites,
  locked destinations or recently viewed destinations.
- The default list shows only planets that the force has unlocked. Enable **Show locked destinations** explicitly to inspect other non-hidden worlds.
- **Include slipstreams and waypoints** allows navigating the large orbital network without cluttering the default planet list.
- **View** enters Remote View only if the game already has an existing, accessible planet surface. The UI never creates a surface or bypasses a discovery technology.

## Platform fleet

- Enumerates the player's force-owned, nonhidden, non-deleting platforms.
- Displays in-transit, in-orbit, paused, unscheduled and under-construction
  states; ongoing connections show their two endpoints. Up to two concrete
  warning explanations appear on each affected platform card, with a count
  for any additional signals.
- Filters for travelling craft, attention-needed craft, favourites and recently opened craft. Bookmarks are private per player.
- Fleet mission roles classify ships automatically from their names, with editable per-player overrides (cargo, science, defense, exploration, construction, general). Filter the fleet by mission without renaming the ship, editing its schedule, or changing another player's annotations.
- **View** changes only the Remote View camera to an existing platform surface, never moves the character, starts a schedule, or renames a platform.
- Both tabs are paginated at 22 entries per page, with no full-game tick scans. Refresh on demand.

## Compatibility and limitations

- This is a separate supported GUI, not an engine GUI injection. Nothing in the vanilla surface panel is patched, replaced or hidden. The button is a companion screen overlay rather than a new control inside Factorio's native starmap header.
- Factorio exposes map render mode and Remote View controller state, but not a distinct starmap-open event. Consequently the button may also appear in other Remote View chart views, not solely when zoomed out to the galaxy.
- The panel and filters do not edit routes, planets, schedules or other mods' GUI.
- The initial version presents dynamic names as Factorio GUI localised captions; search primarily matches internal IDs and star-system grouping. Unknown optional systems are categorised conservatively.
- A planet surface must already exist for its **View** button to work, by design.
- Rename, bulk reassignment, custom nested folders, and platform build-time ETA are intentionally not implemented in this first version.

## Galactic Atlas (Operations 2.0)

- Open **Atlas** next to any listed world to inspect its native description
  (once discovered), measured surface properties, direct unlock technologies,
  incomplete prerequisites, and actual science ingredients from the active
  force technology graph.
- A locked location can be inspected only when **Show locked destinations**
  is explicitly enabled. Its native environment/description stays hidden
  until discovery. Unregistered/source-scripted unlocks are labelled unknown.
- **Use as route origin** builds a shortest-listed-distance corridor from one
  already unlocked visible location to another. The Atlas does not unlock
  destinations, override transit permissions, teleport platforms or
  estimate flight time. Native route research and engine pathing take priority.
- A compact adjacency list describes actual prototype distances and counts
  registered asteroid spawn definitions. These counts are not an invented
  hazard rating or a safety guarantee.
- Atlas data is obtained on GUI inspection/redraw, never scanned each tick.

## Fleet Operations 2.0

- **Inspect** on a platform reveals its actual space connection, position
  percentage (not travel ETA), speed/weight engine values, trip count, stop
  count, damaged foundation tiles and current hub cargo summary.
- Fleet warnings detect a missing hub, a paused platform, missing schedule,
  damaged tiles and waiting on a planetary delivery. These are advisory
  signals, not assertions about fuel, ammunition or ability to survive travel.
- **Attention first** sorts warning-bearing platforms to the top, and the
  existing Needs Attention filter recognises the additional warning types.
- Store a short personal note on each ship. Notes, bookmarks, role overrides,
  origin picks and sorts are kept as small primitive values per player in
  the Factorio save. They cannot alter ship schedules, inventories or routes.
- Cargo scans happen only when a ship is actively inspected, not while the
  map overlay button is synchronised. Fleet state otherwise updates only
  when the panel redraws or the player clicks Refresh.

### Verification required

The Lua fixtures and static checks test the new graph and interface
structure. Factorio 2.1 and the actual full modpack are still needed to
exercise localization, native GUI scaling, route permissions and mixed
planet-mod research effects. The dashboard is informational by design.

Additional Atlas route annotations display the largest size word detected in declared asteroid prototype names. These are not numerical danger ratings, and unknown modded asteroid naming is explicitly unclassified. The chosen planet's Razi industrial research is listed only when the real tech graph contains a direct discovery prerequisite. The inspector is vertically scrollable on compact screens.

## Directory visual polish (2.1.26)

The previous rigid horizontal rows required four or five fixed-width labels
and buttons, which became difficult to read at higher GUI scales. They now
use stacked information cards that wrap native translated planet names,
prioritise actions, retain actual fleet diagnostics and display a native
sprite only if Factorio verifies its path.

All previous player favourites, platform roles, notes, filters, recent
destinations, search preferences, inspection focus and page selection are
preserved. The original map-only button and keyboard shortcut are unchanged.
Pages contain 16 records so a large space-platform fleet doesn't rebuild
more than necessary when the player types.

This is a user interface pass, not a rewrite of Factorio's space platform
scheduler. No ships are moved, no surfaces are created, and no planet
technology or recipes are changed. Runtime inspection with a complete
modpack is still required for display scale, translated world names and
rare third-party planet icons.

## Cargo Network command centre (2.1.27)

The **Cargo Network** tab now tracks the four component families already
registered by the industrial compatibility modules:

1. Precision Control Matrix: Vulcanus, Moshine, Fulgora and Paracelsin.
   Existing downstream industries: Aquilo, Rubia and Linox.
2. Panglia Optic Bond: Panglia, Moshine and Fulgora. Export markets:
   Paracelsin coils and Linox rare-earth refining.
3. Extreme-Environment Lattice: Rubia, Tenebris, Linox and Gleba.
   Downstream research: Vesta and Balack where installed.
4. Umbra Pressure Frame (Deep interdependence): Panglia, Crucible, Linox
   and Vesta. Downstream research: Vesta foundations and Aquilo controllers.

Cards are **only shown when their native Razi component technology really
exists and is visible** in the player's force. Consumer research is also
looked up by its actual technology identifier; unavailable mod branches
do not show fictional products or readiness states. Components have icons
validated using the engine's sprite registry. Expanding one card reveals
the existing recipe's ingredient prototypes and output count, source
world names and real missing technology prerequisites.

A dashboard summary reports available component lines, researched lines,
loaded downstream upgrades and actually travelling space platforms.
Research is clearly distinguished from live factory output: this is a
read-only operational guide, not an invented production telemetry or a
replacement for Planet Express's scheduling and landing-pad interfaces.

Cards reflow into one column at higher UI scales or narrow resolutions,
two columns on larger displays, inside a bounded vertical scroll area.
The dispatch help stays alongside the industry cards rather than in a
second disconnected menu. The selected detail card is a per-player
preference, and all original tabs, planetary favourites, fleet roles and
notes remain intact.

This path uses a small **fixed ten-technology direct-lookup registry**,
rather than scanning every installed research technology on each render.
It adds no new tick processing, inventory scans or platform mutations.

## Cargo Network and Protocol Codex navigation (2.1.28)

The **Cargo** dashboard and **Protocol Codex** now share a small, stable
registry of actual source technology and quest IDs. There are 11 linked
Codex milestones in the four component families; other optional upgrades
are displayed without pretending that a separate quest exists.

- From a linked **industrial Codex milestone**, choose **Inspect in Cargo
  Network**. The related cargo family opens with its recipe/source details
  expanded and the exact selected component or upgrade highlighted.
- From a **Cargo component or linked upgrade**, choose **Open Protocol
  Codex** or **Codex milestone**. The real quest opens in the correct
  chapter, with the search and view filters reset so the objective is
  visible. It does not award research, complete a quest or alter saves.
- Links disappear if the component's actual technology is not installed,
  is hidden, or the current source pack has no matching Codex objective.
  An unavailable industry cannot be reached by forging GUI event values.
- Cargo may be opened **directly from the Codex** during normal gameplay
  without switching the player to Remote View. This does not expose the
  original Galactic Operations map button outside Remote View. Closing
  the window resets its temporary direct-open flag. Display-scale changes
  preserve an already open direct Cargo view; other map views still follow
  the existing map-only lifecycle.
- Research prerequisites are displayed for both the source component
  and a selected downstream factory technology. Research completion is
  not a measurement of actual factory construction or shipping.

Navigation adds no new per-tick polling, prototype mutation, research
events, surface creation or space platform changes. The source research,
current fleet ownership and all established quest completion history
remain authoritative.

## Science requirements in Cargo Network (2.1.31)

Expanded industrial component cards now show the research-unit count
and itemised science requirements of the *installed Factorio technology*.
When a player deep-links from the Protocol Codex to a particular
downstream factory research, its science requirements appear alongside
the actual research prerequisites. This display relies on native
`LuaTechnology.research_unit_ingredients` and
`LuaTechnology.research_unit_count`, not a hard-coded source-mod
science list. The interface does not claim actual production or
cargo delivery. Corrected a duplicate locale key for the
industrial chain heading.
