# Galactic Operations

Razi Protocol's independent, native Factorio 2.1 planet and space-platform dashboard, designed for campaigns with dozens of modded destinations and fleets. Inspired by the organisational needs identified by [Space Platform Organizer - Enhanced](https://mods.factorio.com/mod/SpacePlatformOrgUI-Enhanced), but independently implemented and not derived from its source code.

## Opening

- Enter **Remote View** and open the space map. A dedicated **Galactic Ops** button appears at the upper-right edge of the map, independent of the Factorio shortcut bar.
- While viewing the map, you can optionally press **Ctrl+Shift+G** (rebind under Controls).
- The map button hides automatically when returning to normal gameplay. It updates within half a second after a map view change; it does not poll the fleet or planet list.
- The original Space Age planet and platform selector stays available.
- The panel is draggable and scales to the player's display resolution.

## Worlds and destinations

- Razi's seven campaign star systems appear in their progression order, with unrecognised optional mod worlds collected under **Other & Optional Systems**.
- Search by destination internal name or star-system group, narrow to a single system, and switch between all, accessible, favourites, locked destinations, or recently viewed destinations.
- The default list shows only planets that the force has unlocked. Enable **Show locked destinations** explicitly to inspect other non-hidden worlds.
- **Include slipstreams and waypoints** allows navigating the large orbital network without cluttering the default planet list.
- **View** enters Remote View only if the game already has an existing, accessible planet surface. The UI never creates a surface or bypasses a discovery technology.

## Platform fleet

- Enumerates the player's force-owned, nonhidden, non-deleting platforms.
- Displays in-transit, in-orbit, paused, unscheduled and under-construction states; ongoing connections show their two endpoints.
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
