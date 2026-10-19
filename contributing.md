# Contributing to Razi Protocol

## Branches

| Branch | What it is | How it changes |
| --- | --- | --- |
| `main` | the released 2.1.x line; every merge with a releasable commit is published by CI | pull requests from `fix/<name>` branches, merged with a merge commit |
| `dev` | Razi Protocol 3.0 in progress | pull requests from `feat/<name>` or `fix/<name>` branches, squash merged |
| `dev-full-sync-history` | the 3.0 work as one long history, kept to port from | read only |

- One feature or one fix per branch. Commits inside a branch are free; only the pull request title has to be a good commit message.
- A fix for released players goes to `main` first. After the release, `dev` is fast-forwarded to `main`, or `main` is merged into `dev` once they have diverged.
- Apart from CI's release commits and that fast-forward, `main` and `dev` take no direct pushes, and never a force push.
- 3.0 reaches `main` in one pull request from `dev`, with `BREAKING CHANGE:` in the merge message.

## Commits and versions

See [Releases in the README](README.md#releases). In short:

- commit subjects and pull request titles are conventional commits (`feat:`, `fix:`, `balance:`, `compat:`…), and the subject becomes the changelog line;
- never edit the version in `info.json` or `changelog.txt`: CI writes both when it releases.

## Workflow

1. Identify the player problem and the intended change. Prefer one coherent fix over unrelated experimental changes.
2. Inspect the real source prototype IDs, mod dependencies and callers before patching a route, research chain or journal definition.
3. Respect existing saves: do not casually rename setting keys, quest IDs or technologies.
4. Update English locale text, translations and focused tests together with the code.
5. Run the affected tests locally. When the change touches prototypes, tech trees, the starmap or UI, also load the game with the full mod set, load an existing save, and check the behaviour in game.
6. Describe what was checked, what could not be checked, and any migration or compatibility consequences.

## Design invariants

1. **Source mods own their content.** Use their real prototype IDs and mechanics; patch them only on purpose, with a comment saying why.
2. **Progression is meaningful, not circular.** Every required technology stays reachable with the labs, science, routes and prerequisites that exist. Optional worlds must not silently become mandatory.
3. **Travel routes are gameplay.** Keep the starmap legible; danger and asteroid exposure show real route properties.
4. **Narrative is honest.** Journal progress tracks real research, discovery and construction.
5. **Save compatibility comes first.** No renamed quest IDs, settings, technologies, locations or saved keys without a migration.
6. **Performance is a feature.** Prefer load-time data, bounded UI work and settings for heavy behaviour.
7. **Quiet visual hierarchy.** Native Factorio readability over ornament.
8. **Compatibility fails soft.** A missing optional mod skips only the affected feature; required dependencies are explicit in `info.json`.
9. **Test intent, not only syntax.** Fixtures on a mocked `data.raw` do not replace loading the game: check what the change does with the real mods.
10. **Respect upstream authors.** Keep attribution, do not copy unlicensed textures or code, document why an override exists.

## Pull requests

The description states:

- **player impact**;
- **implementation rationale**;
- **source-mod compatibility**;
- **save impact**;
- **tests run**;
- **manual verification still needed**.

Screenshots help for map and UI changes. Do not claim in-game verification from static checks alone.

CI (`check`) runs on every pull request: Lua 5.2 syntax, luacheck, emmylua_check against the Factorio API, and the `changelog.txt` format. A pull request is merged only when it is green.

## Changes to avoid

- Undocumented hard dependencies on optional mods.
- Duplicating source recipes or research.
- Fake research completion or quest rewards.
- Moving a planet without updating its routes and tests.
- Runtime UI rebuilt every tick.
- Breaking setting keys or save migrations without a plan.
- Code that is not wired in, kept for later.
- Documents that log each step; the history is in git and the pull request descriptions.
