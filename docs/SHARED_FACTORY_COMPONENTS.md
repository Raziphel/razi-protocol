# Shared Factory Components: cross-world production, not grind

Four reusable intermediate items reward the supply network built across
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

This is a *data-final-fixes* compatibility layer. The component
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
- Deep mode is also necessary for the Umbra Pressure Frame and its
  return-cargo Vesta/Aquilo variants.

## Audit before release

These source IDs come from existing Razi compatibility definitions,
but some upstream mods may rename or disable recipes. New component
availability is guarded and cannot be assumed until testing in the
complete game engine. Run the pure Lua fixture plus the Python static
test, the full post-load `scripts/audit_supply_chains.py`, and inspect
in-game assembler categories and physical surface limits.

No runtime tick logic, new planet, custom graphics asset or independent
fleet scheduler was introduced.

## Panglia Optic Bond

- **Eight per craft** (10 seconds) using 2 Panglia glass, 2 Moshine
  optical cables and 1 Fulgoran holmium plate.
- Research requires **360** of each Solaris and Nyxaris tech card,
  after the original source technologies are available.
- One bond per four source batches enters Paracelsin electrochemical
  coils or Linox rare-earth refining. Those optional studies cost 520
  and 650 research units respectively.
- Their craft time penalty is 10% and the gross bonus is capped at 25%.
  Producing eight bonds from a single interplanetary mixture spreads
  cargo costs across many manufacturing runs.

## Umbra Pressure Frame (Deep only)

- **Eight per craft** (20 seconds) using one Panglia Optic Bond,
  one Crucible science pack, two Vesta supermagnets and two Linox
  rare-earth powders.
- The component unlock costs 980 each of Beetlejuice/Umbra science.
  Native pressure, magnetism and material supply remain required.
- Two late consumers return the frame to Vesta foundation workshops
  and Aquilo cryogenic controllers. Their research costs 960 and
  1100, respectively.
- Each consumer keeps the native source ingredients and byproducts
  across four batches, consumes one additional frame and uses a 12%
  crafting-time premium. The bonus is computed from **the actual
  native output quantity**, not hard-coded at +1 for bulk products.

A physically meaningful import route cannot be confirmed solely from
prototype identities. To compare expected output per machine, use
`scripts/audit_exchange_economy.py` with the full loaded Factorio
prototype dump. The source recipe and all original campaign progress
must remain viable without these optional intermediates.
