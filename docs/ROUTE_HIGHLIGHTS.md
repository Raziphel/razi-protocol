## 2.1.98: Real colored routes, not colored midpoint pips

Screenshots in 2.1.95 showed a completely grey starmap because the
ten-stage palette only tinted small, low-visibility single-point markers,
and the Major route scope excluded most real connections. Those markers
were never the requested full-length colored routes.

Razi now renders solid, antialiased *colored paths* exactly over verified
native Factorio connections, while leaving the original travel and hover
graph alone. A shared 1024x512 sprite atlas contains 128 directions,
selected for short segments (target 3.6 chart units). Each connection
is sampled along its real native line or validated arc origin, with
precise world-coordinate shifts, extra join coverage and no parallel
offset. The sprite lines are tinted to the same blue-to-red levels 1-10
used by Quality Asteroids. No dots, square-block seams, invented route
geometry, or fixed precomputed planet coordinates.

The default scope is now **All**. Old saves with the saved Major
setting can change the setting to All under Startup Settings to get
local lines too. Off still suppresses overlays. An adaptive allocation
caps draw-layer count to 1,600 and shares the budget among known
connections. In rare very crowded maps, geometry that cannot safely
be verified is left native-grey, rather than drawing a fake route or
causing a startup crash. PlanetsLib orbits and all native routes remain
intact. The old carna/gleba/velora dotted aesthetic is not reintroduced
because the new atlas is solid and uses actual route geometry.

Asset: `graphics/route-highlights/route-ribbons.png` (shared texture).
Generator: `node scripts/generate_route_ribbons.js`.
Renderer: `prototypes/system/route_ribbons.lua`.
This adds no tick handlers or savegame entities; startup render only.
Visual alignment, sprite loading and route hover/click behavior still
require verification in Factorio itself.

## 2.1.94: 10 distinct quality-danger colors (blue to red)

Razi now uses the first-party 10-level asteroid quality curve as its
single map color key, rather than the older 5-level size-only palette.
The **highest encountered quality-difficulty level** along each native
route determines its marker's color. This warns about middle-of-route
danger spikes as well as the destination. Each level has a separate
static color:

| Level | Route marker | Meaning |
|:--|:--|:--|
| 1 | #5485C9, steel blue | starter |
| 2 | #47A1C9, sky blue | low |
| 3 | #40B3B0, teal | early |
| 4 | #4ABA87, emerald | developing |
| 5 | #70C266, green | moderate |
| 6 | #A8C25C, lime | difficult |
| 7 | #D1BA4D, yellow | advanced |
| 8 | #E0964A, orange | severe |
| 9 | #D6664A, vermilion | extreme |
| 10 | #C7384A, crimson red | guaranteed legendary hostile asteroids |

The overlay uses a dedicated tiny white signal-pip icon,
`graphics/route-highlights/quality-risk-marker.png`. White pixels
accept the exact difficulty tint instead of muddling blue and green
with the older gold/bronze route icon artwork. Its editable SVG and
deterministic generator are retained for future polish. Source-owned
connection icons in `graphics/icons/routes/` remain completely intact.

Color is derived from `scripts/razi_asteroid_difficulty.lua` and also
applies to the value inside native route tooltips. Danger and Chapter
modes honor the same scale while quality asteroids are enabled.
Every qualifying corridor, even level 1, receives at most **one small
tinted marker**, with stronger warnings on levels 8-10. The existing
major/all scope, 36-marker budget, no-overlap policy, native clickable
lines, real orbit geometry, and historical red-dotted-trail cleanup
remain intact. Marker colors are static for a route's *peak* level;
they do not update per-tick or color entire routes. Factorio 2.1's
SpaceConnectionPrototype does not expose a native line tint, so Razi
does not reintroduce the notorious second parallel route line.

If Razi's quality-asteroid feature is disabled, the original 5-class
asteroid-size coloring remains as a compatibility fallback. No spawn
probabilities, route geometry, technology, or save ID is changed.

## October 2026 old route-guide removal

The retired hand-positioned guide-01 through guide-14 sprite files and
`route_highlight_manifest.lua` have been deleted. They described
hardcoded positions from the previous six-star map and are not imported
by the current Razi route overlay. The current
`graphics/route-highlights/continuous-strokes.png` sprite sheet remains
the sole route-overlay texture, with final native coordinates and actual
asteroid risk values governing color. No routes or danger data were deleted.

## 2.1.91: Single native line, sparse safety warnings

Screenshots proved Razi's continuous-strokes tile atlas produced a
green parallel line with repeated square joins on top of Factorio's
native route. All multi-sprite route coloring is retired. The native
connection draws the only full-length line and remains clickable.
The risk inspector and detailed route hover text are unchanged.

Danger mode now emits only one small offset badge on serious asteroid
danger or genuine belt crossings; medium and safe routes have no extra
art. Chapter mode can add single small accents at major waypoints.
Symbols are capped at 36, checked against nearby glyph positions and
never generated from unknown distant arcs. Retired first-party route
strips are removed. No route, research, travel, or save changes.

## October 2026 route color refinement

Reference: Space Route Overlay 0.2.7 uses actual asteroid spawn sizes
to derive route colors (small/blue, medium/green, big/yellow,
huge/red), with special categories for extreme/warp corridors.
Razi retains its independent route geometry, native real-connection
tracking, and its single authoritative hazard inspector.

The refreshed palette uses muted blue-grey for routes without recorded
hostile spawns, blue for small asteroids, green for medium, warm amber
for big, and restrained red for huge or dense big asteroids. Chapter
mode stays available but uses quieter neutrals and never suppresses
high-threat colors. The alpha ladder is now 0.105/0.14/0.19/0.25/0.30,
so simple travel no longer paints a second loud line across the map.
Physical asteroid belts have a caution floor of 0.26 opacity.

Strokes are shorter and joined with smaller overlap, reducing the
noticeable step between directions. The total atlas-layer budget is
slightly lower. No route connection, entity, asteroid spawn, discovery,
or travel geometry is modified. The external overlay remains
incompatible, preventing duplicate decoration. Validate native
Factorio chart zoom before making further visibility adjustments.

## Native route freight intelligence (2.1.50)

Native space-connection tooltips now give a **haul distance band** using
actual route kilometres and an **asteroid size mixture** from its
configured hostile asteroid spawn definitions. The resulting labels
distinguish one size, multiple sizes, unknown modded asteroid types, or
none listed. No travel-time estimate, promised encounter, altered route,
asteroid curve or additional runtime event is involved.

# Razi route overlay (built in)

Razi Protocol Dev **2.1.45** implements its own route overlay. No external
renderer is required. Space Route Overlay is marked incompatible so two
renderers cannot paint competing paths.

## What's different

The old Razi compositor stretched one directional glyph across 20+ chart
units and tried to infer distant arcs from a partial orbit catalog. Lines
looked disconnected and varied in width and thickness. Version 2.1.45
retains Razi's small 64-bearing source atlas, but **completely replaces
the geometry algorithm**:

- Read the final Factorio 2.1 space-connection shape/origin and actual
  planet/location distance/orientation/origin after route reconciliation.
- Use the source PlanetsLib orbit only when a native absolute coordinate
  is missing. Resolve known removed virtual stars using Razi's galaxy
  layout anchors.
- Split paths into short, equal-length ~6 chart-unit chords. This avoids
  scaling an oversized sprite to cover long distances and creates a
  consistent thin stroke at every bearing.
- Stop painting ~2.2 chart units before each location, keeping planet
  marker labels and connection hover targets unobscured.
- Color from the **real asteroid spawn profile**, not inferred threat from
  the destination planet. The existing route_hazards palette is shared
  with Razi route-intelligence tooltips; belts are purple.
- Optionally color by Razi chapter instead of danger, without modifying
  actual technology unlocks.
- On regional arcs, honor explicit route.origin and only draw short,
  near-circular segments. Default-origin arcs are only safe to color
  inside the home system. All ambiguous curves remain native gray
  rather than showing phantom loops across the galaxy.
- Precompute in data-final-fixes; no scripts, events, per-frame rendering
  or game-tick work.

## Settings

| Setting | Default | Other choices |
| --- | --- | --- |
| Razi route colors | **Asteroid danger** | Chapter, Off |
| Colored route coverage | **Major routes and belts** | All verified connections |

**Major** is intentionally sparse to keep local planetary routes readable.
**All** also colors short validated local routes, at half the major opacity.
Invalid or wildly curved routes stay native under either setting.

## Installation

This is included directly in Razi Protocol Dev. Do **not** install
Space Route Overlay alongside Razi, because the mods are declared
incompatible to prevent drawing the same network twice.

## Validation

In Factorio 2.1 confirm hazard colors follow all major lines without
doubled native shapes, no dropped line caps in Solaris, and no fake
galactic arcs around sprite-only stars. Test dangerous asteroid belts and
old saves, including hover interaction in remote view. The static fixture
is not a substitute for these in-game checks.

This implementation is original to Razi. No third-party source code or
artwork was copied.

## 2.1.78 decorative half-line cleanup

Screenshots showed thin red dotted pairs ending partway across the chart
near Carna and Velora. The old renderer could decorate arbitrary source
connections, which may point outside a system after repositioning worlds.
The visual overlay now paints only canonical Razi interstellar hub corridors
and native belt crossings; smaller planet/world links remain native Factorio
space connections and are not erased. This is deliberately a visual-only
change; unknown source sub-networks, modded travel and asteroid spawning
remain unchanged. The danger/Chapter options still color primary corridors;
All no longer adds doubled route strokes to ordinary planet links.
