# Razi Protocol Art Direction

Razi Protocol's visual identity is anchored by the existing Solaris, Nyxaris,
Vibrant, and BeetleJuice stars and by the eight industrial technology cards.
New assets should extend that collection rather than reinterpret it.

## Stars

- Use a centered, nearly frame-filling stellar disc on transparency at
  1024 x 1024 pixels.
- Preserve the originals' turbulent, layered surface detail, restrained corona,
  sharp alpha edge, and strong readability when reduced for the starmap.
- Give each system a controlled palette and characteristic surface pattern;
  avoid flat circles, generic lens flares, text, frames, or scenery.
- Vespera is cold white/cyan with blue-violet depth. Umbra is near-black indigo
  with ultraviolet/magenta fissures and a pale violet limb.

## Technology cards

- Cards are 256 x 256 transparent PNGs using the same tilted, chunky industrial
  cartridge silhouette, dark worn metal, copper contacts, inset stellar window,
  bevel lighting, and compact framing as the original card set.
- The inset star carries the system palette while the casing remains materially
  consistent across the collection. Dedicated art is preferred to runtime tint.
- Details must survive Factorio's small inventory and technology icon sizes.

## Route icons

The four 64 x 64 icons in `graphics/icons/routes/` form one compact family:

- `planetary-route`: ordinary local planetary travel.
- `interstellar-route`: travel between stellar systems.
- `asteroid-route`: hazardous asteroid-belt crossings.
- `deep-space-route`: extreme-distance and late-game routes.

Their editable SVG sources are kept beside the PNGs. All use a worn octagonal
navigation-instrument housing, recessed fasteners, a dark gridded display,
high-contrast route marks, restrained emissive color, and clean alpha. The
silhouette and main route symbol must remain legible at 32--64 pixels; avoid
glossy circular badges, flat neon nodes, or UI treatments that read as generic
mobile-app icons. Add a category only when it communicates a genuinely
different route.

## Ownership and validation

Keep external-mod graphics as dependency references; do not copy them into this
repository. The legacy `graphics/orbits/` images were not restored from the
original edition: Dev has no references to those bitmap rings and its current
PlanetsLib orbit/starmap layout uses prototype orbit data instead.

Run `python3 scripts/audit_assets.py` after changing graphics. The audit resolves
every Razi-owned graphics path, validates PNG headers, alpha and known dimensions,
and protects the dedicated star/card and late route-icon contracts. Lua route
fixtures additionally verify that every final space connection receives an icon
without overwriting icon metadata owned by another mod.
