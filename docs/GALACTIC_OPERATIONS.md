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
