# Orbital Salvage integration

Razi Protocol 3.0 integrates [Razi Rocket Reusability](https://mods.factorio.com/mod/razi-rocket-reusability) without duplicating its asteroid spawns, beacons or research. The dependency is mandatory for the curated campaign, and all salvage operations continue to be driven by the original mod.

## Challenge presets and actual Mod Settings

The 1.1.7+ Rocket Reusability source mod contains a Lua bridge that reads `razi-difficulty-preset` and updates **its own** `razi-rocket-reusability-side-arrivals` Map setting once per second when necessary:
- **Easy, Normal:** Restore the player's original preference after leaving Hard/Nightmare; otherwise leave the setting untouched.
- **Hard, Nightmare:** Set the real Side-arriving wrecks checkbox On, even if a player manually unchecked it. The independent arrival chance remains adjustable.
- **Custom or standalone:** Restore the earlier manual preference when leaving a forced difficulty.

These are real Map setting changes, performed only by the mod that OWNS the setting. Factorio does not allow Razi Protocol to write settings belonging to other mods. It does not alter source startup settings, recovery chance, active wreck cap, beacon priorities, or safe front-fallback.

**Versions:** Razi Protocol accepts Rocket Reusability 1.1.5+. Version 1.1.6 provides the effective gameplay fallback but cannot update the checkbox. The **1.1.7** source update implements real in-game setting synchronization; it must be published to and installed from the mod portal separately. The one-second runtime check occurs after entering a map, not in the main-menu settings screen.

## Expedition Journal

The **Orbital Salvage** chapter is placed immediately after Expedition Fleet, with three acts:
1. First Recovery: research native Rocket Chunk Processing and the Remnant Beacon.
2. Sorting the Wreckage: optional Fulgora and Aquilo industrial upgrades.
3. Fleet-Wide Reclamation: optional network-scale processing using RAZI's real precision matrix.

Quests refer to genuine native or RAZI research IDs. Existing researched saves complete retroactively; no artificial rocket-launch counter or simulated beacon objective is implied. Side-arrival risks and beacon mechanics are explained by the in-game mission hints.

## Optional industry (data-final-fixes)

| Research | Unlock prerequisite | Bulk crushing recipe | Balance |
| --- | --- | --- | --- |
| Precision Rocket Reclamation | Remnant Beacon, Fulgora | 3 rocket chunks + 1 holmium plate | Native outputs x3, +1 first product, 15% faster |
| Cryogenic Rocket Reclamation | Precision, Aquilo | 4 rocket chunks + 15 ice + 2 processing units | Native outputs x4, +1 first product, 25% faster |
| Network Rocket Reclamation | Cryogenic, real RAZI precision-matrix research and trade | 6 rocket chunks + 1 RAZI precision matrix | Native outputs x6, +2 first product, 30% faster |

If research, ingredients, source recipes or dependencies are absent, that tier is skipped. All recipes retain the source crushing category and output schema, including original chunk-return odds, source K2SO cost adaptation, Muluna compatibility and incomplete rocket parts. Productivity is disabled on these recipes to avoid stacking productivity with the fixed handling bonus.

No planetary discovery, science gate, source recipe, Remnant Beacon or rocket silo is altered.

## In-game verification checklist

- Start Easy, Normal, Hard, Nightmare and Custom saves with rocket mod **1.1.7+**; after at least one second verify the actual side-arrivals Map checkbox and restoration of the previous manual value.
- Change the side-arrival chance live; verify a zero chance yields front-only wrecks even on Hard/Nightmare.
- Test long, broad and asymmetrical platforms. Side lanes should retry/fall back safely without additional wrecks.
- Verify actual K2SO and Muluna `rocket-chunk-processing` outputs and the three bulk recipes with their loaded mod settings.
- Confirm all five milestones render and complete in the Journal, including old saves already possessing researched source technologies.

Offline static checks cannot replace testing with the full Factorio 2.1 mod pack.
