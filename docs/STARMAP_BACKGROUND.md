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