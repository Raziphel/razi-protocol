# Orbital, railway and defense companion integration

**Scope:** Razi Protocol Dev, 15 October 2026. All new companions are optional in gameplay.
The manifest marks six as recommended; Orbital Catapult must be installed by
the player because its author specifically prohibits regular ordering dependencies.

## Recommended companions and ownership

| Mod | Version floor | Actual integration | Original owner keeps |
| --- | --- | --- | --- |
| Various Cargo Bays | 1.1.0 | Listed in Cargo Network field notes when installed | Pod hatches, storage bay placement, recipes and unlocks |
| Space Age Railway Expansion | 0.0.18 | Guarded research hooks for nuclear and fusion locomotive technology | Train entities, fuel, Mk tiers, graphic setting, train roboports |
| Shield Generators | 0.7.0 | Add Fulgora electromagnetic science to the source superconducting-shield technology when possible | Turret shields, generators, battery buffers and performance logic |
| Circuit Launchable Rockets | 1.4.6 | Installed status in Cargo Network; no new rockets or transport shortcuts | Circuit destination signals and actual rocket launching |
| Cargo Bay Limit Research | 1.1.2 | Installed status in Cargo Network; keep source's own tiered research | Placement limits, configured base capacity and refunds |
| Platform Logistics Overhaul | 2.1.2 | Installed status in Cargo Network; no duplicated pod handling | Real cargo-pod transfers, orbit priorities and import presets |

Source dependencies such as `migratus-orchestrus` are transitively managed by
their original mod. Razi does not add a second copy.

## Optional technology weave

Switch: **Research advanced companion industries across planets**, default **on**.
The pass only runs when the relevant companion is installed, and iterates
existing technologies with a locomotive/fusion/nuclear or superconducting-shield
source specialization. It only appends source-compatible research prerequisites
and science packs after checking the real producer, original technology unit,
technology graph and an existing lab's accepted inputs. If any check fails, the
single target remains untouched and a skip reason is written as
`[Razi Protocol/companion-industry]` to the Factorio log.

- Nuclear locomotive research: Solaris tech card and existing nuclear power.
- Fusion locomotive research: Aquilo discovery and Vespera tech card;
  Mk3+ can require Beetlejuice's industrial card when available.
- Superconducting shields: Fulgora discovery and electromagnetic science.
- Other mods keep their native research and source balancing by design.

If `razi-companion-science-weave` is off, no change is made to the source
technology graph. The feature does not create new labs, recipes, planet
discovery chains or unresearchable science packs.

## Orbital Catapult is deliberately separate

The source author instructs modders to depend on it using **only**
`~ orbital-cannon` (load-order independent). This is not compatible with
Razi's policy that all companion installs remain non-mandatory. Therefore it
is **not a direct dependency declaration**. Its manually installed module
is detected and the custom extension interface is used only when the
**Experimental Muria–Aquilo orbital catapults** startup setting is enabled.

There are precisely two one-way links, Muria -> Aquilo and Aquilo -> Muria.
They do not cross the Vespera asteroid belt, do not cross star systems, and
do not connect the critical Aquilo -> belt -> Rubia lane. They are **off by
default** and not release-certified. Test the source's link availability,
research, UI, map final-fixes order, power supply and old-save behavior before
enabling this in a campaign. Never use this as a bypass for required gateways.

## Test profiles and release gates

1. **Baseline:** Remove all six optional companions and manually installed
   Orbital Catapult. Verify Razi starts without missing prototype errors,
   the same native rocket/space-platform research exists, and the Cargo
   Network doesn't claim uninstalled systems exist.
2. **Research profile:** Add just Space Age Railway Expansion and Shield
   Generators. Inspect `factorio-current.log` for successful or individually
   skipped `companion-industry` rules. Verify source recipes remain enabled,
   science cards actually have producers, and at least one real lab accepts
   the final science ingredient combination. Research and craft one train
   and one superconducting shield on a **new** save.
3. **Logistics profile:** Enable the other four recommended mods. Test
   rocket signal destination routing, storage/pod bay behavior, same-orbit
   two-way real pod transfers, and cargo limit placement/refunds with
   Planet Express enabled. Verify Razi's native belt crossings and platform
   schedules remain unchanged.
4. **All six:** Start the full K2SO campaign with all recommended companions
   and capture gameplay logs for prototype collisions, technology cycles,
   unreachable science and UPS. Space Age Railway Expansion's HD artwork
   may consume substantial VRAM; use its standard graphics initially.
   Shield Generators has Lua-driven combat overhead: measure large battles.
5. **Catapult experiment only:** Back up save data first. Manually enable
   Orbital Catapult, its own dependency `powered-machine`, and Razi's
   catapult-link startup setting in a disposable save. Check reciprocal
   Muria/Aquilo routes and confirm *no* shortcuts into Rubia or outside
   Vespera. Disable if graphics or source unlock checks are inconsistent.
6. **Existing saves:** Backup before installing or removing any content mod.
   Load an old completed-Dyson / partial-Convergence save to confirm
   research progress, inventory and cargo deliveries remain intact.

Focused offline regression commands (run manually, no automatic CI):

```bash
python3 -m unittest discover -s tests -p 'test_dependency_policy.py'
python3 -m unittest discover -s tests -p 'test_frontier_companions.py'
lua5.2 tests/lua/test_frontier_companions.lua
python3 scripts/audit_mod_dependencies.py --json /tmp/razi-deps.json --check
```

The tests assert schema, optionality, guards and mocked Lua prototype changes.
They **cannot certify full installed modpack gameplay**. Only release after
actual Factorio startup and saved-game smoke checks.
