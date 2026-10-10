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
