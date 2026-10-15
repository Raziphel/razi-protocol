## Optional native signal network (2.1.53)

AAI Signal Transmission's **native** powered transmitters and receivers
can be built in separate planetary factories and tuned to one channel.
They share wire signals such as stock and demand between worlds, making
Planet Express import/reserve settings easier to coordinate manually.
AAI owns the communication network; Planet Express owns rocket
deliveries and platform schedules. Razi shows only the native research
state and operator instructions in the Cargo Network, never fictional
signal/channel counts.

When installed and compatible, its source technology also becomes a
prerequisite for two Razi-owned premium multiworld component researches.
This is optional from the modpack's perspective and doesn't change
any first-arrival or system discovery, asteroid route or logistics
schedule. A source prototype dump and old-save playtest are required
before promoting the optional integration to a default modpack choice.

# Cargo and Research integration (Factorio 2.1)

## Two recommended NON-planet modules

1. **Planet Express >= 2.1.9** (recommended) (MIT; `planet-express`). Ships use real
   rockets and vanilla schedules. Users enrol platforms at their hubs and
   set import demands/reserves in native landing pads. Razi never writes
   Planet Express's storage or platform schedules, preventing competing
   fleet dispatchers. Its native `interplanetary-trade-logistics` technology
   is anchored to existing `space-science-pack` research only when safe.
2. **Rocket Turrets Upgraded >= 2.1.1** (recommended) (`upgraded-rocket-turrets`).
   Source owns the four rocket turret tiers and their combat statistics,
   recipes, machinery and planet production restrictions. Razi detects
   their actual source technology/recipe names from the live loaded
   `unlock-recipe` effects, and adds safe science technology
   relationships to Vulcanus (MK1), Fulgora (MK2) and Aquilo (MK3/MK4).
   No new costs, loops or recipe rebalancing.

Neither is required to load the Razi campaign. Both are recommended for richer logistics and defense, with guarded prototype hooks when installed. Multiplayer Factorio synchronizes the enabled mod set independently of a hard dependency declaration. Neither adds a new planet. There is no runtime bridge into third-party
internal tables, no duplicated autotrader, and no new on-tick scheduling.

## Galactic Operations: new views

**Research & Campaign** gives all eight chapter milestones a
read-only progress readout, researched destination technologies,
missing research prerequisites, actual installed planet and moon unlock research and whether their system-card
manufacturing recipe is unlocked. Presence of source tech does not
prove the surface has been visited or a production chain is feasible.

**Cargo Network** gives the Planet Express research state,
the actual Razi platform count, current in-transit and unscheduled
ships and onboarding steps for landing-pad demands, platform hubs,
reserves and real rockets. It also surfaces the number of installed
Razi cross-planet industrial technologies. It intentionally does
not duplicate the third party's fleet monitor or manipulate schedules.

Both views open from the existing map-attached Galactic Operations
button, never the shortcut bar, and refresh only on demand.

## More legible native technology tree

All Razi system discoveries, the two surveyed debris-belt technologies
and the complete singularity / transceiver endgame chain are marked
`essential=true`, with stable order for the existing Razi chapter nodes.
The Factorio 2.1 research screen's native **Show only essential
technologies** filter can now highlight the whole expedition backbone.
This does not hide ordinary source technologies or remove any content,
and does not change research costs, science requirements or effects.

## Tech tree audit

Run `python scripts/audit_tech_tree.py --dump-data-raw <file.json>`.
It reports nonhidden technology prerequisite cycles, missing
prerequisite identifiers, technologies whose complete science pack
list is unsupported by any lab, and discoverable planets with no
normal technology unlock. Use `--json` for structured diagnostics.

This audit is advisory; modded planets may have scripted progression
or nonstandard triggers, so unknown discoveries must be investigated
before adding gates. It does NOT auto-delete recipes or sources.

## Final acceptance checklist

- Resolve all runtime mod dependencies with Factorio 2.1.
- Run full --dump-data-raw and the tech, recipe/supply and distance audits.
- Play a fresh save and check both map-tab views with Planet Express
  before and after research.
- Enrol two ships, ship nonperishables and a perishable, manually
  edit a schedule and verify Planet Express backs off properly.
- Research each rocket turret tier and verify category/surface
  restrictions and source damage are unchanged.
- Verify a saved world upgrades without altered space-platform routes.

Full game-engine testing remains outstanding until a Factorio
client/server with the entire required pack is available.
