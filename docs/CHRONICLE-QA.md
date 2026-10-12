# Expedition Chronicle 2.1.6 QA Checklist

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
