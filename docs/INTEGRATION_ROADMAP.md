# Integration and Expansion Roadmap

This roadmap tracks **what still needs real implementation or in-engine
verification** after the first cleanup pass. It is not a release changelog.

## Phase 1: Compatibility cleanup (implemented in private main)

- [x] Retire conflicting Muria route/orbit overrides
- [x] Preserve vanilla enemy spawns when no optional enemy prototype exists
- [x] Add isolated K2SO research-trigger compatibility regression fixtures
- [x] Extend legacy recipe-output detection for migration guards
- [x] Register the known cross-mod patches and their review status
- [x] Add recipe, recycling, research-trigger and surface-condition diagnostics
- [x] Detect system-card recipe-unlock deadlocks in post-load prototype dumps
- [x] Add planet field guide as a future Informatron content source

## Phase 2: Validate required-mod progression (blocking for release)

- [ ] Start Factorio 2.1 with the **exact required** modpack and capture data.raw
- [ ] Run both prototype audits, review errors and all advisory warnings
- [ ] Confirm every expected planet has actual unlock-space-location coverage
- [ ] Confirm the seven-system map has no disconnected or unintentional routes
- [ ] Confirm each science card's ingredients can be produced before first use
- [x] Add a pre-/post-arrival nested recipe-chain audit for Aquilo, Linox, Crucible and Vesta
- [ ] Review the full-modpack output of scripts/audit_supply_chains.py and fix proven blockers
- [ ] Verify native Apia/Carnova and Aegis/Bellicos connections in the live game
- [ ] Test a fresh save and a **backed-up** existing campaign migration

## Phase 3: Work with Alex on dependency fixes

- [ ] Compare Alex's recipe-unlock fixes to our current compat modules
- [ ] Compare recycling changes and surface/building restrictions by mod version
- [ ] Record concrete upstream issue/PR links for every confirmed workaround
- [ ] Eliminate verified redundant patches only after testing replacement behavior
- [ ] Add regression fixtures for each accepted ported fix
- [ ] Preserve author attribution and avoid bundling copied source mod assets

## Phase 4: Weather and enemies

- [ ] Verify Celestial Weather 2.1 fork behavior on Muria, Rubia, Paracelsin, Vesta and Panglia
- [ ] Inspect Pelagos weather only when the optional mod is installed
- [ ] Document actual warning signs and severity, not guessed hazards
- [ ] Review enemy spawn and evolution curves in each inhabited environment
- [ ] Respect startup setting to disable Razi custom enemy routing entirely

## Phase 5: In-game encyclopedia

- [ ] Verify current Informatron 2.1 remote API and compatible optional load behavior
- [ ] Convert the Planet Field Guide into system and planet pages
- [ ] Include source credits, unlock prerequisites, native environments and verified weather
- [ ] Never expose a science pack or planet as required when its mod is optional

## Phase 6: Expansion slots for older planet mods

- [ ] Review each candidate's Factorio 2.1 support and exact mod ID
- [ ] Evaluate the planet's unique gameplay and appropriate stellar parent
- [ ] Review source-mod dependencies, recycling, surface conditions and enemy controls
- [ ] Verify source ownership of native travel routes and technology unlock effects
- [ ] Add guarded integration and fixture tests before making the dependency required

## Phase 7: Six additional planet destinations

- [x] Screen 2.1 candidates for distinct gameplay, updates and compatibility
- [x] Add five mature recommendations and experimental optional Athos
- [x] Attach guarded planet travel, star ownership, and native discovery gates
- [x] Preserve Rabbasca's Gleba moon orbit and native source links
- [x] Add isolated regression fixtures for absent mods and research cycles
- [ ] Run each recommended planet with actual Factorio 2.1 + K2SO
- [ ] Run the all-recommended combination and check modded machine restrictions
- [ ] Test Asteroid defenses and the normal seven-system tech card victory
- [ ] Verify Athos before recommending it by default

## Release condition

A green GitHub Actions run means **source checks and isolated fixtures passed**.
It does not mean the game loads. A release is blocked until the required-mod
Factorio 2.1 world, old-save migration and supported optional integrations
pass in-engine testing.

## Phase 8: Staged asteroid hazards

- [x] Profile Razi-owned routes from mild launches through high-risk Deep Space approaches
- [x] Preserve modded asteroid species, their native spawn curves, and source-owned internal travel routes
- [x] Use region-specific hazards for newly added optional planet connections
- [x] Add regression tests for custom asteroid preservation and deterministic duplicate-route handling
- [ ] Validate actual asteroid and resource composition in the full Factorio 2.1 modpack
- [ ] Playtest ammunition, shielding and throughput on representative ships in each frontier

## Phase 9: Real asteroid belt corridors

- [x] Make Calidus small-only, including existing moon routes and orbits
- [x] Add hard size ceilings for the first and second frontiers
- [x] Add Vespera and Umbra belt rim locations and survey technologies
- [x] Replace direct Aquilo/Rubia and Crucible/Vesta shortcuts with crossings
- [x] Preserve modded asteroid resource types on retired direct routes
- [x] Test giant-asteroid introductions only in the late dangerous belt
- [ ] Design unique starmap sprites for both debris belts after a live map review
- [ ] Fly and benchmark both belts with the full Factorio 2.1 modpack
