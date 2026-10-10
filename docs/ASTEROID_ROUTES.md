# Seven-System Asteroid Routes

**Status:** Implemented on private `main`, pending real Factorio 2.1 load and space-platform playtesting.

Razi-owned connections now follow a graduated route-hazard table instead of
applying one asteroid preset to entire chapters. The aim is meaningful choices
in ship design while keeping local travel useful and supporting other mods'
asteroid resources.

| Route group | Example | Base profile | Relative vanilla density |
| --- | --- | --- | --- |
| Home launch | Nauvis -> Calidus hub | Starter | 0.82x |
| First interstellar jumps | Calidus -> Solaris or Nyxaris | First Crossing | 0.99x |
| First-frontier system crosslink | Solaris <-> Nyxaris | Frontier Crosslink | 1.05x |
| Solaris industry | Vulcanus, Castra, Arig, Hyarion | Industrial / Deep | 0.96–1.08x, metallic bias |
| Nyxaris biology | Gleba, Moshine, Apia, Panglia | Biological / Deep | 0.97–1.10x, carbonic bias |
| Next-tier interstellar jumps | Solaris -> Vibrant; Nyxaris -> Vespera | Middle Crossing | 1.08x |
| Vibrant science | Fulgora, Ribbonia, Paracelsin, Shchierbin | Electrical / Chemistry | 1.08–1.21x |
| Vespera survival | Muria, Aquilo, Rubia, Maraxsis | Cryogenic / Deep | 1.15–1.25x |
| Second-frontier crosslink | Vibrant <-> Vespera | Middle Crosslink | 1.13x |
| Outer-system crossings | Vibrant -> Beetlejuice; Vespera -> Umbra | Outer Crossing | 1.30x |
| Beetlejuice industry | Cubium, Linox, Secretas, Frozeta | Outer Industry / Deep | 1.30–1.39x, metallic bias |
| Umbra science | Tenebris, Crucible Orbit, Vesta | Outer Void / Deep | 1.34–1.42x, carbonic bias |
| Outer crosslink | Beetlejuice <-> Umbra; Vesta <-> Secretas | Outer Crosslink | 1.33x |
| Final approaches | Secretas/Vesta -> Solar-System Edge | Deep Edge | 1.40x |

*Multipliers are applied only to existing **vanilla** asteroid spawn-point
probabilities, not to speed, ore yield, asteroid size or all asteroid types at
once. A 1.4x multiplier does not mean exactly 40% more real-world danger:
the underlying vanilla preset and planet-specific modifiers also matter.*

## Compatibility rules

- Do not replace or remove any modded asteroid species or its spawn points.
  Exact vanilla asteroid names are whitelisted. A modded name containing
  `metallic`, `oxide`, `carbonic` or `promethium` is still custom.
- On Razi-managed routes with existing definitions, retain all custom entries
  and apply restrained changes only to vanilla ones. Do not change modded
  asteroid speed or spawn-probability curves.
- When two mods supply the same connection, prefer the original non-Razi
  route name. Merge any missing custom asteroid definitions before dropping
  duplicate routes.
- Fresh Razi routes use copies of Factorio's own asteroid-spawn presets.
  Fallbacks allow mod forks that do not expose every optional preset.
- Do not rebalance the source-owned internal routes for Dea Dia, Apia,
  Crucible, Aegis/Bellicos, optional planet mechanics or moon-only routes.
  Those may use custom asteroid species essential to their resource chains.
- No route hazards are added to planetary orbit asteroid tables, and none of
  the required/optional planet mods gains new dependencies.

## Verification

GitHub Lua fixtures cover scaling order, preservation of native Imersite and
other modded entries, route consolidation and repeated application.

Full modpack testing still needs:

1. Inspect a `--dump-data-raw` export for every connection's final asteroid
   species and curves, especially Imersite, Carna and optional planet chunks.
2. Fly Nauvis -> Solaris and Nauvis -> Nyxaris with starter ships, then test
   the two middle and outer parallel paths using appropriately upgraded ships.
3. Ensure crucial asteroid resource chunks remain attainable on all
   destinations that depend on them.
4. Verify no duplicate route or unintended shortcut exists after integrating
   all optional planets.
5. Compare speed, ammunition consumption, shield attrition and throughput
   before declaring the danger curve fully balanced.

The new profile implementation is in
[`prototypes/system/asteroid_profiles.lua`](../prototypes/system/asteroid_profiles.lua);
the route ownership table is in
[`prototypes/system/route_reconcile.lua`](../prototypes/system/route_reconcile.lua).
