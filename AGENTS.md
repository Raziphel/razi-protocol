# Repository development rules

## Conventional Commits (required)

Use the [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) format for **all future Git commits**, including changes made by coding agents:

```text
<type>(optional-scope)!: short, imperative description
```

- Use `feat` for new functionality, `fix` for bugs, `perf` for performance, `refactor` for behavior-preserving restructuring, and `docs`, `test`, `build`, `ci`, `chore`, or `revert` as appropriate.
- Prefer meaningful scopes naming the affected subsystem. For example: `feat(starmap): add asteroid belt hazards`, `fix(journal): preserve chapter scroll position`, `chore(deps): update dependency metadata`.
- Mark incompatible changes with `!` in the header and explain them in a `BREAKING CHANGE:` footer when useful. Do not use breaking-change markers for routine updates.
- Keep the subject specific to the actual change; avoid vague subjects such as `update` or `fix stuff`. Group related changes without mixing unrelated work.
- Under standard semantic-version tooling, `fix` implies patch, `feat` implies minor, and `BREAKING CHANGE` or `!` implies major. **The message alone does not publish or bump a version**. Only the repository's explicitly configured, validated release workflow may tag, bump, or publish artifacts.
- Respect the current build, testing, release and deployment processes. Do not rewrite historical commits or add new GitHub Actions merely to adopt the convention.

For Factorio mods, coordinate versioned releases with `info.json`, `changelog.txt`, dependencies and Factorio compatibility; do not automatically publish mods from an unverified commit message.

Follow the repository's existing contributing guide, tests, and deployment policy when applicable.
