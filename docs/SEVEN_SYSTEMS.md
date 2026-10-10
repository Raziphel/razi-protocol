# Seven-System Revamp: Implementation notes

**Development branch:** private \`Raziphel/razi-protocol-dev\` \`main\`. This update is **experimental** until tested inside Factorio 2.1.

## System layout

The galaxy has three parallel pairs surrounding Calidus and leading to Deep Space.

| Stage | Parallel A | Parallel B | Exit gate |
|---|---|---|---|
| Early | Solaris | Nyxaris | Both sets of frontier planet research |
| Middle | Vibrant | Vespera | Shchierbin + Maraxsis |
| Outer | Beetlejuice | Umbra | Frozeta + Vesta + Linox |
| Finale | Outer Frontier Mastery | Deep Space | Stable Singularity and Intergalactic Signal Lock |

### Main system ownership

* **Calidus:** Nauvis, Vulcanus, Fulgora, Gleba, Muluna; optional Cerys and Eneas
* **Solaris:** Castra, Arig, Hyarion, Tellus, Corrundum
* **Nyxaris:** Moshine, Apia/Carnova, Panglia; optional Pelagos and Dea Dia
* **Vibrant:** Ribbonia, Paracelsin, Shchierbin
* **Vespera:** Muria, Aquilo, Rubia, Maraxsis
* **Beetlejuice:** Cubium, Linox, Secretas, Frozeta
* **Umbra:** Tenebris, Crucible and its orbit, Vesta

### Physical routes

The final route tables are in \`prototypes/system/route_reconcile.lua\`. Razi-owned interstellar connections:

    Calidus <-> Solaris       Calidus <-> Nyxaris
    Solaris <-> Nyxaris       Solaris <-> Vibrant
    Nyxaris <-> Vespera       Vibrant <-> Vespera
    Vibrant <-> Beetlejuice   Vespera <-> Umbra
    Beetlejuice <-> Umbra

Local branches remain connected inside their own systems, including:

    Solaris: Castra -> Arig/Hyarion -> Tellus -> Corrundum
    Nyxaris: Moshine | Apia/Carnova | Panglia (+ Pelagos / Dea Dia)
    Vibrant: Ribbonia -> Paracelsin -> Shchierbin
    Vespera: Muria -> Aquilo -> Rubia -> Maraxsis
    Beetlejuice: Cubium -> Linox; Cubium -> Secretas -> Frozeta
    Umbra: Tenebris -> Crucible Orbit -> Vesta; Crucible Orbit -> Crucible (native)
    Outer edge: Secretas/Vesta -> Solar System Edge -> Aegis/Bellicos

Razi's reconciliation pass only removes source routes where **both** endpoints belong to explicitly managed but different chapters. Unknown optional source-mod internals stay intact.

## Research source of truth

\`prototypes/technology/seven_system_gates.lua\` is deliberately the final technology-rule pass. Earlier per-planet and compatibility passes can still run, but the canonical chapter gate rules execute after them.

* Solaris and Nyxaris: Calidus research and Calidus card
* Vibrant and Vespera: both first-frontier cards plus Corrundum, Apia/Carnova, Moshine and Panglia discoveries
* Beetlejuice and Umbra: both second-frontier cards plus Shchierbin and Maraxsis discoveries
* Outer Frontier Mastery: both outer cards plus Frozeta, Vesta and Linox discoveries

The \`*-discovery\` technology IDs of existing systems were retained. New IDs are \`vespera-discovery\`, \`umbra-discovery\`, and \`razi-outer-frontier-mastery\`. The new science-card prototype IDs are \`vespera-tech-card\` and \`umbra-tech-card\`. Any later rework must keep those stable for existing saves.

## Known limits and follow-up work

1. **Real Factorio engine tests remain essential.** GitHub Actions validates Lua syntax/API and our mocked test routes but cannot independently load K2SO and dozens of planet mods.
2. Research graphs may have upstream constraints that differ from our assumptions. Run \`scripts/audit_prototypes.py\` against the full \`--dump-data-raw\` output and verify practical resource acquisition per chapter.
3. The two new star sprites reuse tinted/standard Razi graphics. Design distinct Vespera and Umbra star and card sprites after the orbital positions are approved visually.
4. Current native star positions and routes are adjusted only for the core pack. Optional mod compatibility matrices should be verified one by one.
5. **Do not merge into the public release repo** until full loading, a fresh playthrough and existing-save migration have been tested.
6. Follow Alex's collaboration suggestion: only small, guarded direct-dependency fixes belong in the integration layer, and upstream/source mod fixes should be preferred when reasonable.
