## October 2026 old route-guide removal

The retired hand-positioned guide-01 through guide-14 sprite files and
`route_highlight_manifest.lua` have been deleted. They described
hardcoded positions from the previous six-star map and are not imported
by the current Razi route overlay. The current
`graphics/route-highlights/continuous-strokes.png` sprite sheet remains
the sole route-overlay texture, with final native coordinates and actual
asteroid risk values governing color. No routes or danger data were deleted.

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
