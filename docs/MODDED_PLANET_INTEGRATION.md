# Modded-planet manufacturing

I wanted the planet mods to trade their interesting materials, not just
iron and copper. These seven alternate production methods tie six of
those industries together. The original recipes still work.

| Native factory | Off-world source(s) | Existing source recipe | Specialized output | Native → exchange output |
| --- | --- | --- | --- | --- |
| Rubia | Paracelsin zinc plate, Moshine optical cable | `craptonite-casting` | Craptonite frame | 3 → 4, with concrete byproduct retained |
| Paracelsin | Moshine optical cable | `electric-coil` | Electric coil | 4 → 5 |
| Moshine | Paracelsin zinc solder | `silicon-cell` | Silicon cell | 4 → 5 |
| Linox | Moshine optical cable, Paracelsin zinc plate | `linox-recipe_rare-earth-refining` | Rare-earth powder | 4 → 5 |
| Vesta | Linox rare-earth powder, Moshine optical cable | `supermagnet` | Supermagnet | 3 → 4 |
| Tenebris | Paracelsin zinc rivets | `chitosan` | Chitosan | 8 → 10 |
| Rubia | Paracelsin electric coil, Moshine optical cable | `rubia-long-stack-inserter` | Long stack inserter | 3 → 4 |

**Production rewards:** Four of these methods add 25% output, three
approximately 33%, with imported parts and 30% more crafting time per base
batch. Some originals support productivity modules while the variants do
not, so the best option depends on throughput and local factory equipment.
These are *alternative trade-offs*, not guaranteed upgrades over every
existing late-game productivity setup.

**Research timing:** All exchange technologies require the source recipe's
**actual unlock technology**, every supplier's producer-recipe unlock (when
the recipe is disabled at startup), plus the destination and source
planets' discovery technologies. Earlier pair synergies use Solaris and
Nyxaris tech cards; outer specializations use Vibrant and Vespera.
The original recipe remains unlocked by its native technologies and is
never removed, overwritten, or modified. No new alternative is a science
ingredient or is included in a system discovery prerequisite.

**Local machinery and planet identity:** Rubia's wind-locked frothing and
returned concrete remain intact. Tenebris keeps chitin chemistry and its
pressure condition. Linox retains stone, sulfuric acid and its own
surface restriction. Vesta's supermagnet still consumes native electrolyte
and requires its gaseous atmosphere. Paracelsin coils remain in the
mechanical crafting category. Source-mod recycling, technologies,
environment restrictions and machines are untouched.

**Fail-closed behavior:** Each extra recipe is created only when its exact
source mod and supplier mods exist, its original recipe and output exist,
the required item and fluid prototypes are visible, source and supplier
recipe unlocks are available, and a suitable homeworld machine has adequate
fluid ports and valid surface conditions. Missing mod components make only
the affected new recipe disappear; the original recipe keeps working.
No modules or quality/productivity stacking may amplify the exchange
bonus; no automatic recycling is generated for them.

**Source recipes used:** [Rubia](https://github.com/LoupAndSnoop/rubia),
[Paracelsin](https://github.com/ag-game/Paracelsin),
[Moshine](https://github.com/snouz/Moshine),
[Linox](https://github.com/xeon0527/factorio_mod_planet_linox),
[Vesta](https://github.com/invisiblek/skewer_planet_vesta),
[Tenebris Prime](https://github.com/nicholasgower/tenebris-prime).
Version-dependent source changes can skip a bridge and should be
investigated, not patched by forcing arbitrary machine categories.

**Validation limits:** `tests/lua/test_modded_planet_exchanges.lua`
verifies the seven alternative recipes, unlocks, outputs, native preservation,
and source-missing guards. This does not establish complete modpack
playability. Run Factorio 2.1 with every required mod and confirm actual
ingredient production, native research, surface pressure, machine crafting,
and comparative cargo cost before balancing further.

### Ferrum, Wit and Balack

An additional guarded catalog expands the optional production network with
Ferrum rare-earth magnets, Wit's expensive late-stage accumulators, and
Balack radiation shielding. Original early space science and specialized
factory restrictions remain unchanged. See
[Community Expansions](COMMUNITY_EXPANSIONS.md#community-industrial-integration-ferrum-wit-and-balack).
