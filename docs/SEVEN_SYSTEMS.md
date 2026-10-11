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

## Distance calibration: Razi's final starmap

Factorio space-connection `length` is measured in **kilometres**. Starmap
`orbit.distance` is a layout coordinate rather than real astronomical scale,
so the following are gameplay distances chosen to broadly follow the visual
map, increasing ship capacity, native planet behavior, and asteroid profiles.

| Travel | Previous | Updated |
| --- | ---: | ---: |
| Calidus to Solaris / Nyxaris | 60,000 / 65,000 | unchanged |
| Solaris to Nyxaris (first paired stars) | 32,000 | **88,000** |
| Solaris/Nyxaris to middle star (straight) | 95,000 | unchanged |
| First to middle star (diagonal) | 116,000 | **142,000** |
| Vibrant to Vespera (middle paired stars) | 38,000 | **103,000** |
| Middle to outer star (straight) | 130,000 | unchanged |
| Middle to outer star (diagonal) | 148,000 | **174,000** |
| Beetlejuice to Umbra (outer paired stars) | 45,000 | **126,000** |
| Secretas to Solar System Edge | 75,000 | **155,000** |
| Vesta to Solar System Edge | 75,000 | **185,000** |

The old 23,000 km direct **Vesta to Secretas** cross-star route is removed.
It gave a shortcut around Umbra's surveyed asteroid belt. Players retain
several interstellar star-hub routes, including the Beetlejuice/Umbra direct
crosslink and the appropriate progression-gated diagonals.

### Local routes and native intent

Ordinary planetary legs remain roughly 10,000 to 25,000 km, including the
Asteroid Belt segments. Castra's hub and the longer Hyarion branch have been
adjusted to reflect their final positions. Ribbonia's approach and the
Paracelsin/Shchierbin chemical frontier are now spaced progressively.

Razi's route reconciler prefers an already-existing original connection name
and preserves source asteroid resources. It now also preserves a **native
route's original length** when that length falls within 75% to 135% of the
planned local chapter distance. Far-outside lengths are bounded, not copied
blindly. This keeps the author's 20,000 km Maraxsis journey intact and stops
an obsolete 1,000 km connection from trivializing a moved outer planet.
Special source-owned internal routes, such as Crucible's short orbital hop
and Dea Dia's internal links, are not part of this normalization at all.

The two belt cores remain **6,500 km** (Vespera) and **8,000 km** (Umbra).
Their escalating challenge is encounter density and asteroid size, not
artificially inflated travel time. Bellicos/Aegis and optional endgame routes
are also deliberately not normalized.

The post-load checker `scripts/audit_route_distances.py` compares interstellar
km against resolved parent-orbit geometry, warns on inexplicable short hops,
checks staged travel growth, duplicates and removed-belt shortcuts. CI uses
the canonical Razi route manifest and final starmap anchors as fixtures.

## October 2026 optional community destinations

New guarded late-addition paths use native moon, special surface and
solar-station handling. Ferrum and Khemia join Vibrant's electrically and
chemically focused worlds; Arcanyx joins Umbra's experimental side branches;
Velora stays Gleba's moon and Nulla stays Aquilo's moon. Balack remains a
dangerous post-Aquilo destination inside Vespera. Wit stays near Nauvis.
Solar Halo and Rabbasca Underground retain their source-owned layouts.

Native authors' unusual worlds are not flattened into Razi's standard
asteroid patterns. For the exact list, safety checks and unresolved
full-modpack tests see [Community Expansions](COMMUNITY_EXPANSIONS.md).
