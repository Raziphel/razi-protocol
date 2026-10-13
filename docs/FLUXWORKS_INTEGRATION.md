# FluxWorks industrial companion (experimental)

FluxWorks 0.2.12+ is an **optional** industrial expansion for Razi Protocol. It is not another galaxy or science overhaul. Install FluxWorks plus FluxWorksAssets and its own required dependencies to play the additional factories, machines, materials and Flux-processing chains.

## Who owns what

- **Razi Protocol:** planet discovery, seven-system research gates, asteroid crossings, Shattered Planet space location, Journal, chapter cards, and overall ending.
- **FluxWorks:** machines, processing recipes, industrial components, four Flux spectra, specialist mastery projects, and phase/rift devices.
- **K2SO:** source-defined materials and its native research paths.

FluxWorks detects Razi automatically. Razi's dependency `? FluxWorks >= 0.2.12` establishes data-stage ordering: FluxWorks establishes its items, Razi adds the final campaign bridges. Do not make FluxWorks depend on Razi as well.

## Changes when both are installed

- No FluxWorks landable Shattered Planet conversion. The canonical space location is preserved.
- No independent FluxWorks victory, starter supplies, or shared world physics/spoilage/asteroid rewrites.
- Original Nauvis ore nodes remain. FluxWorks adds selected introductory deposits without scattering Flux ores across the pack's other planets.
- The four FluxWorks science packs are **optional specialist mastery research** in this profile. Extra domain-science costs are removed from ordinary FluxWorks technologies. Existing IDs are retained; the prototypes are not destroyed.
- FluxWorks' existing Space Age and K2SO industrial recipes stay available.
- Razi contributes guarded alternate recipes to four existing FluxWorks planetary technologies:

| Chapter | Existing FluxWorks technology | Razi recipe |
| --- | --- | --- |
| Solaris | `fw-vulcanus-industrial-symbiosis` | `razi-fw-solaris-cermet-foundry` |
| Nyxaris | `fw-gleba-regenerative-symbiosis` | `razi-fw-nyxaris-bioresin-culture` |
| Vibrant | `fw-fulgora-electromagnetic-symbiosis` | `razi-fw-vibrant-sensor-fabrication` |
| Vespera | `fw-aquilo-thermal-symbiosis` | `razi-fw-vespera-crystal-stabilization` |

These are alternate industrial processes, **not** extra prerequisites for reaching planets. Each process is added only when its product, ingredients, category, chapter discovery, and source technology exist. The source FluxWorks technology gains that chapter's discovery as a prerequisite when its recipe is available.

FluxWorks Rift Exchange remains available as an advanced reward but refuses item/fluid transfers before `razi-outer-frontier-mastery` has been researched. Both transfer start and completion check that rule.

## Code

- Razi bridge: `prototypes/compat/fluxworks.lua` invoked at the end of `data-final-fixes.lua`.
- FluxWorks companion switch: `prototypes/lib/companion-mode.lua`.
- FluxWorks standalone modules are retained and guarded instead of deleted.
- No changes to Razi's normal progression when FluxWorks is missing.

## Engine validation required

This integration still needs a full **Factorio 2.1 + K2SO + Razi** game load. Source-level review cannot substitute for prototype-building and practical save tests.

Check both configurations, with and without FluxWorks. Confirm:
1. No Shattered Planet prototype conflict, and no disabled Native/Razi victory.
2. A new Nauvis map has normal iron/copper/coal/stone and FluxWorks' intended specialty deposits.
3. All four new recipes have valid machines and reachable ingredient supply chains after their chapter discovery.
4. No chapter discovers a planet through FluxWorks' standalone Shattered Planet unlock effects.
5. Rift Exchange does not transfer before Outer Frontier Mastery and still works afterward.
6. FluxWorks mastery packs and projects remain optional and tech prerequisites are acyclic.
7. Test a **copy** of an existing save. A standalone FluxWorks save with a generated landable Shattered Planet cannot be assumed to migrate safely into the combined pack.

Do not add FluxWorks to the stable public Razi modpack until these checks pass.
