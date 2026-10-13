# Space route visuals: native paths with one color renderer

Razi Protocol 2.1.44 retires its broken segmented route-stroke compositor.
The old baked directional atlas, fixed guide masks and color setting are not
used. They could not track actual game arcs and produced jagged, offset,
duplicated colored lines across the galaxy.

## Recommended companion

Install [Space Route Overlay](https://mods.factorio.com/mod/space-route-overlay)
**0.2.7 or newer** (by valent125) if you want colored routes. Its overlays
follow native Space Age routes and automatically reflect the asteroid threats
of the individual connections. Razi itself no longer attempts to paint those
lines. With the companion missing, only Factorio's native gray connections
are displayed, not an inaccurate fallback.

The mod declares a hidden optional Razi dependency in 0.2.7. Razi records
`~ space-route-overlay >= 0.2.7` as a compatibility requirement **only when
it is present**, without imposing a reverse load order. A normal hard
dependency from Razi to Space Route Overlay would risk a dependency cycle
with Space Route Overlay's own optional Razi integration. The player installs
and enables Space Route Overlay in the mod browser. No external source
assets or implementation are copied into Razi.

## Source ownership

- Factorio and the original planet mods own connection rendering and geometry.
- `prototypes/system/route_reconcile.lua` owns the Razi-authored travel graph,
  length, local shape and asteroid profile. Solaris connections are explicit
  straight lines between real endpoints, not radial arcs with mismatched centers.
- `prototypes/system/route_hazards.lua` and `route_intel.lua` continue to
  power the danger tiers, ship advice and belt crossing data in Razi tooltips.
- Space Route Overlay, when installed, is the only mod responsible for
  color on the visible connections. No extra GUI / render tick loop is added
  by Razi.

## Verification

Verify both with and without Space Route Overlay on Factorio 2.1. Check
dangerous asteroid profiles, outer belt edges, long interstellar lines, and
Solaris's local eight-connection corridor. No route must be colored twice;
the overlay must not draw an invented arc or cover a neighbor planet.
A full graphics test with the installed mod and existing save is necessary.
