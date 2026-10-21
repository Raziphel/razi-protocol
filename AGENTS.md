# Repository development rules

## Conventional Commits (required)

Use [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) for all future commits, including those made by AI coding agents.

Format: `<type>(optional-scope)!: imperative summary`. Use `feat` for features, `fix` for bugs, `perf` for performance, `refactor` for behavior-preserving changes, and `docs`, `test`, `build`, `ci`, `chore`, or `revert` when appropriate. Use a scope for the actual subsystem, such as `starmap`, `journal`, `planets`, `progression`, or `compat`.

Examples:
- `feat(starmap): add asteroid belt hazards`
- `fix(journal): preserve scroll position`
- `perf(planets): reduce scripted event overhead`
- `chore(deps): refresh compatibility metadata`

Use `!` and, when needed, a `BREAKING CHANGE:` footer for backward-incompatible changes. Conventional SemVer tools interpret `fix` as patch, `feat` as minor, and breaking as major, but **do not assume a version bump or release occurs unless explicitly configured**. For Factorio releases, keep `info.json`, `changelog.txt`, compatibility and actual packaged artifacts in sync using the existing validated release process. Do not change unrelated release automation, rewrite history or add CI jobs just to adopt this convention. Preserve the repository's established developer guidance and tests.
