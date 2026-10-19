## 2.1.68: Return freight rewards for system-card factories

Beetlejuice and Umbra now join Solaris, Nyxaris, Vibrant, Vespera and Deep
Space in offering Razi-owned freight-assisted science-card production.
Beetlejuice uses Gold from Secretas and rare earths from Linox; Umbra uses
Tenebris chitosan, Vesta supermagnets and Linox rare earths. Every optional
recipe requires the original science-card ingredients in full plus imports.

These production alternatives are 4:5 material batches with a 25% gross
output bonus and 15% extra time compared with four normal batches.
Neither first-discovery science nor mandatory source cards change. The
Campaign panel shows whether each alternative is actually installed and
unlocked. The existing native production and logistics systems remain
source-owned.

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

Transport integrations and remaining candidates:
- **Orbital Catapult >=0.15.0 now required** by Razi Protocol 3.0,
  with the upstream author's recommended `~` dependency prefix, to avoid
  forcing a problematic load order. It provides operational powered
  catapults and source-owned handling for item/player transportation.
  Razi registers three deliberately short **two-way Vespera corridors**
  using six one-way link prototypes: Muria–Aquilo, Muria–Rubia and
  Rubia–Aquilo. Original Muria–Aquilo IDs are unchanged for old saves.
  Catapults complement normal space platforms, **not** replace their
  routes. The existing startup option
  `razi-orbital-catapult-local-links` now defaults ON and can disable
  all six Razi lanes without uninstalling the source mod. No native
  research, recipes, planet discoveries, surface restrictions or
  Convergence shipments are rewritten. Player travel via catapult
  is possible as defined by the original mod: check native
  progression safety in-game before a public release.
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

## Orbital Catapult: required Vespera local freight (3.0)

**Source:** [Orbital Catapult](https://mods.factorio.com/mod/orbital-cannon)
by Frontrider, 0.15.0+; original MIT-licensed transport behavior is
unmodified. The mod has its own required dependencies, including
`powered-machine`, which the Factorio mod portal resolves automatically.

| Source | Destination | Return route | Role |
|---|---|---|---|
| Muria | Aquilo | Aquilo → Muria | Existing cryogenic resupply |
| Muria | Rubia | Rubia → Muria | Nearby industrial transfers |
| Rubia | Aquilo | Aquilo → Rubia | Direct material/cold-chain exchanges |

Every row represents two separate `orbital-cannon-link` records.
Register during `data.lua`, only when both planet prototypes exist.
The source mod consumes registered links in its final-fixes phase,
after Razi's system positions are defined. Leave `mods["orbital-cannon"]`
checks to guard data-stage injection, but the metadata now requires
the mod with `~ orbital-cannon >= 0.15.0`: the tilde is intentional
and follows the source author's load-order warning.

The same **startup setting ID** remains; it is now **ON by default**.
Changing it requires restarting Factorio. OFF removes Razi's six
declared corridors and keeps the source mod installed for any other
compatible mod's lanes. Native space-platform routes remain independent.

The existing Expedition Journal provides nearby-world dossiers for
Muria, Rubia and Aquilo, encouraging discovery and infrastructure rather
than inventing a new research requirement or counting catapult activity
as completed Convergence freight. Catapult inventory/request throughput,
electricity, planet placements and any player transfer require real
Factorio 2.1 testing. Do **not** mark native planet discovery complete
merely by registering a directed transport lane.

## Vespera regional freight dossier (3.0 follow-through)

The required Orbital Catapult now has an integrated, **read-only**
regional freight guide inside Expedition Journal > Projects > Cargo Network.
It reads the same six directional prototypes registered in
`prototypes/compat/orbital_catapult.lua`. Each pair is deduplicated
into a single short-haul opportunity. Route suggestions are purpose-built:

| Regional route | Suggested engineering role |
|---|---|
| Muria ⇄ Aquilo | Support the cryogenic supply chain with nearby manufacturing. |
| Muria ⇄ Rubia | Exchange finished materials locally rather than routing every small load by platform. |
| Rubia ⇄ Aquilo | Stage cryogenic and advanced-materials logistics after native production is established. |

The guide reports the actual planet discovery technology **research state**,
not catapult placement, freight throughput, shipped items, active receivers
or proof of player arrival. With Hide Spoilers ON, it conceals a corridor
until **both** native discovery researches are completed, preventing the
Cargo page from naming unexplored planets. Disable spoiler hiding to preview
all installed links, but do not confuse the preview with an unlock.

World dossiers for Muria, Rubia and Aquilo also show discovered neighboring
corridors. The feature adds **no new technology, power bonuses, recipes,
items, surfaces, planets, routes outside Vespera, or simulation loops**.
The source Orbital Catapult mod still owns circuit handling, machine
placement, transport, players and inventories.

The read-only dossier is evaluated only when opening/rebuilding the Journal,
not every game tick. Missing optional planets remove only their affected
entries, and the old links keep their original names. New testing lives in
`tests/lua/test_razi_catapult_network.lua` and
`tests/test_razi_catapult_network.py`.

## Orbital Catapult, regional deployment expansion

The second freight layer now adds six more directional link prototypes
(three reversible local corridors), controlled by the new startup setting
`razi-orbital-catapult-regional-links`, ON by default and independent
of the original `razi-orbital-catapult-local-links` switch.

| System | Bidirectional transport link | Suggested industrial use |
|---|---|---|
| Solaris | Vulcanus ⇄ Castra | Local foundry output and salvage resupply |
| Nyxaris | Gleba ⇄ Moshine | Short-haul biological manufacturing and analytical machinery |
| Vespera | Rubia ⇄ Maraxsis | Industrial supplies for native underwater development |

When both settings are on, **six corridors / twelve directed catapult
links** are exported through the source mod's documented
`orbital-cannon-link` interface. Turning off the new regional option
restores the previous three Vespera corridors; turning off the original
option leaves only the three new ones. Neither setting removes the
required Orbital Catapult mod.

This is **actual transport network integration**, not merely a Journal
guide. The original mod still supplies its real powered launchers, item
and player transportation, logistics mechanics, costs and restrictions.
Nothing here auto-places a machine, creates free freight, bypasses
native planet research, rewrites crafting or routes across a star.
Catapults still require working endpoint infrastructure.

The Cargo Network now groups researched corridors under Solaris,
Nyxaris and Vespera, with their intended practical role. Existing
Journal dossiers for Vulcanus, Castra, Gleba, Moshine, Muria, Rubia,
Aquilo and Maraxsis contain relevant local freight guidance.
With Hide Spoilers ON, the UI does not name a lane until both native
destination-discovery research milestones are complete; the underlying
Factorio link prototypes are not a substitute for the native source's
transport accessibility checks.

**Pre-release gate:** test a loaded Factorio 2.1 world with all source
planets installed, including Maraxsis's actual launch environment,
surface restrictions, power, return links, item/player arrival and
rocket/platform parity. Test existing saves with both toggles ON/OFF.
The upstream source mod does not provide general freight telemetry to
this integration. We must not report live shipments until measured.

## Freight Desk: operational packing plans (3.0)

The regional Orbital Catapult dashboard now has a **Freight Desk**.
This is an actual interactive planning tool inside Expedition Journal
→ Projects → Cargo Network, not just prose about route geometry.

Players can select either direction of any **already discovered**
and currently enabled catapult corridor, choose a **real item** from
Factorio's item picker and enter the desired item quantity. The
Freight Desk calculates the number of inventory stacks from the
live `prototypes.item[item].stack_size` (including item-stack changes
from the installed modpack). It shows the player's real carried
item count alongside the order and provides controls to mark an order
packed/unpacked or delete it.

The queue is **per-player**, save-persistent, limited to 20 orders and
1,000,000 items per order, and cleaned up when a player is removed.
Only strings, numbers and booleans are saved, not Lua game objects.
Route permissions use native planet-discovery research, the existing
two independent corridor switches and the same source-backed route
manifest as the actual catapult link definitions. Spoilers cannot
reveal undiscovered endpoints through saved plans.

This is intentionally **not** an auto-shipping system. Razi does not
reserve materials, alter the source mod's transport machinery, manipulate
catapult inventories, fabricate launch/delivery receipts, add free items,
skip recipe costs or claim a completed Convergence shipment. Packing
status is user-entered, while inventory numbers are strictly the
player's own inventory, not a factory's or a catapult's contents.
Update counts with the existing Journal refresh action.

**Next potential integration:** machine counts, real throughput or
remote dispatch would require documenting and testing a stable API
provided by Orbital Catapult itself. We deliberately avoid guessed
entity IDs and experimental remote calls in this release.

### Razi 3.0: live departure-stock checks (Pass A foundation)

The Freight Desk additionally checks the player's actual physical departure
planet and their **currently carried** stock. Pending orders of the same
item compete for the same stock in saved priority order. This prevents two
plans from each claiming readiness against the same inventory. Players can
move an order up/down to change which pending shipment gets the available
materials first.

Each visible order is classified as **ready to pack**, **short**, **on a
different world**, **manually packed**, or **unable to check**. The combined
readiness line shows the count in each of the first four states. "Ready"
is an inventory estimate only, not proof of loading or launch. The
existing packed checkbox remains explicitly manual, never a claim of
verified transport. No items are removed or reserved.

Plans concealed by undiscovered worlds, disabled corridors or removed
item prototypes remain saved and spoiler-safe. The UI lets players delete
each inaccessible order by an opaque ID, even when no corridor is visible,
so the 20-order queue cannot become permanently blocked. Removed plans
are not re-created if research or settings change later.

This layer is read-only with respect to every source mod; it does not
touch rocket/platform schedules, cargo pods, orbital launcher inventories,
destination delivery counts or victory rules. Existing orders need no save
migration. There are no background scans: the check runs when the freight
board is rendered or manually refreshed.

Developer regression:
`luatex --luaonly tests/lua/test_razi_freight_orders.lua`
(or the supported Lua 5.2 runner). In-game verification remains required,
particularly when using Remote View, switching physical surfaces, changing
mod settings, and editing an established save.

