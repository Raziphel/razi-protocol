# Required worlds and interplanetary bridge roadmap

## Installation policy (October 2026)

Razi Protocol now requires **14 formerly optional/recommended conventional
planet or moon mods** with known Factorio 2.1 releases, including Cerys,
Eneas, Igrys, Rabbasca, Foliax, Obsidiax, Carna, Athos, Velora, Nulla,
Khemia, Arcanyx, Wit and Balack. This brings those worlds into the same
installed campaign as the existing core Planetaris/K2SO planets.

**Three conventional worlds cannot safely be promoted yet:**

- `dea-dia-system`: current official portal release targets Factorio 2.0.
- `pelagos`: current official portal release targets Factorio 2.0.
- `planet-ferrum`: Razi's optional minimum (0.1.4) currently exceeds the
  discoverable Factorio 2.1 release (0.1.3); confirm a compatible version
  before making it required.

The above three remain optional, with guarded Razi integrations.
Nexus and Void Processing are separate, substantial endgame branches;
Hephaestus, Solar Halo and Rabbasca Underground have specialized nonplanet
location mechanics. None of those are silently made ordinary planets.

Cerys and Eneas are genuine moons. Preserve their native mechanics,
discovery, and orbital connections. Rabbasca, Velora, Wit and Nulla likewise
retain their native parent worlds. Do not move the unique Cerys nuclear
puzzle behind a manufactured Razi science bottleneck.

The base and Space Age engine minimum is 2.1.20, as required by recent
Cerys builds. Installed optional world version floors for Foliax and
Rabbasca were lowered to public 2.1 releases documented by the portal;
source API and whole-pack load still need validation.

## Endgame planetary unification

`prototypes/technology/planetary_unification.lua` indexes the original
technology `unlock-space-location` effects in one pass. The final
`razi-stable-intergalactic-singularity` tech then inherits discoverable
world technologies for the recognized Razi planets/moons. This makes
native world discoveries matter at the final milestone **without**
introducing new multi-pack research recipes or blocking earlier exploration.

It checks the live technology graph and never creates a dependency cycle.
If a mod's discovery tech is absent, hidden, disabled or locked after
the finale, that world is not forcibly added. This limitation is
intentional to prevent a broken game: the data-raw graph and source mods
must be validated before asserting 100% coverage. Researching discovery
technology is not the same thing as physically visiting the planet.

The source recipes, special world mechanics, surface restrictions and
all pre-existing tech names stay intact. No scripts are added to the
runtime tick loop.

## Non-planet mods worth adapting into real bridges

1. **Planet Express** (`planet-express`, 2.1): existing real-platform
   cargo dispatch, two-way shipments, reserved stock and destination
   allowlists. Adapt into Razi Galactic Operations with source-driven
   supply hints, research-aware access and belt-aware routing.
2. **Space Age Galore** (`space_age_galore`, 2.1): broad source recipe
   catalog for planet materials. Curate only well-verified multi-planet
   process variants rather than importing hundreds of undifferentiated
   recipes. Avoid collisions with K2SO and Razi exchange bonuses.
3. **Rocket Turrets Upgraded** (`upgraded-rocket-turrets`, 2.1):
   native Vulcanus/Fulgora/Aquilo/orbit crafting locations form a
   platform-defense equipment ladder. Adapt later tiers with Castra,
   Rubia and Linox logistics without buffing early turret damage.
4. **Cerys Lunaponics** (`cerys-lunaponics`): greenhouse-based wood
   production on Cerys. Could form a bio/industry link with Gleba,
   Foliax and Nyxaris, protecting Cerys's native scarcity puzzles.
5. **Inter Platform Logistics** (`Inter-Platform-Logistics`, 2.1):
   optional same-orbit ship-to-ship relay challenges. Most of its
   core behavior exists in vanilla 2.1, so only use its extra
   thresholds/antenna ideas where they materially improve logistics.

These are **research candidates, not new required dependencies**. Before
shipping an adaptation, inspect upstream licences, prototype IDs, runtime
interfaces and server-side costs. No copy-pasting third-party source
into Razi by default.

## Safety/performance contract

- Keep the opening pair of stars accessible from Calidus.
- Do not create new hard prerequisites to *visit* a world that require
  materials from that world or its descendants.
- Native author technology/progression wins over generic Razi gating.
- Keep the two surveyed asteroid barriers and native hazardous routes.
- All world-science/recipe changes must pass full 2.1
  `--dump-data-raw`, `scripts/audit_supply_chains.py` and at least
  one fresh-save/test-save manual playthrough.
- No new planets, image assets, extra background scripts or duplicate
  GitHub Actions jobs were introduced in this pass.
