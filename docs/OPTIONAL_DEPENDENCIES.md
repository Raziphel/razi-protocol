# Dependency categories and optional companions (2.1.66)

The full audit now includes direct dependencies plus the upstream required graph, version-pin evidence and a repeatable API auditor. The human-readable review lives in
[Dependency Audit](DEPENDENCY_AUDIT.md) and the matching
[machine-readable ledger](../compat/dependency_policy.json).
Every manifest entry is reviewed; the contract is checked by
`tests/test_dependency_policy.py`.

| Category | Current direct entries |
| --- | ---: |
| Required | 48 |
| Recommended (`+`) | 9 |
| Optional (`?`) | 14 |
| Incompatible (`!`) | 22 |

## Recommended companions

These improve the full K2SO campaign, but do not belong on its
non-negotiable prerequisite chain:

- AAI Signal Transmission 0.6.0+: source-owned cross-world circuit relays
- Imersite Asteroids 1.3.0+: extra K2SO asteroid materials
- Planet Express 2.1.9+: automated interplanetary shipments
- Rocket Turrets Upgraded 2.1.1+: source-owned planetary turret tiers
- Celestial Weather Updated 1.5.1+: atmospheric visual effects
- Celestial Weather Additions 1.3.1+: extra planet atmospheres;
  requires Celestial Weather Updated upstream
- Frost Biters 2.3.0+: cold-world enemies, guarded by source presence
- Science Tab 1.13.0+: grouped science UI; Razi's cards fall back to
  Intermediate Products when it is absent
- Big Monsters 2.2.1+: source-owned enemy encounters

## Deliberately optional

FluxWorks remains at `? FluxWorks >= 0.2.12` until that
minimum is publicly available and its companion integration is
tested. Dea Dia and Pelagos remain opt-in due to absent native 2.1
releases. Outer Rim and Secretas orbit patches can compete over
source-authored routes; they remain opt-in. Smaller content branches
and the optional enemy compatibility families stay optional.

Nexus-Updated stays **required by the curated campaign profile**. It directly requires Nexus-Threat-Updated, so Razi no longer duplicates the exact same hard dependency. Similarly, K2 Dyson Sphere Rebalance requires the correct Dyson Sphere fork; Razi does not need to list it again. The standalone Nexus Bosses addon requires its own
enemy-mod stack, including Nexus Threat and Big Monsters, when
installed. It has an optional dependency on Razi, so directly
depending on Nexus Bosses here would risk a circular graph.

The `+` prefix signals a suggested install, not a guarantee
that a mod is safe to remove from a live save. Always back up
your save before changing the enabled mod list. GitHub Actions
remain manual-only.

## Historical note

The old optional-dependency audit removed dozens of unrelated
or unmaintained suggestions. This current policy does **not**
re-add those decorative dependencies. The remaining explicit
incompatibilities continue preventing known duplicate planets,
route overlays, and incompatible alternative endgames.
