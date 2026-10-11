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
