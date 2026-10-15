# Early Lava Compatibility for Factorio 2.1

Companion **`a-razi-lava-compat`** is a separate, tiny Factorio mod.
Rabbasca 0.22.4 and Crucible 1.2.4 still index
`data.raw["tile-effect"]["lava"].water.textures[2]` even though Space
Age 2.1 stores its lava image at `water.image_textures[1]`.

This companion aliases those two entries **before** independent source
planet `data.lua` files load. Because the references point to the same
image object, planet lava recolors are preserved when source mods
deep-copy or merge the base effect.

The alias is removed in the companion's data-final-fixes, and again in
Razi's last final-fixes handler if the companion is installed, to prevent
unknown or obsolete properties in finished tile-effect definitions.

## Distributing to all players

1. Test with the complete Factorio 2.1 modpack and both failing planets.
2. Publish the ZIP as a new Factorio helper mod on the mod portal.
3. Change Razi's `? a-razi-lava-compat >= 0.1.0` optional dependency
   to `a-razi-lava-compat >= 0.1.0` **only after** the portal release,
   so Factorio automatically installs it for every Razi player.

The repository code by itself cannot install the companion. It is not
a complete released fix until those steps happen. Do not suppress or
remove Crucible/Rabbasca from the campaign.

This is a compatibility layer, not an edit of another author's mod ZIP.
It changes no surfaces, science, route lengths, endgame conditions or
planet artwork assets.
