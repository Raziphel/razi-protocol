## Vibrant: visible metallic divide and clean freight lanes (October 2026)

The existing two 512px Vibrant textures had a bright annulus centered
around 24 starmap units, while the actual inner/outer asteroid gateways
are at radii 31 and 39. The new texture scales place the painted belt
around radius 34–35 without adding another PNG or a false route. Purple
glow is dimmer and pale metallic rubble is stronger, so the belt reads
as a field of debris rather than a soft neon ring. Artwork remains
optional under the existing atmosphere and background settings.

Fulgora and Ribbonia now have better separation inside the ring. Their
two direct local links replace the old gateway/Fulgora/Ribbonia triangle;
the route then proceeds through Ribbonia to the original 5,000 km
inner-to-outer asteroid crossing, with Paracelsin and Beetlejuice
accessible only on the far side. Source moon routes, asteroid spawns,
research unlocks and physical travel lengths are unchanged. All
curated Vibrant local connections use native straight chords so legacy
unanchored arcs cannot curve across the centre of the system.

## 2.1.71: Quiet-star atlas and region-specific belts

This is an **actual source change in Razi Protocol Dev**, using its existing
hand-authored graphics rather than substituting a wallpaper image.

- The 6×6 starfield still uses the four existing 1024px source textures, but
  now applies tiny deterministic exposure variations from cell to cell.
  At wide zoom, that softens repeated tiles without runtime drawing, new
  assets, larger sprites or additional GPU atlas layers.
- System glow radii and opacity are reduced, particularly at Solaris,
  so planet markers, chart labels and real routes remain crisp. Vespera's
  ambient color is now neutral pearl-white; Umbra's is subtle copper
  rather than a second purple Vibrant.
- Vibrant's existing `belt-vibrant.png` and `debris-vibrant.png` artwork
  remains its **only** dedicated ring. The redundant generic Vibrant ring
  has been removed from the atlas, and its original artwork is prepended
  behind native star and planet sprites. Its alpha and footprint are
  reduced without changing the physical asteroid belt geometry.
- Vespera and Umbra now combine a faint common `atlas-belt.png` layer
  with their individual existing `debris-vespera.png` and
  `debris-umbra.png` sprites. Their colors match their star identities,
  rather than covering the whole system with a neon orbit circle.
- The four remote dust pockets are smaller and softer; the four
  micro-accents are shifted beyond main planet orbits, with lower
  intensity. No false navigation rings, new starmap destinations or
  planet/route coordinate changes are introduced.
- Belt-specific route strokes echo each region: metallic violet at
  Vibrant, pale silver-blue at Vespera and muted ember at Umbra.
  They're static, narrow and sit under Factorio's clickable route map.

All art switches preserve the existing setting names. The background
`Off` toggle and belt-atmosphere toggle now consistently suppress
Vibrant's special ring, just like the generic belts. The optional
Better Starmap Background mod gets preference for *both* Razi layers.
Switching artwork off does not touch belt coordinates, unlocks,
asteroid distributions or saves.

**Source files:** `prototypes/system/starmap_background.lua`,
`prototypes/system/asteroid_belt_integration.lua`,
`prototypes/system/route_highlights.lua`. All referenced PNG assets
were already part of Razi Protocol.

**Manual visual acceptance:** Test Subtle, Cinematic, Off, and
belt-atmosphere Off with the full modpack at near, medium and full
galaxy zoom. Inspect whether any route labels overlap dust, whether
Vibrant is visibly doubled, and whether Vespera/Umbra show distinct
debris signatures. Static fixture checks do not replace screenshots
of the actual rendered starmap.

## Fine starfield textures (2.1.48)

The four original 1024×1024 starfield PNG sheets are replaced with
deterministic, sparse **one-pixel pinpoints**, carefully scattered cool
and warm white specks and rare three-pixel cross sparkles. No blurry
five- or ten-pixel star blobs. The familiar 6×6 tile layout, nebulae,
system star art and textures remain separate; no runtime particle or
per-frame star generation is involved. Subtle and Cinematic modes still
exist, using star-dot contrast rather than apparent star diameter.

> **2.1.46 quiet chart pass:** The extra Solaris halo is smaller and lower
> opacity, the indexed background is dimmer, and four giant fog patches
> in the first-frontier travel area have been removed. Native sun artwork
> stays untouched. Solaris now shows a single reference orbit in Balanced
> mode. See [Solaris compact polish](STARMAP_LAYOUT.md#solaris-compact-orbital-polish-2146).

> **2.1.45:** A new built-in Razi path renderer replaces the previous
> retired route layer. It reuses a single small directional atlas,
> applies consistent short-stroke scaling, and adds only verified paths.
> No unrelated background graphics or planetary art are changed.
> See [ROUTE_HIGHLIGHTS.md](ROUTE_HIGHLIGHTS.md).

> **2.1.44 route correction:** Razi no longer paints 2048px
> directional-stroke sprite segments behind the map. Factorio owns the true
> connection geometry, and the optional Space Route Overlay 0.2.7+ handles
> hazard-based colors when installed. Earlier colored-atlas sections below
> describe the retired implementation. Solaris also uses native direct
> connections in place of its oversized local arc sweeps.

> **Solaris 2.1.43:** The Solaris ambient glow strength is reduced while
> preserving the original star core and shared static starfield. Planet orbit
> repositioning and transport-graph changes are documented in
> [STARMAP_LAYOUT.md](STARMAP_LAYOUT.md#solaris-local-orbital-chart-2143).

> **Current 2.1.42 atlas baseline:** Calidus Drift is retired. The 6×6
> original indexed star atlas remains, with lower contrast and smaller
> system light, belt particles and fine detail; route highlight opacity has
> also been reduced. The sections below document historical art experiments.

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

## Calidus atlas cleanup (October 2026)

The first system now separates home-world and moon labels (Nauvis east,
Muluna west, solar orbit waypoints on opposing sides) without relocating
source-owned moon positions. The Calidus Drift salvage node has one small,
low-opacity amber ambient halo rather than another huge orbital ring.

The overdrawn all-route atlas had incorrectly reconstructed native arcs
without a known centre as circular sweeps around {0,0}. It now **never
guesses** that geometry: colored strokes cover straight connections and
explicitly centered, short, radial-safe local arcs. Other native arcs remain
as their authentic gray Factorio curves until their exact path can be
validated. The default-colored strokes are also dimmer and capped at 600
static segments instead of 1,800, to avoid visual spaghetti.


## High-resolution deep-space atlas (2.1.40)

The starfield draws inspiration from the starry background of Tserup's mod,
but all textures were authored independently for Razi Protocol. Four original
1024px indexed transparent PNGs are arranged across a four-by-four atlas
covering the central seven systems and the deep-space frontier. Their render
scale is half the earlier value, preserving the same map coverage while giving
each star twice the source resolution. Star points vary in temperature,
brightness and clustering while leaving dark breathing room for planets,
routes and labels.

The halo, dust and belt overlays are now 512px rather than 128px. Their scales
were reduced by the matching factor of four, so their world-space footprint is
unchanged but their corona, wisps and asteroid fragments remain crisp. Lower
default opacity keeps route lines and labels readable. The new halo has a clear
core for the real system star; dust is asymmetrical rather than a round smudge;
and belts use broken particle arcs instead of a soft neon loop.

Thirty-six static background sprites are rendered below the current system
halos, real stars and other game artwork. The existing Subtle and Cinematic
settings change their opacity; Off disables them. Fine detail, belt and
cartography switches remain independent, and the existing compatibility
guard defers to Better_Starmap_Background when installed.

This adds no tick loop, gameplay hazard, research gate, map node or route.
The transparent textures remain bounded by the asset-contract size limit.
Full Factorio 2.1 graphics testing at multiple zooms remains necessary.

## Crisp atlas polish (2.1.41)

The starfield now uses a six-by-six grid at 4x source scale. It covers the
same map area as the former four-by-four grid at 6x scale, but point stars are
one-third smaller and no longer magnify their soft fringe into square blobs.
System coronas are also more compact so they frame the real star art without
washing out planets, labels, or route lines.

Three transparent orientations of a new original dust lane replace the
repeated central smoke texture. Their narrow granular structure, alternating
direction, large transparent margins, and slightly reduced render scale
create localized galactic detail without an obvious repeated stamp. The
background remains static and keeps the existing Better Starmap Background
compatibility guard.
