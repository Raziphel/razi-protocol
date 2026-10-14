## 2.1.67: Supplier roles in Galactic Atlas

Unlocked source planets now display their actual installed Cargo Network
component links, using the same source-world identifiers and technology
research states as the Cargo panel. Each Atlas entry opens the matching
existing Cargo Network card for real component ingredients, source worlds
and downstream research. Undiscovered planets remain spoiler-safe. This
does not create a new trade route or require optional components for a
system card; original native production and freight remain unchanged.

## Native interplanetary communication (2.1.53)

AAI Signal Transmission >=0.6.0 is an **optional** Factorio 2.1
dependency, reused without importing or copying its proprietary code or
inventing replacement entities. Players research and construct its own
powered signal transmitters/receivers on matching channels across
planets. AAI moves red/green wire circuit values, **not goods**.
Planet Express remains the only automatic fleet dispatcher; Razi keeps
its Cargo Network read-only.

For interdependence Balanced and Deep, a valid early native AAI
communication technology becomes a prerequisite of two Razi-owned
advanced factory researches: Precision Control Matrix and Panglia
Optic Bond. The link is not applied when the source is missing, disabled,
hidden, restricted to the next outer star, or would make a research
cycle. Off mode never adds the prerequisite. Neither world arrival nor
AAI's own source technology is modified.

The Cargo Network shows native research completion and concise wiring
guidance with an optional Codex link. It does **not** claim to detect
actual channel wiring, receive signals, or change platform requests.
This leverages the upstream implementation instead of duplicating it.

Other candidates:
- Orbital Catapult (orbital-cannon >=0.14): 2.1 MIT and mod-defined
  one-way links, but each link can carry players as well as items and
  could bypass a required planet-discovery or asteroid-belt crossing.
  **Not enabled** until the target-research safety behavior can be
  tested in the full modpack.
- Cargo Ships >=2.1.8: promising for local water-world logistics, but
  not interplanetary and not a universal required dependency.
- Compact circuits >=2.1.0: useful to simplify advanced AAI relay
  combinator installations, but requires FLIB and adds no essential
  cross-world content. Trial as player choice.
- BerbCorp Cargo Bay Loader: 2.1 local landing-pad automation, but
  overlap with other cargo/proxy mods requires a conflict audit.

## Vibrant–Vespera reciprocal factories (2.1.52)

Four middle-tier optional recipes share completed native products:
**Fulgora** makes fortified supercapacitors with Aquilo controllers
and Moshine cable; **Aquilo** combines Fulgora capacitors with Moshine
optics for stable cryogenic controls; **Paracelsin** reinforces
electric coils with Rubia craptonite and Fulgora holmium; **Rubia**
builds conductive craptonite frames with Paracelsin coils and Fulgora
capacitors.

All follow the existing guarded native-recipe exchange engine: real
supplier recipes and unlock research, correct manufacturing world and
category, matching lab science, unchanged native source inputs and
byproducts, four source batches, one bonus item capped at 25%, and
12–15% extra machine time. Productivity and automatic recycling remain
disabled. Missing mod content suppresses only the affected premium recipe.

The Paracelsin and Rubia research milestones are conditional
prerequisites of the **outer** system discoveries. Their premium recipes
are not ingredients of one another, so the integration does not produce
a circular industrial dependency. Their native products, not the bonus
recipes, establish the freight exchange.

## First-frontier manufacturing triangle (2.1.51)

Three new **optional** guarded native-recipe alternatives reward keeping the
first two stars connected even after exploration. Moshine's native silicon
cells can import Vulcanus rare metals and Gleba bioflux. Gleba's native
carbon-fiber production can import Moshine optical cable and Vulcanus rare
metals. Castra's original piercing-magazine production can import Gleba
carbon fiber and Moshine silicon cells.

Each alternative processes four original recipe batches with one bonus
output, charges 12-15% additional machine time and requires actual upstream
supplier recipes, native research, a supported manufacturing category,
a permitted surface and compatible science labs. The original recipes,
item prototypes, research unlocks and surface restrictions are unchanged.
No productivity or auto-recycling bonus can stack on top.

Registration uses the existing modded-planet exchange preference, and skips
an alternative when its source recipes or required technologies are missing
or incompatible. No planetary discovery or chapter science card depends
on these alternatives. Verify actual mod-prototype dump, technology
reachability and factory throughput in Factorio 2.1 before release.

## Return freight: Calidus relay electronics (2.1.50)

The optional `razi-first-frontier-relay-components` research adds a
Nauvis K2SO electronics alternative consuming imported Vulcanus rare
metals, Gleba bioflux and Moshine optical cable. It scales four native
batches, gains one output, charges 12% more crafting time and disables
productivity and automatic recycling. The native recipe is untouched.

The established exchange registration checks native source outputs,
actual supplier recipes and research, world discoveries, ingredients,
machine capability, legal surface and lab science. A missing or modified
upstream prototype safely suppresses this optional alternative. Its
Codex milestone is not a required science-card or planet gate.

# Galactic Industrial Network

**Fourteen optional three-to-five-world recipes** are introduced by this
pass, complementing Razi's existing 26 exchange alternatives. No new
planets, science packs, map surfaces, graphics or background logic.

## Balanced: ten additional partnerships

| Factory world | Native industry | Imports from other worlds |
| --- | --- | --- |
| Vulcanus | K2SO rare metals | Gleba bioflux + Moshine optical cable |
| Paracelsin | Electric coils | Moshine optical cable + Fulgora holmium |
| Moshine | Silicon cells | Paracelsin zinc solder + Fulgora holmium |
| Rubia | Craptonite frames | Tenebris chitosan + Paracelsin zinc + Moshine optics |
| Tenebris | Chitosan | Rubia craptonite + Paracelsin rivets + Moshine optics |
| Linox | Rare-earth powder | Rubia frames + Moshine optical cable + Paracelsin zinc |
| Rubia | Advanced stack inserters | Linox rare earths + Paracelsin coils + Moshine optics |
| Vesta | Supermagnets | Linox rare earths + Moshine optics + Secretas gold |
| Ferrum (optional) | Rare-earth magnets | Linox powder + Moshine optics + Paracelsin zinc |
| Cubium | Secretas gold refining | Linox powder + Paracelsin zinc + Vulcanus rare metals |

## Deep: four additional late collaborations

| Factory world | Native industry | Imports |
| --- | --- | --- |
| Wit (optional) | Late advanced accumulators | Ferrum magnets + Linox powder + Moshine optics + Vesta magnets |
| Balack (optional) | Radiation shielding | Rubia frames + Tenebris chitosan + Vesta magnets |
| Vesta | Native foundations | Rubia frames + Tenebris chitosan + Fulgoran holmium |
| Aquilo | K2SO cryogenic energy control | Moshine optics + Vesta magnets + Rubia frames + Fulgoran holmium |

**All upgrades are optional**. Every source recipe continues to work
unchanged. The original discovery, original producer unlock and all
native source ingredients/byproducts are preserved. Every import must
have a native producing recipe with valid ingredients and, when
necessary, an actual existing technology to unlock it.

Modern production bonuses are capped at **25% of the native batch
output**. Recipes scale the native process to several batches and require
imported components on top of the original cost. The standard network
recipes still charge 15% more crafting time in Balanced or 20% in Deep;
the new Panglia return-cargo recipes use 10%, and the Deep pressure-frame
consumers use 12%. Productivity and auto-recycling cannot multiply gains.

The existing `razi-planetary-interdependence` Off / Balanced / Deep
setting controls visibility. The independent K2SO and modded-world
exchange toggles continue to work. Missing mods or ingredient producer
identities suppress only the affected optional upgrade. No mandatory
world discovery, science card, machine, asteroid belt or route is
altered, and there are no new tick-time scripts or sprites.

**Validation caveat:** The addition uses established Razi source
recipe/item IDs and guards their existence at data-final-fixes time,
but still requires a real Factorio 2.1 data-raw dump, recipe/surface
audit and savegame test before a public release. Some recipes will
intentionally not appear if upstream versions rename items or remove
a producer tech.

## Return cargo: Panglia, Crucible and the outer factory (2.1.24)

Two **optional intermediate items** give earlier planetary factories export
customers without introducing mandatory research gates:

- **Panglia Optic Bond:** Panglia glass + Moshine optical cable + Fulgoran
  holmium. Built as a portable intermediate and shipped into improved coil
  production at Paracelsin and rare-earth refinement at Linox.
- **Umbra Pressure Frame (Deep mode):** One Panglia bond, one Crucible
  high-pressure science pack, Vesta supermagnets and Linox rare-earth powder.
  The frame feeds guarded Vesta foundation production and an outer-to-Aquilo
  K2SO cryogenic-control alternative.

The four consumers only appear if their **native recipes, suppliers,
source research, science labs and legal manufacturing surface/machine**
all still exist. Each is an optional copy of an original process.
All source ingredients and byproducts remain unchanged; the added
component is *consumed*, batch bonuses are capped at 25%, and the
recipes cannot use productivity or auto-recycling.

The pressure frame is deliberately **not** made from active or unstable
Crucible hydrogen. Spoiling and source pressure-machine gameplay are left
alone. A native high-pressure science producer must exist first, and Deep
mode must be selected to build this part. If a mod update changes a
named supplier recipe, the affected collaboration does not register.

The two independent export lines do not require Razi's original Precision
Control Matrix: Panglia can still ship bonds if one unrelated supplier is
missing. The new six optional Codex milestones guide players through
building the Panglia bond, its two customers, the pressure frame and the
two late freight returns. These are not additional chapter travel gates.

As with the original network, a post-load Factorio prototype dump and
in-game check remain necessary to verify the actual mod versions installed.

## Economy tuning (2.1.25)

| Recipe family | Before | Tuned | Why |
| --- | --- | --- | --- |
| Panglia optical bonds | 2 per 8-second cycle | 8 per 10-second cycle | Freight material overhead is spread across many improved batches |
| Umbra pressure frames | 2 per 16-second cycle | 8 per 20-second cycle | A very late four-world component must be worth transporting |
| Panglia bond customers | 1 flat bonus / 4 native batches, 15% slower | About 20 to 25% more output, 10% slower | Real per-machine throughput improvement after the import |
| Umbra pressure-frame customers | 1 flat bonus / 4 batches, 20% slower | Output-scaled, at most 25% extra, 12% slower | Bulk Vesta foundation recipes otherwise lose throughput |
| Early Fulgora/Aquilo exchanges | Up to 75 to 100% gross bonus | Four native batches with a 20 to 25% guarded bonus | Eliminate unusually high early yield multipliers |
| Vesta foundation exchange | One native batch + five items | Four native batches with an output-scaled bonus capped at 25% | Avoid a 50% free-output multiplier |


- The two bond customers now cost **520 and 650** research units. The
  component research costs **360** instead of 520 units.
- The Deep pressure frame costs **980** research units rather than 1450;
  its Vesta/Aquilo consumers cost **960/1100** instead of 1900/1950.
- In the optional exchange engine, recipes without an explicit time
  multiplier now use a **15%**, rather than **30%**, machine-time
  surcharge. When a native recipe omits `energy_required`, Razi now
  follows Factorio's actual **0.5-second default** rather than
  assuming 1 second.
- Scaled bonuses are computed from the **current post-load native output
  amount**, with caps enforced afterwards. Mods that change native
  batch sizes should not silently break the reward math.

The numbers are tuned for positive *machine throughput*, not a guaranteed
total-resource profit. Actual cargo costs depend on the planet distances,
rocket capacity, production modules, power supply and material recycling.
Use `python3 scripts/audit_exchange_economy.py
script-output/data-raw-dump.json` to inspect the post-load math and
in-game freight trials to determine whether to expand a route.

## Tracking the freight network in Galactic Operations (2.1.27)

Open the space map's **Galactic Ops → Cargo** tab to inspect real
technology readiness for Precision Matrix, Panglia Optic Bond,
Extreme Lattice and Umbra Pressure Frame. The upstream worlds and known
downstream factory upgrades are grouped by component. Missing optional
research is omitted and the Deep-only component appears only when its
technology is actually installed.

Choose **View sources and recipe** to inspect loaded ingredient amounts,
recipe output and specific outstanding technology prerequisites. The
overview deliberately does not claim factories are operating or cargo
has been delivered just because a research objective is complete.
Actual Planet Express cargo and fleet schedules remain owned by that mod.

## Codex-linked industrial navigation (2.1.28)

The Cargo Network dashboard can now open eleven established Codex
milestones, including the Panglia Optic Bond and Umbra Pressure Frame
chains. The matching Codex pages have a shortcut back to the specific
Cargo component and selected downstream technology. Only installed and
visible technologies with existing quests have return links.

The dashboard reads force research and source prototype recipe details;
it never claims factory production or freight delivery based on a quest,
and it does not operate Planet Express.
