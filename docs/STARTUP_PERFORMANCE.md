# Faster startup for Razi Protocol and large Factorio 2.1 modpacks

This is a **client-side performance guide** for players, not a new gameplay
setting. Razi cannot toggle the host Factorio installation's graphics or
prototype caches from `settings.lua`, `control.lua`, or the mod's data stage.

## First: enable Factorio's two built-in disk caches

1. Open Factorio's main menu.
2. Hold **Ctrl + Alt** while clicking **Settings**.
3. Open **The rest** and search for `cache`.
4. Enable `cache-prototype-data` under **Other**.
5. Enable `cache-sprite-atlas` under **Graphics**.
6. Apply, start the game once to build the caches, exit, then restart with
   **the same modpack and startup settings** to assess the benefit.

The official Factorio wiki confirms both options and warns they are advanced
settings. The cache will use more disk space, and its **first** rebuild can
take longer than normal. Game updates, mod updates, changed mod lists, startup
options or changed assets can invalidate a cache, requiring another full load.

- Prototype cache: reduces repeated **Building prototypes** work.
- Sprite cache: reduces repeated **Loading sprites** processing.
- Neither removes the initial mod download, first full load, save load,
  multiplayer connection, or local need for installed mod files.

Sources:
- https://wiki.factorio.com/Settings
- https://factorio.com/blog/post/fff-326

### Optional config file alternative

If the hidden menu is unavailable, close Factorio and edit its local
`config/config.ini`. On the usual Windows installation this lives under
`%APPDATA%\\Factorio\\config\\config.ini`. For Linux, macOS and portable
installs use the [Factorio application directories guide](https://wiki.factorio.com/User_data_directory).
**Back up config.ini before editing it.**

Within their existing sections (do not create duplicate sections or duplicate
keys), set:

```ini
[other]
cache-prototype-data=true

[graphics]
cache-sprite-atlas=true
```

These section snippets are examples, not replacements for the rest of the file.
The built-in UI is preferred because it knows where the installed version
stores its settings.

## Diagnose which stage is slow before cutting content

Find `factorio-current.log` in Factorio's user-data directory; the previous
run is saved as `factorio-previous.log`. Timestamps at the beginning of
lines can help determine where startup time was spent. Compare one start with
caches disabled, the first start after enabling them, and a repeat start
**without changing any mods**.

| Slow phase | Best first action |
| --- | --- |
| Loading mod settings, data stages, Building prototypes | Prototype cache; keep a stable mod set; collect log timings for deeper analysis |
| Loading sprites / atlas processing | Sprite cache; ensure adequate disk space and GPU memory; review graphics settings |
| Downloading/synchronising mods to join multiplayer | Use the server's exact mod versions and startup settings before joining; caches do not skip network downloads |
| Loading the saved map after reaching the menu | Treat separately from mod startup; profile save size/map load, not prototype caching |

Log locations and format: https://wiki.factorio.com/Log_File

If the first two cached startups are still very slow, attach the full
`factorio-current.log` and note the Factorio version, operating system,
CPU, RAM, graphics card and number of enabled mods. A single screenshot of
the loading bar is not enough to isolate the bottleneck.

## Razi-specific findings and recommendations

- Razi's `info.json` has a large **required** planet ecosystem. Disabling a
  required mod is not a safe speed tweak and will break campaign compatibility.
  Optional or hidden-optional integrations do **not** force installation merely
  because they are listed in `info.json`.
- For a server/community pack, maintain a tested **stable release set** rather
  than distributing every experimental update. Caches are most useful across
  repeated launches with no changes. Do not claim players have the latest
  prototypes if their cache was built against different files.
- The custom starmap includes around **8 MB of source PNGs** in the
  `graphics/starmap/razi` directory. This is small compared with the many
  third-party planet mods but adds graphic assets while enabled.
  Players who need a lightweight visual preset can change
  `razi-starmap-background-style` to **Off** and optionally disable
  fine details or route highlights. This requires a restart and trades
  appearance for fewer referenced visual layers. Do **not** promise a
  measurable speedup without timing the full installed pack.
- Razi's data-stage compatibility and progression passes inspect prototypes,
  but there are no measured per-module load timings yet. Replacing them
  with a homemade cross-restart cache is **not** recommended: other mods'
  final prototype edits and the campaign's deterministic progression must
  remain accurate.
- Do not indiscriminately recommend `disable-prototype-history` or obscure
  debug/performance switches. They can remove useful diagnostics or alter
  behaviour and need game-version-specific validation.
- Mods cannot secretly precompile or redistribute another mod's enabled
  prototype cache to clients. Use Factorio's built-in cache instead.

## Honest verification status

No full Factorio 2.1 game binary, full modpack, or representative player
startup logs were available for this repo audit. The caching mechanisms
are confirmed by Factorio's own documentation. **Any claimed seconds saved
for Razi Protocol itself must come from before/after timings on the exact
tested system.** Do not confuse a cold first launch with a cached repeat launch.


## Enabled-by-default code optimizations

Razi applies these automatically in its data-final-fixes stage, regardless
of any optional visual preferences:

- Index technology recipe unlocks once per compatibility pass rather than
  scanning all technologies for every cross-planet imported ingredient.
- Index only the science-pack producers actually referenced by the campaign
  weave. Re-evaluate live technology dependencies when testing each gate,
  so earlier-world science cannot accidentally become future-world research.
- Index surviving space connections by endpoint pair after the campaign
  bypass cleanup. Preserve native route names, asteroid details, original
  length balancing and the belt barriers while reconciling duplicates.

These caches are **in-memory and data-stage-only**. They do not add persisted
save data, bypass unlock requirements or let a mod configure Factorio's
client-side prototype/sprite caches. On huge packs the primary benefits
remain the built-in engine disk caches enabled by each player. Benchmark
the full pack before attributing any specific number of seconds to Razi's
internal improvements.

The optimisation is independent of starmap artwork settings. Razi will not
silently disable starfield details to gain a small unmeasured improvement.

### Reused route highlights and stellar coronas

October 2026 starmap polish reuses existing PNGs for corridor glow and six
additional stellar coronas. It introduces no new on-disk textures and does
not require per-tick runtime rendering. Verify any increase in sprite layer
processing in a real startup benchmark.

## In-game UI work (2.1.20)

The Codex and Galactic Operations are intentionally built around user
interaction rather than new tick-based scanners. A few internal changes
cut down work without reducing graphics quality or changing the refresh rate:

- The Codex builds its planet research-unlock catalogue once per runtime
  session from the installed technology prototypes. Each view still uses the
  current force's live research state, so newly researched planets show up.
- A Codex redraw now groups its current quests by chapter and computes their
  states in one pass. Search and filter use that result rather than
  recalculating every quest for all 18 chapter headers.
- The Galaxy Atlas keeps immutable technology and connection indexes in
  module memory. Route planning still checks the current force's unlocked
  planets but does not repeat the same check for each edge.
- The floating starmap button only receives a new GUI location when the
  resolution or UI scale has actually moved it. Normal map-state polling is
  unchanged.
- The planet/platform list normalizes search text, recent items, sorting
  names and group ranks once per redraw rather than during every comparison.

These caches are **not written to storage** and do not affect save size.
Research completion, optional planet availability and the starmap routes
remain controlled by Factorio. The included fixtures check these behaviors;
measurable UPS/UI improvements require timings from the full modpack in-game.

## Data-stage indexing pass (2.1.21)

The optional industrial recipes share one machine-category catalogue instead
of scanning every furnace and assembling machine for each exchange. Fluid port
counts are calculated when the catalogue is built; individual planet surface
conditions are still checked for each proposed recipe. The same engine reuses
a one-time lookup of which science packs each lab accepts.

The campaign weave and regional research bridges now keep recipe-unlock
information for **only the science ingredients they actually check**. The
regional pass also exits without a broad scan when none of its optional
candidate worlds is installed. These changes do not remove crafting checks
or relax science/progression constraints.

These are in-memory data-stage lookups and are discarded once prototype
building finishes. They add no save data and do not change any images.
A game update or new mod release will invalidate Factorio's prototype and
sprite caches, so judge startup improvements on *repeat* launches with the
same exact mod list and settings, not the first rebuild.

To compare before and after, collect `factorio-current.log` for both versions
and compare the elapsed durations of **Loading mod settings**, **Loading mod
prototypes**, **Building prototypes**, **Loading sprites**, and overall
startup. A faster Lua data stage will not fix slow texture decompression or
third-party prototype creation. No measured seconds saved are claimed without
an actual before/after run of the full modpack.
