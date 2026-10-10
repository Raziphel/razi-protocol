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
