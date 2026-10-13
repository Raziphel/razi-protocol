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
