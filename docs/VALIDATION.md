# Razi Protocol validation

## Automated on every private main push / pull request

The GitHub Check workflow runs the existing Factorio Lua lint and syntax
checks, a small set of compatibility Lua fixture tests, and the post-load
prototype auditor's Python unit tests. These checks do not require owning or
downloading Factorio on GitHub Actions.

## Validate the actual modpack in Factorio

Static checks cannot know the final prototype state after every dependency
has run its data stages. For each supported configuration:

1. Enable the exact mod combination you want to release with.
2. Run Factorio with --dump-data-raw, which writes
   script-output/data-raw-dump.json into the Factorio write-data directory.
3. In this repository run:

       python3 scripts/audit_prototypes.py /path/to/script-output/data-raw-dump.json

The auditor checks:

- missing and cyclic technology prerequisites
- whether one lab accepts every science ingredient for each Razi campaign tech
- all eight system cards and their recipe unlocks
- space-connection endpoints
- physical routes from Nauvis to the seven major system hubs

To check specific optional planets, pass --required-location planet-name,
repeating the flag for additional planets. For an experimental map with
different hub semantics, pass --no-campaign-route-checks to disable only the
hard-coded campaign reachability requirement; route endpoint validation remains.

Suggested smoke-test configurations:

- Required-only Factorio 2.1 pack (the release baseline)
- Required pack with all seven system gates unlocked and Outer Frontier Mastery completed
- Required pack + Nexus-Updated
- Required pack + supported optional planets such as Cerys or Eneas
- Required pack + each optional enemy family
- All compatible optional integrations together, where releases exist

The auditor cannot prove that an in-game resource chain is economically
craftable or that activation events will fire. Still test a fresh game, an
existing save migration, and the singularity transceiver in-game. In
particular, checking the technology graph alone does not prove every recipe
has producible materials.

These full-engine modpack tests are manual until a Factorio binary and legal
dependency staging are available to CI.

For the new progression, explicitly test two independent first-tier entry choices,
both second-tier branches, both third-tier branches, the Muria/Aquilo and
Tenebris/Crucible travel paths, and an unmodified Aegis/Bellicos expedition.
The new Lua fixtures verify structural intent only: they cannot prove resource
craftability or that parent star coordinates render cleanly in Factorio.

The interwoven progression fixture additionally checks science technology
prerequisites, complete-lab compatibility, cyclic and absent dependencies,
and repeat-pass stability. The full pack must still be tested in-game.

## Recipe-unlock and source-planet reachability audit

The post-load prototype auditor now checks a second dependency graph that
research prerequisite checks alone miss: **which technology unlocks the
recipes that produce each mandatory System Tech Card ingredient**. If every
source recipe is locked behind the very research consuming that card, it
reports a hard science-supply deadlock. The audit also finds card recipe
ingredient cycles and checks known source-planet science against the
consumer's transitive planet-discovery prerequisites.

The interwoven science module now declines to add an optional science-pack
cost when every available recipe producing that pack unlocks only at or
after the consuming discovery technology. It retains the normal predecessor
research milestone, avoiding an artificial lock on the actual ingredient.

This only establishes *logical availability*. It cannot establish fuel,
electricity, resources, special crafting events, surface placement or input
transport without a complete enabled-modpack Factorio dump and a gameplay
smoke test.

## Linox hard-mode integration with the outer system

Linox's optional `linox-settings_hard-mode_enable-science-pack_aquilo`
setting can insert `linox-item_linox-science-pack` into pre-Linox
Aquilo-era technologies. Linox itself moved into Beetlejuice, and cannot
supply that pack until its discovery and native production are unlocked.
Razi now strips that ingredient only from the prerequisite ancestry of
`beetlejuice-discovery`, `umbra-discovery` and Linox's own landing
discovery. This keeps all required entrances feasible while leaving later
Linox hard-mode recipes and technologies untouched.

The source-planet ancestry assertion is restricted to **Razi campaign
milestones**. Independent K2SO/third-party technologies can legitimately
consume imported System Tech Cards without having every source-world
planet discovery as a direct prerequisite. Such use is not a deadlock.

## Late-world exclusive-science bootstrap

Crucible is originally designed to be visitable before Aquilo and can modify
Aquilo-tier research. Razi now places Crucible in Umbra. The guarded
`outer_science_arrival_guard.lua` removes Crucible's own science/tech-card
cost only from the prerequisite chain that unlocks Crucible, and similarly
prevents Vesta's gas science from blocking Vesta discovery. Native post-arrival
research keeps these exclusive science requirements. The guard runs only
with the relevant world and K2SO enabled, and avoids an empty tech-cost
prototype by using an already-valid early science fallback when available.
A live full-modpack prototype dump must still verify all native revisions.

## Aquilo, Linox, Crucible and Vesta supply-chain report

A separate nested producer-chain report now examines the installed
post-load modpack for the four most sensitive worlds and the Outer Frontier:

    python3 scripts/audit_supply_chains.py /path/to/script-output/data-raw-dump.json
    python3 scripts/audit_supply_chains.py /path/to/script-output/data-raw-dump.json --json

The report checks **before** each discovery whether its research science has
a recipe path whose producer recipes are unlocked by prior technologies, and
**after** arrival whether important native/K2SO products have a traceable
recipe ingredient chain. It resolves multiple producer recipes, mined inputs,
technology-unlock effects, recipe surface conditions and machine categories.
The JSON includes the chosen recipe, its nested dependencies and blockers,
so a precise compatibility rule can be written instead of globally changing
a planet's resources.

Interpreting status:

- `traceable`: an apparent recipe path exists, not a gameplay guarantee
- `natural-source-unverified`: some mineable prototype produces the material,
  but **its presence on the current world has not been established**
- `blocked`: no path within the research and machine snapshot under the
  stated assumptions; review the nested unlock/surface/machine reason
- `unresolved`/`unverified`/`depth-limit`: insufficient proof, not a hard error

The report is intentionally advisory and does not make a green GitHub
Actions fixture run stand in for a real Factorio game load. Source mods can
grant material through starting inventory, script events, asteroid routing,
spoiling or remote supply. In particular, researching an independent branch
outside a tech's formal prerequisites is possible, so a recipe listed as
locked in its strict ancestor snapshot is **not necessarily** impossible.
A real data dump and targeted in-game playtest determine which alerts need
patches.

### Specific source interaction

Crucible's upstream author documents that its mod changes some Aquilo-era
technologies and supports K2SO natively. Razi places Crucible after Aquilo,
so `outer_science_arrival_guard.lua` ensures Crucible science cannot appear
in research needed to reach Aquilo, Umbra or Crucible. Vesta's gas science is
treated similarly. Only late-world-exclusive science is removed from those
pre-arrival milestones; native science needed after arrival remains in place.
See `tests/lua/test_outer_science_arrival_guard.lua`.

The recipe-chain tracer explicitly distinguishes recipes locked *behind*
the destination (`future-unlock`, a likely deadlock) from recipes unlocked by
independent technologies outside the snapshot's prerequisite ancestry
(`independent-research`, not enough evidence to call impossible).
