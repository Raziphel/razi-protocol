# Optional community expansion compatibility, October 2026

This pass covers the 16 specific mods proposed for Razi Protocol.
They are side-content and optional sources of unique materials and gameplay.
**No optional planet is required for any of the eight Razi system tech cards,
the seven-system campaign, or the base endgame.** None is allowed to replace
another mod's native science, enemy control, landing mechanic or specialized
factory. A successful static test does not prove that all mods load together.

| Mod portal ID | Status | Home or treatment | Safety and intended role |
| --- | --- | --- | --- |
| `Igrys` | Already integrated, recommended | Solaris | Native magical/glass industry, Razi local route and discovery. |
| `planet-rabbasca` | Already integrated, recommended | Gleba moon, Nyxaris | Preserves unique energy field, native orbit, hop limits, and research. |
| `foliax` | Already integrated, recommended | Nyxaris | Botany/arcane production stays source-authored. |
| `obsidiax` | Already integrated, recommended | Vespera | Frozen lava world retains rock growing and thermal mechanics. |
| `PlanetAthos` | Already integrated, optional | Solaris | Stone crushing and carbon loop; native science stays optional. |
| `rabbasca-underground` | Registered, native-only | Hidden Rabbasca stabilizer | A *non-space-accessible* traveling underground environment. Never add a launch corridor or reveal on the starmap. |
| `skewer_shattered_planet` | Registered, native-only | Original Shattered Planet endgame | Do not duplicate the Shattered Planet location, isotopes, or native science gates. Combined endgame requires live validation. |
| `Solar-Halo` | Registered, native-only, discovery gate when present | Solar orbit and station | Keep the mod's `halo-solar-orbit` and `halo-solar-station` connection and flare asteroids; native Vulcanus entrance. |
| `planet-ferrum` | Guarded side-world integration | Vibrant; native Fulgora/Vulcanus routes | Remote-view-only artificial planet. Preserve choice-driven tech and native rare-earth bridges with Linox/Moshine; no forced landing. |
| `Velora` | Guarded moon integration | Gleba moon, Nyxaris | Original moon orbit, native enemy population, science and resource chain. Add a short connection only if missing. |
| `nulla` | Guarded moon integration | Aquilo moon, Vespera | Keep abandoned factory / drone challenge and native local route. No pre-Aquilo unlock. |
| `alchemy-khemia` | Guarded side-world integration | Vibrant chemistry branch | Source-authored glyphs, chemistry, brine tanks and crate logistics. Optional link to Paracelsin when no native in-system route exists. |
| `Arcanyx` | Guarded side-world integration | Umbra experimental branch | Voidcraft/Iridescent Industry and prism production untouched. Connect toward Tenebris only if no native local route exists. |
| `Hephaestus` | Registered, native-only | Original megastructure and warp routes | This mod is not a conventional planet. Avoid rewriting runtime surfaces and mass-relay routes without inspecting real output. |
| `biological-machines-planet-wit` | Guarded moon integration | Nauvis moon, Calidus | Never move Wit away from Nauvis; preserve its early space science, helium and electricity restrictions. |
| `biological-machines-planet-balack` | Guarded high-risk side-world integration | Vespera after Aquilo | Preserve original enormous asteroid traffic, promethium technology, fabrication and dangerous enemies. |

### Why these dependencies are optional

Rabbasca's original high-energy restriction, Ferrum's remotely controlled
factories, Wit changing *how space science is made*, Arcanyx's Voidcraft
dependency tree and alternative Shattered Planet gameplay are significant.
Requiring every mod in the core dependency list before confirming full game
load would risk making **Razi Protocol itself impossible to install**.
The five previously admitted mods keep their existing dependency status;
the eleven new additions are declared as Factorio optional dependencies
with known 2.1-compatible minimum versions. Download/enable any desired
side module in Factorio's Mod Manager. Razi then detects its prototypes.

### How travel and research are reconciled

For conventional worlds, the late data stage checks that the mod, source
planet, target system and relevant existing star technology are present.
It adds only an appropriate side connection when no native in-system
route exists. It adds the corresponding system/planet discovery prerequisite
to the **original unlock-space-location technology**, not a fabricated
replacement technology; preexisting/indirect prerequisites and cycles are
respected. A non-existent prototype is never instantiated.

Ferrum keeps its native Fulgora and Vulcanus connections and their
asteroid distributions. The Fulgora link stays at its native 10,000 km,
while the Vulcanus-to-Ferrum link is calibrated to 115,000 km now that
it crosses from Solaris to Vibrant; this closes a 10,000 km interstellar
shortcut without discarding native resource asteroids.
Its discovery technology may be chapter-gated but its
dynamic research choices are untouched. The moon trio (Velora, Nulla, Wit)
keep original orbital relationships. Balack keeps its original, hard
Aquilo-side hazardous path. Special worlds (Rabbasca Underground,
Hephaestus, Shattered) retain all native mechanisms and paths.
Solar Halo's unique flare route and solar station are never overwritten.

Late research naturally remains late: source original tech may require
promethium, an Aquilo visit or its own local production chain. Razi
never gives those ingredients or discoveries earlier. No new Razi science
pack requires items from these optional worlds.

### Source-specific compatibility risks

1. **Wit:** Source makes space science and asteroid collectors part of
   its own moon campaign. We must verify the initial Calidus tech-card
   bootstrap before enabling it in a recommended full pack.
2. **Balack:** Source's native promethium requirements and Shattered
   discovery changes interact with our Outer Frontier Mastery. Verify
   post-load research graphs; do not change its technology by guessing.
3. **Ferrum:** Its recipe unlock order depends on in-game choices; avoid
   injecting generic science or rewriting those choice rules. It already
   integrates with Linox and Moshine.
4. **Solar Halo:** Its sun orbit has dedicated flare asteroids. Do not
   apply an ordinary Razi asteroid profile to those native routes.
5. **Rabbasca Underground:** Underground warp surfaces cannot receive
   platforms. No orbital route is created.
6. **Hephaestus:** The author's shortcuts are controlled by its own
   technologies; audit their reachable star systems to rule out a
   premature interstellar bypass.
7. **Arcanyx:** Voidcraft, Iridescent Industry and associated assets
   are substantial. Treat it as optional until K2SO recipe collision
   tests pass.
8. **Shattered Planet extension:** It expands the existing endgame
   surface; do not duplicate it or assume its high-tier resources
   are compatible with Razi's singularity victory.

### Validation before an all-modpack release

Run Factorio 2.1 with just the required pack, then with each optional
world, then all eleven new options together. Export `data.raw`, run
`scripts/audit_prototypes.py`,
`scripts/audit_supply_chains.py`, and
`scripts/audit_route_distances.py`; confirm tech unlock names, visually
inspect the star map, and fly representative routes. Test a backed-up
late save as well as a fresh save. Check especially the science routes
noted above. Only then should a new entry be promoted from optional
to recommended or required.

### Sources

The requested mod pages and their original source links are at
`https://mods.factorio.com/mod/<mod-ID>`. Confirmed upstream source
repositories include:
- `benlaflen/planet-ferrum`
- `ackeri/Solar-Halo`
- `PizzaPlanner/rabbasca-underground`
- `bradythehuman/Biological-Machines`

All installed mod-specific art, recipes, resource tables and sound
files remain owned by their respective mods; none is copied into Razi.
