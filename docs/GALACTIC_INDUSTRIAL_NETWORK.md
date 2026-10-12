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

Production bonuses are capped at **25% of the native batch output**.
The native process is scaled to multiple batches, imported components
are consumed on top of that cost, and crafting requires **15% extra
time per base batch in Balanced** or **20% in Deep**. Productivity
modules and auto-recycling cannot multiply these gains.

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
