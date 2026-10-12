# Expedition Chronicle 2.1.7 QA Checklist

These steps deliberately use manual Factorio testing so normal pushes do not consume GitHub Actions minutes.

## Load and migration

1. Start a fresh Factorio 2.1 game with the required Razi Protocol mod stack. Check the top-bar Chronicle icon, open and close the window and use every tab.
2. Install 2.1.6 into an existing save with researched chapters and landed planets. Verify progress is reflected without invented historic completion splits.
3. Save, exit, load again. Confirm times, selected chapter, chosen tab, mission filter, compact-card preference and popup preference survive.
4. Check all seven tabs when Cerys, Pelagos, Nexus and Dea Dia are absent. Optional entries must hide without errors.
5. Switch forces and merge two forces. First-visit timestamps must use the earliest recorded visit and no chapter progress should be reset.

## Story and event capture

1. Complete a short technology research and verify the started/finished events update its mission.
2. Land on an unvisited planet. Confirm first-landfall completion, its time and one transient popup. Revisit it; there must be no repeated achievement.
3. Build the first working space platform hub and complete an actual platform journey. Confirm both new milestones.
4. Complete a multi-world research project. Verify the progress bar reaches 100% only when the active installed objectives are researched.
5. Build/activate the K2SO intergalactic transceiver. Confirm the existing signal technology gate still unlocks and the Deep Space finale still completes.
6. Confirm no Chronicle objective modifies research prerequisites, planet access, routes or recipe availability.

## Visual and performance

1. Check 1920x1080, 1366x768 and 125%/150% interface scaling for horizontal overflow and clipping.
2. Inspect mission card badges, planet icon fallbacks, project requirements, stats, chapter colors and timeline sorting.
3. Leave the Chronicle open through several research events. Check for rendering issues or unexpected frame overlaps.
4. In System Atlas, verify each neighbor, kilometers and unlock state against the base starmap for the same installed mod set.
5. Verify notification dismissal, automatic expiration and the Records setting for disabling them.
6. With a late-game factory, review UPS while the Chronicle is closed, then while browsing the Atlas. No rendering runs continuously every tick.

## Limitations

- Before-installation historical time cannot be reconstructed from a save.
- The route panel reflects prototype connections and destination unlocks; it does not claim that every route is currently traversable by an actual space platform.
- This release extends the Chronicle and adds a reusable theme. It does not replace external GUI mods or the native Factorio starmap controls.

## Architecture migration validation

- Verify moving Lua modules into `scripts/chronicle/` loads without any stale `require` paths.
- Confirm `storage.razi_protocol_chronicle` keeps existing force and player records on update.
- Confirm the manual-only GitHub Actions check was not enabled or triggered by this release.

## Cross-system research exchanges (2.1.8)

1. In the intended K2SO pack, verify five Research Exchange technologies unlock at their documented later-stage research milestones.
2. For each exchange, verify crafting three Tech Cards consumes the complete ingredients for two baseline batches **plus two additional science packs**. There must be no duplicated ingredient prototype entries.
3. Confirm no Research Exchange is a required prerequisite for any existing planet discovery or K2SO transceiver tech.
4. Remove optional Cerys, Dea Dia, Pelagos, Nexus packs in alternate mod configurations; the normal exchanges must stay playable and optional alternative recipes must disappear cleanly if their sciences are absent.
5. Verify source cards can be researched in a lab accepting both the current and next system's cards. Check the Promethium branch with and without Nexus.
6. Ensure quality modules and recycling do not create an infinite science card loop. The exchange recipes disallow productivity and auto recycling.
7. Confirm the five new Chronicle side quests appear after their tech prototypes exist and existing saved chapter times remain intact.

## Starmap visuals and route polish (2.1.9)

1. Verify corona layers render beneath existing Solaris, Nyxaris, Vibrant and Beetlejuice stars, including PlanetsLib sprite-only conversion.
2. Confirm route hover works over every stellar glow and that duplicate or untranslated tooltip fields do not appear.
3. Inspect regional arcs, interstellar straight corridors, asteroid belts and deep-space hazards in the native starmap.
4. Confirm Frozeta has an outer independent orbit, Vesta sits closer to Beetlejuice, and all original space routes still connect.
5. Check four additional system projects, their chronological progress, save persistence and optional Pelagos handling.
6. Validate labels in English and Russian without changing prototype research, recipe cost, or route availability.

## Star portraits and landmarks (2.1.10)

1. Check the Atlas and chapter Overview show the matching transparent corona portrait for Solaris, Nyxaris, Vibrant and Beetlejuice.
2. Verify Calidus and Deep Space use their existing campaign emblems without sprite-path errors.
3. In Deep Space, check missing Nexus or Oort Cloud prototypes safely remove the corresponding landmark cards.
4. Check portrait sizes on 1366x768 and 1920x1080 and with UI scaling at 125% / 150%.
