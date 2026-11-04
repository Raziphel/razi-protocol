# Contributing to Razi Protocol

## Branches

- `main` holds the released versions. CI publishes every merge that has a releasable commit to the mod portal.
- `dev` holds work for the next major version. It goes into `main` in one pull request when it is ready.
- New work goes on a branch, `feat/<name>` or `fix/<name>`, one feature or fix per branch, and into a pull request. Fixes for the released version go to `main`; after each release `main` is merged into `dev`.
- `main` and `dev` take no direct pushes and no force pushes. CI's release commits are the only exception.

## Commits and versions

See [Releases in the README](README.md#releases):

- commit subjects are conventional commits (`feat:`, `fix:`, `balance:`, `compat:`…), and the subject becomes the changelog line;
- never edit the version in `info.json` or `changelog.txt`: CI writes both when it releases.

## Before a pull request

1. Use the real prototype IDs, dependencies and callers of the source mods.
2. Keep saves working: no renamed settings, quest IDs, technologies or locations without a migration.
3. Change the English locale, translations and tests together with the code.
4. Run the tests: `tests/run.sh`, with RaziLib next to this folder and Lua 5.2 from `lua/setup.sh` of [factorio-mod-tools](https://github.com/GreenTech-Solutions/factorio-mod-tools). For changes to prototypes, the tech tree, the starmap or the UI, also load the game with the full mod set and an existing save.

## Where a file goes

| Folder | What goes there |
| --- | --- |
| `prototypes/fixes/<mod>/` | A mistake of another mod: a crash, a wrong value, a typo, missing data. `common/` when it spans several mods. The order is in `prototypes/fixes/init.lua` |
| `prototypes/compatibility/<mod>/` | Mods working together as they are meant to: homes of enemies, cards in the labs of other mods, gates |
| `prototypes/balance/<mod>/` | Amounts, prices, productivity. A recipe loop goes under `razi-resource-loops` (`prototypes/balance/resource_loops.lua`) |
| `prototypes/world/`, `technology/`, `industry/`, `difficulty/`, `ui/` | What this mod adds itself |
| `scripts/<topic>/` | The control stage, by topic. `scripts/compatibility/<mod>/` for another mod. Handlers register in `scripts/events/` |
| `lib/` | Read by both the data and the control stage |
| `settings/` | Settings, one file per group |

`<mod>` is the name from the `info.json` of that mod. `control.lua`, `settings.lua` and the `data*.lua` files hold only the order of calls.

A fix says what is broken and where, with `file:line` of the other mod. If the author did it on purpose, it is a balance decision of this mod: it goes to `balance/`, and its comment says so. A name that replaces a translated one keeps the original as a fallback, so other languages do not fall back to English.

Past about 500 lines a file is split by meaning. Moves and splits go in their own commits, without changes to the logic, and a data dump before and after has to be identical.

## Pull requests

- The title is a conventional commit.
- The description is a short list of what changes.
- CI (`check`: Lua 5.2 syntax, luacheck, emmylua_check against the Factorio API, `changelog.txt` format, Lua tests) must be green before merging.

## Story text

Story text is written in `locale/en/story-*.cfg` and tried in the game in writer mode. See [docs/writing-guide.md](docs/writing-guide.md); the list of slots is [docs/story-slots.md](docs/story-slots.md), built by `lua tools/story_slots.lua --write`.

## Writing a test

- A test must be able to fail. Run a new test without the change first and see it fail.
- A mock refuses what the game refuses. If the game raises on an unknown entity, the mock raises too; a mock that answers anything hides the crash.
- Check what the game does before writing it into a test: the [API docs](https://lua-api.factorio.com/latest/) or a run in the game.
- Expected values come from the design, not from the function under test.
- Never weaken, skip or delete a test to make a fix pass. A failing test may be wrong: check its setup first, and say in the pull request if you change it.

## Design rules

1. **Source mods own their content.** Use their real prototype IDs and mechanics; patch them only on purpose, with a comment saying why.
2. **Progression is meaningful, not circular.** Every required technology stays reachable with the labs, science, routes and prerequisites that exist. An installed world is researched before the gateways of the next star system (`prototypes/technology/gates/regional_research_bridges.lua`, worlds in `prototypes/world/systems/world_roster.lua`): the worlds of Solaris and Nyxaris before Vibrant and Vespera, those of Vibrant and Vespera before Beetlejuice and Umbra, those of Beetlejuice and Umbra before Outer Frontier Mastery. A world whose research would wait for its own gateway is skipped with a line in the log, not woven. With `razi-planetary-interdependence` off nothing is woven. The exceptions, with a reason each, are in `prototypes/world/systems/optional_worlds.lua`: Balack, Skewer Shattered, Rabbasca Underground, Eneas and Nexus stay off the path, and so do the science packs of Rabbasca and those mods; research outside the path may need such packs (the choice of the mod that owns it). Ferrum is woven, and the path may need its robotics pack. Dea Dia is on the path through the Nyxaris card in every mode.
3. **Travel routes are gameplay.** The starmap stays legible; danger and asteroid exposure show real route properties.
4. **The journal is honest.** Its progress tracks real research, discovery and construction.
5. **Save compatibility comes first.**
6. **Performance is a feature.** Prefer load-time data, bounded UI work and settings for heavy behaviour.
7. **Native Factorio readability over ornament.**
8. **Compatibility fails soft.** A missing optional mod skips only the affected feature; required dependencies are explicit in `info.json`.
9. **Respect upstream authors.** Keep attribution, do not copy unlicensed textures or code.

## Avoid

- Hard dependencies on optional mods.
- Duplicating source recipes or research.
- Fake research completion or quest rewards.
- Moving a planet without updating its routes.
- UI rebuilt every tick.
- Code that is not wired in.
