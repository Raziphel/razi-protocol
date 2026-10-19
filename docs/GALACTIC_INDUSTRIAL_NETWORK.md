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

## A.2: Source-aware transport infrastructure and platform logistics

The Cargo Network's existing Freight Desk now displays a read-only
infrastructure snapshot beside a selected route and each visible freight plan.
This is computed only when the player opens or refreshes the Journal; no
background polls or cross-surface entity searches run on ticks.

For each genuinely discovered and enabled route endpoint it checks:

- **Orbital Catapult hardware candidates:** known runtime entity prototype
  names matching the upstream `orbital-cannon` or `orbital-catapult` naming
  families, scoped to the player's force on an already-created planet surface.
  The name/type match is intentionally **heuristic**, not an upstream
  verified machine registry. Zero means none of those candidates were found;
  it does NOT prove no alternative native launcher exists. An uncreated
  surface or a missing recognized prototype yields **unknown**, never zero.
- **Docked built space platforms:** Factorio 2.1
  `LuaForce.get_space_platforms(location)`, including only valid visible
  built platforms with hubs and no deletion scheduled. Traveling vessels
  are not represented as currently orbiting.
- **Native cross-platform provision:** count of real space-platform hubs
  with `providing_to_other_platforms = true`, independently of whether
  Platform Logistics Overhaul is installed.
- **Operational planning:** docked platforms with no schedule records,
  plus literal vanilla `cargo-bay` entity counts on their surfaces. This
  is **not** a total of all custom/Various Cargo Bays capacity. A missing
  platform surface makes cargo-bay evidence unknown.
- **Optional companion recognition:** whether the
  `platform-logistics-overhaul` mod is actually installed. Razi does not
  read its internal transport queue or claim its pod deliveries.

The results are *observations*, never “ready for shipment”, “connected
catapult”, “powered launcher”, throughput, inventory at the machine, or
arrival receipts. No machine, shipping schedule, stored item or native
companion data is changed. Unresearched/hidden route endpoints are never
probed even if spoiler previews are allowed by the UI.

The source-aware probe and native engine view are implemented in
`scripts/razi_freight_infrastructure.lua`. Its read-only mock fixture is
`tests/lua/test_razi_freight_infrastructure.lua`, runnable with:
`luatex --luaonly tests/lua/test_razi_freight_infrastructure.lua`.

**Game validation required:** confirm exact real Orbital Catapult 0.15.0
entity prototype naming on both ends, visit a planet before/after surface
creation, compare platform sharing checkbox and schedules, test mixed
vanilla/custom cargo bays and save migration. Do not broaden heuristics
until source entity IDs or a stable remote API are confirmed.

Developer regression:
`luatex --luaonly tests/lua/test_razi_freight_orders.lua`
(or the supported Lua 5.2 runner). In-game verification remains required,
particularly when using Remote View, switching physical surfaces, changing
mod settings, and editing an established save.

## A.3: Engine-confirmed cargo-pod delivery history

The Cargo Network now keeps a separate, force-owned **observed cargo-pod
delivery** ledger. It subscribes only to Factorio 2.1's documented
`defines.events.on_cargo_pod_delivered_cargo`, which fires **after** the
engine deposits the cargo. Neither departure nor landing alone is enough.

- One event records a *delivery occurrence* on the pod's destination
  **planet**, only if that planet is an endpoint of a configured Razi
  regional/local Orbital Catapult corridor. The event's cargo pod must have
  a valid force and a valid planet surface.
- The saved record has a single count per force per recognized destination
  world and the latest **24** raw world/tick pairs. No inventory objects,
  player references, entity references or enormous item inventories are
  persisted. The list is size-limited for old-save longevity.
- The Journal displays totals and up to eight latest destination/tick
  observations **only for genuinely researched, visible and enabled
  corridor endpoints**. Disabling links or hiding future worlds reveals
  nothing. Unlocking a world may reveal previous recorded activity for
  that world. Different forces have isolated ledgers; native force merges
  preserve aggregate counters and trim merged history to 24 records.
- The selected Freight Desk route can show how many engine-confirmed
  pod delivery events occurred at each of its two worlds. These are two
  *independent destination totals*, **not deliveries along that route**.
  Manual catapult packing status, Skybridge and Convergence victories
  remain fully separate.
- On a migrated save the history naturally begins empty; there is no
  reliable way to reconstruct old deliveries without a recorded event.
  No periodic polling, cargo insertion or transport scheduling is added.

### Source-attribution boundary

A Factorio native cargo-pod delivery event does **not** report the
original planet, the item IDs/quantities, a Freight Desk order ID or the
responsible mod. Factorio documents that cargo-pod events can also be
raised for modded pods. Therefore the ledger is labeled *observed cargo-pod
activity*, **not Orbital Catapult shipments** or delivered contract units.
We do not use it to close any order, pay any reward, satisfy Project
Skybridge, or mark Convergence complete.

Orbital Catapult 0.15.0's public integration contract documents
`orbital-cannon-link` prototype declarations, but we have not verified a
stable per-launch/per-delivery remote API or event with cargo and route
provenance. Full Catapult-specific verified transport tracking is still
**blocked pending a verified upstream interface**, rather than using
world inventory deltas, guessed machine IDs or teleport detection.

### Acceptance and safety

Run locally (manual-only Check workflow, never scheduled automatically):

```sh
lua5.2 tests/lua/test_razi_freight_orders.lua
lua5.2 tests/lua/test_razi_freight_infrastructure.lua
lua5.2 tests/lua/test_razi_freight_receipts.lua
```

In Factorio 2.1, test a real rocket cargo delivery, a platform-to-world
pod delivery, a modded pod where applicable, a remote-view player,
a route whose other world is undiscovered, disabling both Razi link
groups, force merge, restart/migrated save, and a game with many
deliveries. Ensure the Journal's numbers represent **events**, never
items or completed orders, and compare its destination records to
real native events. A new save cannot infer older events.

## A.4: Galactic Logistics Command, integrated Journal folio

The Journal's existing Cargo Network reference has been reorganized into
four compact sections, **without** creating a separate always-on GUI or
changing source transport mechanics:

| Section | Contents | Evidence source |
| --- | --- | --- |
| Command | Number of researched corridors, saved packing plans, built/in-flight native space platforms and recent pod-delivery events | Discovered Razi corridor registry, existing per-player freight plans, Factorio platform state and `on_cargo_pod_delivered_cargo` records |
| Routes | Per-endpoint potential source launcher counts, docked platforms, native sharing flags, unscheduled vessels, vanilla cargo bays and observed destination pod events; explicit directional plan buttons | The A.2 read-only inspector and A.3 arrival history |
| Freight Desk | Directed route selector, item-count/stack planning, carried-inventory readiness, order priority and manual packed/unpacked/delete controls | Existing A.1 persisted player freight orders; no source cargo modification |
| Industry | Existing source-backed science/factory opportunities, installed companion notes, technology links and manufacturing guidance | `galactic_trade_catalog`, `razi_industry_portfolio`, native prototypes and research |

The **original order IDs and saved manual packing state are unchanged**.
Selecting a route in the Routes section validates it with the original
route authority and opens the Freight Desk with that route chosen.
Research-to-Industry links still open the appropriate factory chain,
not the top of an unrelated dashboard. All ship/platform, machine and
delivery data is read only when the relevant page is rendered, not on
ticks or in repeated per-order scans.

### UX and scrolling

The Cargo reference still uses one native
`razi_journal_project_reader` scroll pane. Each of the four sections
gets an independent `razi_scroll_context` (`cargo:overview`,
`cargo:routes`, `cargo:freight`, `cargo:industry`). Previously
scrolled sections restore their last known native vertical position
when reopened, rather than resetting on every button press. The
stored offsets are numbers inside the already existing per-player
Journal preference object; no migration of freight data is required.

The Freight Desk now uses a compact presentation that does not
repeat infrastructure/arrival evidence for each of 20 possible
plans. Routes and Command own those facts. The old full-page
catapult dossier was retired from the Industry reader, leaving the
manufacturing research and optional production upgrades intact.

On narrow resolutions the tab bar stacks vertically and route
endpoint details switch to a single column; smaller text and
source-backed statuses preserve legibility without large
decorative cards or duplicate progress metrics.

### Ownership and testing

A native delivery event does not reveal origin, shipment amount
or Orbital Catapult activity. The central view carefully calls
the data *observed pod deliveries at destinations*, never
completed Catapult orders or shipment throughput. A potential
launcher entity is not proof of a powered live endpoint. Neither
manual packing nor the new dashboard changes research,
Convergence, inventory, native platform schedules, contracts
or victory conditions.

Manual regression commands:

```sh
lua5.2 tests/lua/test_razi_freight_orders.lua
lua5.2 tests/lua/test_razi_freight_infrastructure.lua
lua5.2 tests/lua/test_razi_freight_receipts.lua
lua5.2 tests/lua/test_razi_logistics_command.lua
```

Also verify an established save with 20 orders; switching between
all four tabs at low resolution; reopening the former Industry
Codex link; hiding future corridors; a disabled catapult network;
A.3 receipts after an actual rocket/pod delivery; both Local and
Regional catapult options; and **scroll position while clicking
Freight add/remove/pack controls**. Static/mock tests do not
replace Factorio GUI, live modpack or multiplayer verification.

## A.5: Source-backed supply-chain planning

The Expedition Journal's Galactic Logistics Command now has a fifth,
responsive **Supply Chains** section. This is a real bill-of-materials
planner for installed optional industrial recipes, not an invented producer
database or automatic delivery system.

### Source and quantity rules

- The planner uses `razi_industry_portfolio.snapshot(force)` and the
  installed `LuaRecipePrototype.ingredients/products` arrays. Only a
  factory site's *actually discovered* planet and installed/visible
  source technology and recipe are shown. If a live per-force
  `LuaRecipe` is available, its ingredient/product quantities take
  precedence over the installed prototype's preview. This does not reveal
  a hidden destination just because spoilers are disabled.
- Choose a real recipe, enter **1–1000 crafts**, and recalculate exact
  recipe ingredient quantities. Multiple identical ingredient entries
  are merged. Deterministic, nonprobabilistic recipe outputs are also
  shown, without claiming factory throughput or productivity bonuses.
  The quantity is **per recipe craft**, not per machine or minute.
- Only physical, named item prototypes with whole, bounded quantities
  (1 to 1,000,000 items per order) can become manual freight orders.
  Fluids, quality-constrained inputs, probabilistic/ranged/ambiguous
  amounts and missing prototypes remain **read-only**. No conversion of
  fluids into made-up barrels occurs.
- A proposed **inbound Orbital Catapult corridor** appears only if it is
  currently configured, exists in the source manifest and *both*
  endpoints have their actual planet-discovery technology researched.
  A world without a direct corridor still has useful ingredient guidance.
- The selected **origin is a PLAYER CHOICE**, never a claim that the
  ingredient is manufactured there. The planner does not invent an
  upstream producing recipe/location, machine count, available stock,
  working catapult, transit time or delivery status.

### Freight Desk handoff

The player may stage one qualifying item or choose **Stage all eligible
item ingredients**. Staging adds exactly the computed amounts to the
existing per-player Freight Desk as ordinary, *unpacked* orders.
The existing route guard, item prototype guard and 20-order limit apply
to all entries. Bulk staging checks every specification and total queue
capacity **before writing anything**: either all eligible items are
queued or none. No partial batch, stock reservation, deletion, inventory
change or transfer occurs. The prior hand-edited Freight Desk draft is
preserved.

The UI saves only the chosen recipe, inbound route and validated craft
count in the existing per-player Journal preferences. It uses native
recipe drop-down selection and text-change events, and does not redraw
the Journal as a side effect of typing each character. Recalculate and
action buttons rebuild through the existing tab-scoped scroll
restoration. Selecting an invalid quantity invalidates the stored
count rather than reusing a previous valid amount.

Research **and the source recipe being enabled for the player's force**
remain required conditions for *creating* orders; a
discovered but not yet researched optional recipe can be previewed
without generating orders. The new system never unlocks source
technology, changes recipes or surfaces, grants items or marks
Convergence/Project freight contracts fulfilled.

### Validation and remaining scope

Manual tests (the Check workflow remains opt-in):

```sh
lua5.2 tests/lua/test_razi_supply_planner.lua
lua5.2 tests/lua/test_razi_freight_orders.lua
python3 -m unittest tests/test_razi_supply_planner_contract.py -v
```

Check an actual Factorio 2.1 campaign with several installed industrial
mods. Verify recipe dropdown names, per-craft totals, empty/missing
producer cases, settings with either catapult group off, fully-discovered
destination vs spoiler-hidden source, recipe tech not yet researched,
very large quantities, variable outputs, fluids, optional quality
requirements, save/reload preferences and narrow-screen tab scrolling.
Confirm one-click batch staging is atomic at the 20-order limit, that
hand-edited drafts stay intact, and that Freight Desk contains new plans
but no actual items.

**Not included:** automated supplier discovery, multihop platform
shipping, route cost optimization, verified item production, live machine
inventories, and shipment-by-shipment Catapult confirmation. These
require additional verified source interfaces and would belong to a
later, separately tested stage.

## A.6: Mixed-mode interplanetary supply-chain route planning

The existing **Supply Chains** folio now offers **real map topology**
alternatives from discovered departure planets to a source-backed
factory. It does not assume that the departure world actually produces
the requested items, or that a ship/catapult is staffed, fueled, powered
or automatically scheduled.

### Source authority and graph rules

- Space-platform legs are read from installed
  `prototypes.space_connection` entries. Native prototype
  `from`, `to`, `length` and `hidden` determine **mapped
  connectivity and actual length**, not an operating logistics service.
  Native space connections are presented as two platform-traversable
  directions. Traversal still depends on the player's ships, schedules,
  speed, asteroid defenses, cargo pads and underlying game rules.
- Catapult legs come **only** from the existing
  `razi_catapult_network.snapshot(force)` and are individually
  validated by `razi_freight_orders.route(force,id)`. A link is
  considered structurally usable only when installed, configured and
  the **real destination/source discoveries** are met. This is **not**
  verified launcher installation, working power or shipment telemetry.
- Waypoints, including intermediate star/space locations, must be
  **unlocked for the player's force** via
  `LuaForce.is_space_location_unlocked` (the source technology check is
  only a fallback for testing older API mocks). All location identities
  come from `prototypes.space_location`. Player-selectable origins
  are **discovered real planets** in `game.planets`, never stars,
  hidden future worlds or hardcoded guesses.
- The planner enumerates up to **four alternatives**, up to six legs,
  using a bounded search (1,600 explored edges, max 400 graph edges).
  It ranks found alternatives by fewer legs, fewer mode changes and
  fewer platform legs, then uses comparable mapped platform distance
  as a tie-breaker. Distances **exclude catapult legs**, which do not
  expose comparable km. No ETA, verified cargo capacity or automatic
  price is fabricated.
- Mode changes are explicitly labeled as **transfer required**.
  A platform leg is a request to manually arrange a capable actual
  space platform, not a new Planet Express schedule or a hidden Razi
  transport service. A Catapult leg requires native source-owned
  launcher infrastructure. Nothing creates routes or rewrites
  source connection prototypes.

### Durable manual manifests and research changes

The player chooses a starting planet and an alternative path. The
selected route ID signature must match the **exact currently displayed
sequence** before a manual itinerary can be saved; if a mod/version/
research change reorders or removes links, the route must be explicitly
chosen again.

A manifest includes one existing factory recipe, selected batch count,
up to 24 **eligible deterministic item ingredients**, their exact
quantities and the ordered native/catapult leg identities. It is
**read-only manual planning guidance** and is **NOT automatically
converted into Freight Desk orders**, because doing so across a
platform or intermediate transfer would invent stock availability and
shipment provenance. The A.5 direct Catapult Freight Desk handoff
remains available for genuine single-leg route plans.

At most **12** saved itineraries per player are retained as plain
serializable values. No LuaObject is stored. Manifests are revalidated
against the current route map and visible installed factory catalog
when displayed. Research, recipe-enabled status and exact eligible
ingredient quantities are also rechecked, so upstream recipe changes
cannot present stale bills of materials as current instructions. A
now-inaccessible plan is represented by a concealed stub with a delete
button so removed mods or rolled-back research do not leak old
waypoints/materials or strand save data.

Saved proposal rows are **collapsed by default**. Clicking a validated
row reveals its detailed travel steps and ingredient list; invalidated
proposals cannot be expanded and can always be deleted. Separate
tab-scoped scroll memory prevents a new planning action from jumping
the main Journal reading position. Removed players clean up their
own itinerary storage. This feature never updates contracts, Project
Skybridge, Convergence or victory.

### Cost and performance boundaries

The graph is rebuilt **only when the Supply Chains tab is rendered
or the player uses its controls**. There is no per-tick polling,
inventory scan, platform creation, movement or remote transport API
call. Each readable saved manifest shares one factory catalog
snapshot rather than triggering another full catalog read per plan.

Manual-only tests (no automatically triggered GitHub Actions):

```sh
lua5.2 tests/lua/test_razi_supply_routes.lua
lua5.2 tests/lua/test_razi_supply_multihop.lua
lua5.2 tests/lua/test_razi_supply_planner.lua
lua5.2 tests/lua/test_razi_freight_orders.lua
```

**Full Factorio testing remains required**: traverse real native
multi-star links and local Razi Catapult corridors, test spoiler
locks on intermediate waypoints, disabled link groups, a missing
planet mod, player removal, force changes, a save with 12 manifests
and low-resolution scrolling. Inspect actual native connection
directionality, asteroid risks, space platform schedules and
infrastructure requirements. Neither static fixtures nor a drawn
route establish successful or possible live deliveries.
