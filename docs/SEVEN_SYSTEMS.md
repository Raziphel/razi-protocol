# Seven-System Revamp: Implementation notes

**Development branch:** private `Raziphel/razi-protocol-dev` `main`. This update is **experimental** until tested inside Factorio 2.1.

## System layout

The galaxy has three parallel pairs surrounding Calidus and leading to Deep Space.

| Stage | Parallel A | Parallel B | Exit gate |
|---|---|---|---|
| Early | Solaris | Nyxaris | Both sets of frontier planet research |
| Middle | Vibrant | Vespera | Shchierbin + Maraxsis |
| Outer | Beetlejuice | Umbra | Frozeta + Vesta + Linox |
| Finale | Outer Frontier Mastery | Deep Space | Stable Singularity and Intergalactic Signal Lock |

### Main system ownership

* **Calidus:** Nauvis, Muluna; optional Eneas
* **Solaris:** Vulcanus, Castra, Arig, Hyarion, Tellus, Corrundum; recommended Igrys, optional Athos
* **Nyxaris:** Gleba, Moshine, Apia/Carnova, Panglia; recommended Foliax and Rabbasca (Gleba moon), optional Pelagos and Dea Dia
* **Vibrant:** Fulgora, Ribbonia, Paracelsin, Shchierbin; optional Cerys (Fulgora moon)
* **Vespera:** Muria, Aquilo, Rubia, Maraxsis; recommended Obsidiax
* **Beetlejuice:** Cubium, Linox, Secretas, Frozeta
* **Umbra:** Tenebris, Crucible and its orbit, Vesta; recommended Carna

### Physical routes

The physical layout is finalized by `prototypes/system/galaxy_layout.lua`,
called explicitly at the end of `data-final-fixes.lua` **after** optional
planet mods have finished positioning their worlds. This
prevents earlier per-planet updates from pulling stars back out of alignment.
The route table itself lives in `prototypes/system/route_reconcile.lua`.

Calidus is the left-hand anchor. Solaris/Nyxaris, Vibrant/Vespera, and
Beetlejuice/Umbra occupy three evenly spaced upper/lower columns. Deep Space
sits beyond the final column. Larger star-to-star orbit circles are hidden to
keep the starmap clean, while local planetary rings remain visible.

Razi-owned interstellar connections:

    Calidus <-> Solaris       Calidus <-> Nyxaris
    Solaris <-> Nyxaris       Solaris <-> Vibrant
    Nyxaris <-> Vespera       Vibrant <-> Vespera
    Vibrant <-> Beetlejuice   Vespera <-> Umbra
    Beetlejuice <-> Umbra

    Additional diagonals (available only after both endpoints unlock):
    Solaris <-> Vespera       Nyxaris <-> Vibrant
    Vibrant <-> Umbra         Vespera <-> Beetlejuice

Local branches remain connected inside their own systems, including:

    Solaris: Vulcanus -> Castra -> Arig/Hyarion -> Tellus -> Corrundum
    Nyxaris: Gleba | Moshine | Apia/Carnova | Panglia (+ Rabbasca / Foliax / Pelagos / Dea Dia)
    Vibrant: Fulgora | Ribbonia -> Paracelsin -> Shchierbin (+ Cerys)
    Vespera: Muria -> Aquilo -> Belt Inner -> Belt Outer -> Rubia -> Maraxsis
    Beetlejuice: Cubium -> Linox; Cubium -> Secretas -> Frozeta
    Umbra: Tenebris -> Crucible Orbit -> Belt Inner -> Belt Outer -> Vesta; Crucible Orbit -> Crucible (native)
    Outer edge: Secretas/Vesta -> Solar System Edge -> Aegis/Bellicos

Cross-system connections render as clean straight lines, without the
large solar-centered arcs that previously tangled the map. The diagonal
links are **not separate research shortcuts**: both endpoint slipstreams
must be researched before they can be used. Vibrant/Vespera require both
first-frontier chapters; Beetlejuice/Umbra require both middle-frontier
chapters. The Solar System Edge remains gated by Outer Frontier Mastery.

Both Solaris and Nyxaris discovery technologies unlock the shared Calidus
departure slipstream. Either branch can therefore be chosen first.

Razi's reconciliation pass only removes source routes where **both** endpoints belong to explicitly managed but different chapters. Unknown optional source-mod internals stay intact.

## Research source of truth

`prototypes/technology/seven_system_gates.lua` is deliberately the final technology-rule pass. Earlier per-planet and compatibility passes can still run, but the canonical chapter gate rules execute after them.

* Solaris and Nyxaris: Calidus research and Calidus card
* Vibrant and Vespera: both first-frontier cards plus Corrundum, Apia/Carnova, Moshine and Panglia discoveries
* Beetlejuice and Umbra: both second-frontier cards plus Shchierbin and Maraxsis discoveries
* Outer Frontier Mastery: both outer cards plus Frozeta, Vesta and Linox discoveries

The `*-discovery` technology IDs of existing systems were retained. New IDs are `vespera-discovery`, `umbra-discovery`, and `razi-outer-frontier-mastery`. The new science-card prototype IDs are `vespera-tech-card` and `umbra-tech-card`. Any later rework must keep those stable for existing saves.

## Known limits and follow-up work

1. **Real Factorio engine tests remain essential.** GitHub Actions validates Lua syntax/API and our mocked test routes but cannot independently load K2SO and dozens of planet mods.
2. Research graphs may have upstream constraints that differ from our assumptions. Run `scripts/audit_prototypes.py` against the full `--dump-data-raw` output and verify practical resource acquisition per chapter.
3. The two new star sprites reuse tinted/standard Razi graphics. Design distinct Vespera and Umbra star and card sprites after the orbital positions are approved visually.
4. Current native star positions and routes are adjusted only for the core pack. Optional mod compatibility matrices should be verified one by one.
5. **Do not merge into the public release repo** until full loading, a fresh playthrough and existing-save migration have been tested.
6. Follow Alex's collaboration suggestion: only small, guarded direct-dependency fixes belong in the integration layer, and upstream/source mod fixes should be preferred when reasonable.

## Asteroid hazards

The route difficulty now increases between the paired frontier tiers while preserving
source-mod asteroid resource species and curves. See the
[Asteroid Route Guide](ASTEROID_ROUTES.md) for the exact tier assignments and safety constraints.

## The two asteroid belts

Vespera's Debris Divide and Umbra's Shattered Divide are separate locations
and researched travel passages. Rubia requires the Vespera belt survey;
Vesta requires the Umbra belt survey. Source-mod custom asteroid resources
from retired direct paths are retained on the new dangerous crossings.
See [Asteroid Routes](ASTEROID_ROUTES.md).

## Research between individual planets

Individual destination technologies now integrate upstream planetary science,
including safe crosslinks between the parallel frontiers. Details and safety
limits are in [Interwoven Progression](INTERWOVEN_PROGRESSION.md).
