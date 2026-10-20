# Orbital Salvage integration

Razi Protocol 3.0 integrates [Razi Rocket Reusability](https://mods.factorio.com/mod/razi-rocket-reusability) without duplicating its asteroid spawns, beacons or research. The dependency is mandatory for the curated campaign, and all salvage operations continue to be driven by the original mod.

## Challenge presets

The rocket mod's companion 1.1.6 source update reads the startup `razi-difficulty-preset` itself:
- **Easy, Normal:** Side wrecks follow the ordinary runtime-global toggle (off by default).
- **Hard, Nightmare:** Side wrecks are active regardless of that toggle. The runtime side-arrival **chance** is still adjustable (35% default).
- **Custom:** The runtime-global toggle has full control.
- **Standalone:** The rocket mod works with its own ordinary settings.

No cross-mod settings writes are used (Factorio forbids those). A side approach replaces a front approach for an existing eligible recovery roll; it does not spawn additional wrecks. The wreck cap, priority of powered beacons, 18x18 safety clearance and front-fallback all remain source-owned.

**Release order:** Razi Protocol accepts rocket mod 1.1.5+, but **automatic preset activation requires 1.1.6+ to be published and installed**. The public mod portal build does not change when GitHub alone is updated.

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

- Start Easy, Normal, Hard, Nightmare and Custom saves with rocket mod **1.1.6+**; verify flank arrivals occur only when enabled and at the configured chance.
- Change the side-arrival chance live; verify a zero chance yields front-only wrecks even on Hard/Nightmare.
- Test long, broad and asymmetrical platforms. Side lanes should retry/fall back safely without additional wrecks.
- Verify actual K2SO and Muluna `rocket-chunk-processing` outputs and the three bulk recipes with their loaded mod settings.
- Confirm all five milestones render and complete in the Journal, including old saves already possessing researched source technologies.

Offline static checks cannot replace testing with the full Factorio 2.1 mod pack.
