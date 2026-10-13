# Clean starmap redesign

The default star map renders new 128-pixel feathered halo, dust and belt sprites instead of the legacy tiled nebula, portal, swirl and filament textures. Cinematic raises opacity without adding more layers. Subtle route mode uses native Factorio lines; Clear adds one verified low-contrast stroke. No tick-based art or planet-route gameplay changes.

Optional planets Igrys, Foliax, Obsidiax, Carna, Ferrum, Khemia, Arcanyx and Balack are positioned both before sprite-only star cleanup and in final native coordinates. Native moons remain under their original parent.

Verify in Factorio 2.1 at multiple zoom levels before promoting to stable.

## Campaign-coloured navigation (October 2026)

The previously white primary interstellar guides now use a deliberately
restrained, single-stroke colour system. Early routes read turquoise, middle
routes gold, outer/deep-space routes lavender and actual asteroid-belt
crossings rose. The **real route asteroid hazard tier** warms dangerous
connections toward orange or red, so campaign order and difficulty both
contribute to the resulting colour. Subtle is visible by default, Clear
increases opacity, and Off preserves native rendering. The visual overlay
is restricted to the 14 authored, position-verified, straight or belt-guide
masks: curved and unrecognized routes are not painted with inaccurate
straight lines. This is a map decoration, not a gameplay or pathing change.

## Refined atmosphere assets

The halo, dust and belt PNGs now use the full 256-level alpha range instead
of the earlier stepped opacity palette. This removes the sharp concentric
bands visible in the first clean-map screenshot. Four extra, half-strength
transparent dust pockets fill the central stellar gaps without bringing
back dense overlapping nebula art. The default composition is 23 small
sprites rather than the previous 19, with unchanged prototype geometry.

## Full modpack route palette (October 2026)

Factorio 2.1 has no per-connection colour field on SpaceConnectionPrototype.
Razi now uses one 2048×2048 four-level-alpha indexed PNG with 64 reusable
directional samples. At data-final-fixes, after all optional routes register,
every installed visible route with numeric endpoint positions gets coloured
without changing its shape, origin, asteroid spawn definitions or travel
length. Straight routes are segmented exactly; curved routes are approximated
as short polar chords around the source-authored arc centre. A fixed cap of
1,800 static sprite segments prevents extreme modlists from bogging down
starmap composition. Unsupported endpoints and excess routes stay native.

The chart gives core lanes turquoise, first-wave fronts green-teal,
middle-game industrial space amber, outer worlds lilac, and Deep Space rose.
Real asteroid danger warms a route toward orange and red; belt crossings
remain clearly distinguished. Subtle is the recommended opacity, Clear is
stronger, and Off disables the overlays. Space Route Overlay is preferred if
installed. The engine still draws its own interactive routes underneath,
which remain authoritative for click/hover navigation.
