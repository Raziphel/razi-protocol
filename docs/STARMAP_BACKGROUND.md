# Seven-System Starmap Background

Original Razi Protocol static artwork for Calidus, Solaris, Nyxaris, Vibrant, Vespera, Beetlejuice, Umbra and Deep Space.

## Layers and identity

Four transparent sky tiles span map coordinates from -256 to +256 on both axes. A broad dust current visually joins the major systems. Each star has a unique, tinted nebula image and Deep Space has a separate cold-blue veil. Three faint dust rings mark the Vibrant, Vespera and Umbra belt regions.

Calidus is gold; Solaris is orange; Nyxaris is turquoise; Vibrant is violet; Vespera is pale icy blue; Beetlejuice is magenta; Umbra is burgundy; Deep Space is cold blue.

These are background layers only. Original planet, orbit, star, native belt, route, and research definitions are unchanged.

## Settings

- Custom universe background: Off, Subtle (default), Cinematic.
- Individual system nebulae: On (default) / Off.
- Asteroid belt dust halos: On (default) / Off.

Settings apply at startup. Cinematic increases the opacity of static imagery and does not animate or twinkle.

## Compatibility and performance

All 16 original paletted transparent PNGs are 1024 pixels or less per side. No 4096/8192 asset or extra-large atlas requirement. Artwork is registered once in data-final-fixes, after positioning the galaxy and before route highlights. There is no runtime tick work.

The original Better_Starmap_Background takes precedence if both mods are installed, preventing duplicate wallpapers. The native AsteroidBelt ring remains in its existing sprite layer above the dust halo.

Python and Lua fixtures verify image structure, atlas limits, sequence, source ownership, and settings. In-game Factorio rendering still needs validation.

## Galactic Scenery Expansion

Seventeen additional original textures bring the atlas to **33 PNG assets**: eight spiral nebula filaments, three irregular debris rings, three distant stellar nurseries, a cold Deep Space gravity-lens motif, a second braided dust stream, and an optional observatory-style star chart. Razi's pre-existing 16 images remain intact.

**Default Subtle** composes 32 sprite layers behind the game's stars, native belts and routes. **Cinematic** composes 40 layers by adding low-opacity expanded filament passes which reuse the same texture assets. The optional Observatory ring adds one additional layer. Both modes keep main route colours visible. Under the new **Detailed galactic scenery** setting, users can disable all new textures and revert to the original 16-layer background without losing the Razi universe theme.

Every image remains 1024 pixels or smaller. The new artwork is constructed only at data loading and adds no per-tick effects or star-map GUI polling. Original asteroid encounters and planet gates remain unchanged.

## Quiet nebula architecture (October 2026)

The default subtle map now has ten **extra static layers**:

- Four dim, distant chromatic dust wisps positioned outside the dense
  navigable seven-star hexagon.
- Six small secondary star halos that preserve the original icon-sized
  silhouettes and system colors.
- The existing Calidus Dyson corona remains behind source orbit markers.

These use preexisting Razi PNGs; no added spritesheets, large images,
new light shaders, background tick logic or memory-heavy GUI scans.
`razi-starmap-galactic-ornaments` can independently remove all ten
additional layers. It works in Subtle and Cinematic themes, remains
off in Background Off mode, and is automatically skipped if the
external Better Starmap Background owns the art.

This is a **static data-stage sprite layer**. Native sun routes, planet
locations, weather, hazards and unlock logic are unchanged.

## Stellar micro-scenery pass

The fine-detail / galactic-ornament layers now have an independently
switchable **Stellar micro-details** setting (default On). It places:

- Eight small, tinted star-swarm pockets near the *far side* of the seven
  principal regions plus Deep Space, away from their navigable planet icons.
- Eight faint filament shadows paired with those pockets, giving the systems
  distinct shapes even at the edge of their charts.
- Four dim distant stellar echoes in otherwise empty outer sky.
- Six low-opacity dust/debris flecks around the three belt corridors,
  behind the genuine belt symbols and danger-coloured routes.

The new pass adds **26 lightweight sprite references** from the *existing*
paletted Razi textures, without adding a new sprite file, simulation work,
dynamic rendering, or any claimed change to Factorio's discoveries.
Subtle mode now builds 74 base scenery layers when all visual toggles
are enabled; Cinematic builds 76. Disable micro-details to restore the
previous 48-layer Subtle treatment, disable Fine Details to return to the
original 16-layer background, or disable Background entirely.

Visual staging order remains: background atmosphere, micro scenery, native
orbital art and source belts, then highlighted real routes. This is static
parallax-*style* composition, not animation or simulated twinkling.
