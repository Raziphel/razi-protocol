# Shared Factory Components: cross-world production, not grind

Two new reusable intermediate items reward the supply network built across
the required Razi worlds. They are **optional**; no native recipe, system
tech card, star discovery, belt gate or victory trigger requires them.

## Precision Control Matrix

- **Two per craft** (8 seconds, ordinary assembling category).
- Ingredients: 3 Moshine optical cable, 2 Paracelsin zinc plate,
  1 Fulgora holmium plate and 2 K2SO Vulcanus rare metals.
- Research: 420 each of the Solaris and Nyxaris system tech cards,
  after the four planets' existing discovery technologies and the
  relevant actual supplier recipe unlock technologies.
- Portable item: one component is used for K2SO control units
  (Aquilo), Rubia's advanced inserters and Linox rare-earth refining.
- Aquilo: **four** original control-unit batches yield **five** units.
  Rubia and Linox: **eight** original batches yield **ten** units.
  These are large-factory efficiency options, not new requirements.
- Original material inputs and byproducts are preserved, with 15% longer
  manufacturing time per original batch and no productivity stacking.

## Extreme-Environment Lattice

- **Two per craft** (12 seconds, ordinary assembling category).
- Inputs: 1 Precision Control Matrix, 2 Rubia craptonite frames,
  2 Tenebris chitosan, 2 Linox rare-earth powder and 2 Gleba
  carbon fiber. Carbon fiber is a stable material, not spoilable
  bioflux shipped across multiple stars.
- Research: 680 each Vibrant and Vespera tech cards, after Rubia,
  Tenebris, Linox, Gleba and all actual supplier research.
- Premium alternatives: Vesta supermagnets in Balanced; additional
  Vesta foundations and Balack radiation shielding in Deep.
- Each guarded alternative consumes 1 lattice in addition to the
  original materials of four native batches. Bonus output capped at
  25%, and productivity and automatic recycling are disabled.

## Robust registration order and conditions

This is a *data-final-fixes* compatibility layer. Both component
definitions register **before** the existing production exchange engine
builds its native unlock index. Their bonus recipes register **after**
all original exchanges and preserve factory surface/category rules.

Each material is checked against the installed modpack for an actual
producer recipe and its own technology unlock when necessary. A missing
source mod, recipe, native science pack or capable lab suppresses
only the **affected** component. For example, missing Linox blocks
the late lattice but does not block the earlier Precision Matrix. The second
component safely disappears if the first cannot be constructed.

Independent startup settings remain authoritative:
- Planetary interdependence Off disables all these new additions.
- The modded-planet-exchanges toggle disables the component framework.
- The K2SO-exchanges toggle independently disables the Aquilo premium
  controller variant; it does not disable the other modded exchanges.
- Deep mode is necessary only for the Vesta foundations and Balack
  premium upgrades.

## Audit before release

These source IDs come from existing Razi compatibility definitions,
but some upstream mods may rename or disable recipes. New component
availability is guarded and cannot be assumed until testing in the
complete game engine. Run the pure Lua fixture plus the Python static
test, the full post-load `scripts/audit_supply_chains.py`, and inspect
in-game assembler categories and physical surface limits.

No runtime tick logic, new planet, custom graphics asset or independent
fleet scheduler was introduced.
