# Razi Protocol settings

Choose **Settings → Mod settings**. Most gameplay and starmap options are **Startup** settings and apply after reload. Journal visibility and welcome controls are **Per-user**; spoiler fog is **Map-wide** and applies immediately.

The defaults are designed for the main expedition. Optional performance experiments start **off**. Fragment and enemy reductions also change balance, not just visuals.

## Find Razi startup settings sooner

Factorio orders mod settings by mod load order, chiefly dependency-chain
depth. Prefixing Razi Protocol's visible title or moving its settings into
RAZI Library does not put them first. RAZI Library 1.3.1 restores the library's
passive behavior and no longer registers Protocol settings.

The optional [early-loading settings companion](../companion/00-razi-protocol-settings/README.md)
(version **1.1.0** or newer) imports Razi Protocol's current startup definitions
and registers them under its own short-dependency section, which may appear
near the beginning of the Startup tab. Razi Protocol itself keeps **Map** and
**Per-player** settings; those must remain writable at runtime. No setting
identifiers or values change. Without the companion, the ordinary Razi
Protocol section works as before. Placement must be verified in Factorio.

## Quick recommendations

- **First playthrough:** Keep the standard settings, especially curated routes, interdependence = Balanced and ten-level asteroid difficulty = Balanced.
- **Performance:** Try cosmetic particle reductions before changing asteroid fragments or spawn density. Compact route graphics target map rendering, not platform UPS.
- **Fewer spoilers:** Leave the shared spoiler fog on; disable its other-mod extension if another mod dynamically edits research visibility.
- **Minimal interface:** Hide the Journal button and/or pinned-objective tracker per player; Ctrl+Shift+J still opens the Journal.
- **Existing saves:** Back up before switching research, recipe, enemy-generation or connection settings.

## Complete settings reference

Existing setting IDs and defaults are preserved. The early-loading `00-razi-protocol-settings` companion mirrors the exact same IDs, types and tooltips.

### Expedition & Story

| Setting | Effect |
| --- | --- |
| Hide future discoveries | Hide unreached research and Journal chapters. Available discoveries stay visible. Shared by the whole map; changes apply immediately. |
| Include other mods' research | Also hide future research from other mods. Turn off if a mod manages its own tech visibility. Requires Hide future discoveries. |

### Welcome & Interface

| Setting | Effect |
| --- | --- |
| Clear new-game startup chat | Clear the console once at the start of a new map. Also removes other mods' startup messages and warnings; later chat stays untouched. |
| Show welcome briefing | Show your first-visit expedition briefing with Journal, wiki and Discord links. Use /razi-welcome to read it again. |
| Show Journal shortcut button | Show the gold Journal shortcut in the top-left. The Ctrl+Shift+J shortcut still works when hidden. Personal setting; instant. |
| Show pinned-objective tracker | Show the sidebar for pinned Journal objectives. Hiding it keeps your pinned objective. Personal setting; instant. |

### Worlds & Encounters

| Setting | Effect |
| --- | --- |
| Place modded enemies by world | Place supported enemy factions on fitting worlds. Off restores source-mod placement. Only newly generated terrain is affected. |
| Enable quality asteroids | Spawn higher-quality asteroids along the 10-level threat scale. Home routes stay safe; outer routes offer greater risk and rewards. |
| Asteroid difficulty | Balanced preserves the intended 10-level progression; Challenging and Relentless increase danger on advanced routes. |
| Asteroid population | Change hostile asteroid frequency on Razi-curated routes: 65%, 100%, 130% or 160%. Does not change asteroid types. |
| Belt combat intensity | Scale extra large asteroid encounters in Razi's belt crossings: 50%, 100% or 150%. Native encounters are unchanged. |
| Belt ore richness | Scale Razi-added belt ore to 60%, 100% or 150%. Other planets and original asteroid mining are unchanged. |
| Mid-belt salvage | Add harvestable ore to the dangerous middle of Razi belt crossings. Off keeps the original resource layout. |
| Safe-edge harvesting | Add passive ore harvesting at safer belt edges. Off makes belt trips more dependent on combat. |

### Performance

| Setting | Effect |
| --- | --- |
| Reduce asteroid impact particles | Reduce cosmetic asteroid impact particles. May improve FPS, not necessarily UPS. Gameplay and resource drops stay intact. Off by default. |
| Reduce weapon impact particles | Reduce cosmetic projectile and beam particles. Damage is unchanged; some weapon effects look simpler. Off by default. |
| Fewer asteroid fragments | Reduce native chunks released by destroyed large asteroids. Lowers entity counts AND resource yields. Off by default. |
| Reduce outer-route hostiles | Reduce hostile asteroid spawns by 28% on level 8-10 routes. Makes the outer galaxy easier. Off by default. |
| Reduce space explosion smoke | Reduce cosmetic smoke in space explosions. Damage and sounds remain; visuals may be plainer. Off by default. |
| Reduce asteroid creation dust | Reduce cosmetic dust when asteroids spawn. Real asteroids and quality rolls stay unchanged. Off by default. |
| Simplify colored route lines | Use fewer precomputed route-line sprites. Saves map graphics work but makes some curves less smooth. Does not affect UPS. Off by default. |

### Industrial Integration

| Setting | Effect |
| --- | --- |
| Planetary interdependence | Off removes optional Razi trade and science links; Balanced is intended; Deep adds import-heavy recipes. Core progression remains. |
| K2SO trade recipes | Add optional interplanetary recipes using K2SO materials. Off leaves source recipes and mandatory research intact. |
| Modded-planet trade recipes | Add optional manufacturing links among supported planet mods. Off leaves their original recipes untouched. |
| Spread technology unlocks | Tie selected robots, nuclear and companion research to appropriate planetary science. Off keeps source unlocks. |
| Companion technology integration | Connect supported rail and shield research to regional science when all prerequisites exist. Off keeps source technologies. |
| Vespera catapult routes | Add two-way freight links among Muria, Rubia and Aquilo. Uses Orbital Catapult's normal machines and costs. |
| Regional catapult routes | Add short two-way catapult links in Solaris, Nyxaris and Vespera. Does not bypass asteroid belts. |
| Repair distant route lengths | Correct unusually short travel distances on faraway source routes. Off retains the source mods' distances. |

### Stellar Projects

| Setting | Effect |
| --- | --- |
| Dyson research integration | Link later Dyson upgrades to regional research milestones. Native Dyson machinery and output remain unchanged. |
| Calidus Dyson orbit layout | Arrange the source Dyson orbit locations in compact rings around Calidus. Visual placement only. |

### Quality & Navigation

| Setting | Effect |
| --- | --- |
| Hide duplicate assemblers | Hide duplicate tier-4 assemblers already covered by K2SO. Off keeps the source mods' machines and unlocks. |
| Add expedition descriptions | Add short system notes to original planet descriptions. Off restores the original descriptions. Text only. |
| Group barrel recipes | Move verified fill/empty barrel recipes into a Fluids group. Recipes and crafting are unchanged. |
| Group spoilable recipes | Put single-output spoilable intermediates in their own group. Experimental; does not change spoil timers. |
| Colored route lines | Off uses native lines; Danger colors routes by level 1-10; Chapter adds chapter styling. Routes stay clickable. |
| Colored route coverage | All colors every verified route; Major colors only main corridors and belt crossings. Missing geometry stays native. |
| Use curated space routes | Use Razi's intended interplanetary connections while retaining essential source routes. Off keeps source-mod extras. |
| Detailed route tooltips | Add distance, hazards, harvestable chunks and ship advice to route tooltips. Travel itself is unchanged. |
| Route line brightness | Change colored route opacity: Soft, Standard or Bright. Native connections remain visible and clickable. |
| Route curve detail | Economy draws fewer curve points; Smooth draws more. Standard balances line quality and map graphics cost. |
| Show danger level | Show each route's danger rating on the 1-10 scale in tooltips. |
| Show asteroid sizes | Identify the largest hostile asteroid expected on a route. |
| Show harvestable chunks | List collectible asteroid chunk types along each route. |
| Show ship preparation tips | Include suggested ship defenses for hazardous routes. |
| Show unknown hazard warnings | Warn when a source mod's asteroid hazards cannot be determined. |
| Mark belt crossings | Identify required asteroid belt crossings in route tooltips. |
| Show star-system names | Identify a route's origin and destination star systems. |
| Show long-haul routes | Flag long-distance cargo journeys in route tooltips. |

### Galaxy Visuals

| Setting | Effect |
| --- | --- |
| Galaxy background style | Off keeps the native sky; Subtle adds restrained scenery; Cinematic uses richer accents. Cosmetic only. |
| Orbit ring density | Full draws all native planet rings; Balanced and Clean draw fewer; Off hides Razi-managed rings. |
| Show star halos | Show faint color glows around star systems. Does not alter map positions. |
| Show belt dust | Show thin dust rings around the real asteroid belts. Hazards remain unchanged. |
| Soften Bellicos glare | Dim excess Bellicos pulsar glare while keeping its recognizable shape. |
| Show distant star details | Show sparse background stars beyond the main planetary systems. |
| Show nebula pockets | Show a few faint nebula pockets between the main systems. |
| Show subtle star flecks | Show tiny, low-opacity star flecks for extra sky texture. |
| Show Calidus chart detail | Add a small observatory-style star chart near Calidus. Off by default. |
| Star brightness | Adjust background star brightness; does not affect gameplay. |
| Halo brightness | Adjust star-system halo brightness; does not affect gameplay. |
| Belt dust brightness | Adjust belt dust brightness; asteroid encounters are unchanged. |
| Nebula brightness | Adjust small nebula and dust accents; does not affect gameplay. |

## Compatibility

The optional first-in-list companion owns the settings only when installed. Otherwise Razi Protocol defines them itself. Keep companion files and its distributable ZIP synchronized using `python3 tools/build_settings_companion.py`. Factorio determines cross-mod settings order; no text prefix can guarantee the top position.

All settings are available in English and Russian. The UI section names are visual labels, not extra settings.
