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
