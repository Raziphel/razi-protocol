# Temporary Factorio 2.1.22 upstream compatibility

This folder holds **all temporary 2.1.22 prototype migration code**.
No planets, machines, recipes, textures or gameplay features are disabled.

- `fluid_boxes.lua`: translates removed FluidBox temperature properties;
  fixes machine-level invalid minimums (e.g. Panglia roots 0 C vs
  branbalite slurry's 165 C default), and old unlimited-temperature zeros.
- `tile_effects.lua`: migrates legacy wetland, lava, oil and water effects
  while keeping each planet's image atlases.
- `audit.lua`: logs formats it cannot safely repair instead of fabricating
  values or changing unfamiliar prototypes.
- `loader.lua`: the only integration entry point, runs at the END of
  `data-final-fixes.lua` and only with Factorio 2.1.22+.
- `tests/`: source regression fixtures including Panglia and Cubium.

**Known initially affected mods:** Corrundum, Panglia, Cubium, Planetaris:
Tellus, K2SO, and other planet dependencies using the old API.

## Complete removal

1. Confirm all affected mods are updated, with a successful full Factorio
   modpack load and no 2.1.22 compatibility audit warnings.
2. Delete the directory `temporary/factorio_2_1_22/`.
3. Remove the ONE `require("temporary.factorio_2_1_22.loader")`
   line and two preceding comments from `data-final-fixes.lua`.
4. Repeat smoke tests. No additional production files need editing.

The shims are version-gated but do not automatically switch off for future
patches. They become no-ops on already-fixed prototypes. Do not remove them
until the installed versions of the upstream mods work without them.

**Phase 3 audit hardening:** the read-only checker now also reports legacy
temperature fields nested in fluid-burning `energy_source` boxes. These are
already covered by the migration bridge. All findings are diagnostics, not
permission to modify third-party archives or remove the shim automatically.

## Oil atlas regression (Balack 1.1.2)
The legacy oil texture order is noise, **image atlas**, gradient, **specular
atlas**. Only slots 2 and 4 can enter `image_textures`. Slot 3 is the
512x32 gradient belonging to the 2.1 two-texture noise shader instead.
Oil artwork pairs are migrated only when their declared atlas dimensions
match; unfamiliar layouts remain unchanged and are reported by the audit.
