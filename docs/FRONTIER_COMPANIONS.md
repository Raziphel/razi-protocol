# Orbital, railway and defense companion integration

**Scope:** Razi Protocol 3.0 development branch. The six extra logistics,
rail and defense companions remain recommended and optional, but Orbital
Catapult >= 0.15.0 is now a required mod. The manifest uses the upstream
author's load-order-independent `~ orbital-cannon` dependency. Both
Razi-owned link groups are independently configurable.

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

## Orbital Catapult: real regional links, source-owned movement

Orbital Catapult is required via `~ orbital-cannon >= 0.15.0`. The
`razi-orbital-catapult-local-links` and
`razi-orbital-catapult-regional-links` startup options each default to ON.
Each group exports six directed native `orbital-cannon-link` prototypes
(three reversible corridors), but only for planets actually installed:

- Vespera: Muria <-> Aquilo, Muria <-> Rubia, Rubia <-> Aquilo
- Regional: Vulcanus <-> Castra, Gleba <-> Moshine, Rubia <-> Maraxsis

These are local transport possibilities, not free freight. The source mod
still owns power requirements, actual launchers, deliveries, arrival checks,
items and player transport. Neither group connects across star systems or
replaces space-platform routes. Test the native source's research/surface
restrictions before declaring a connection usable.

The Cargo Network includes an optional, per-player manual Freight Desk.
It can check the player's physically carried departure-world inventory
against prioritized orders and explain shortfalls without double-counting
the same items. It does **not** reserve stock, read catapult machinery,
observe a shipment, or verify delivery. Saved inaccessible orders can
be removed without exposing spoiler-hidden route names.

Recommended companion dependencies remain optional. Source-mod ownership and
safe compatibility skips remain mandatory.

## Test profiles and release gates

1. **Baseline:** Remove all six optional companions, retain the now-required
   Orbital Catapult, and disable both Razi link groups. Verify Razi loads,
   keeps native rocket/platform research and reports zero Razi corridors
   without claiming absent companions are installed.
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
5. **Catapult link profiles:** Test local-only, regional-only, both-ON
   and both-OFF startup settings on copied saves. Verify up to twelve
   directed native links (six reversible pairs), only between actually
   installed and unlocked destinations. Check real endpoint machines,
   reciprocal travel, inventory/player arrival, underwater Maraxsis
   restrictions and no cross-star or asteroid-belt bypass. Confirm an
   unavailable Freight Desk route never leaks its name and that order
   stock checks don't pretend a delivery occurred.
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
