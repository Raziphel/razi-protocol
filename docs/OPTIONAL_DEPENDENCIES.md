# Dependency categories and optional companions (2.1.79)

The full audit now includes direct dependencies plus the upstream required graph, version-pin evidence and a repeatable API auditor. The human-readable review lives in
[Dependency Audit](DEPENDENCY_AUDIT.md) and the matching
[machine-readable ledger](../compat/dependency_policy.json).
Every manifest entry is reviewed; the contract is checked by
`tests/test_dependency_policy.py`.

| Category | Current direct entries |
| --- | ---: |
| Required | 48 |
| Recommended (`+`) | 24 |
| Optional (`?`) | 2 |
| Hidden optional (`(?)`) | 1 |
| Incompatible (`!`) | 22 |

## Recommended companions

These improve the full K2SO campaign, but do not belong on its
non-negotiable prerequisite chain:

- AAI Signal Transmission 0.6.0+: source-owned cross-world circuit relays
- Imersite Asteroids 1.3.0+: extra K2SO asteroid materials
- Planet Express 2.1.9+: automated interplanetary shipments
- Rocket Turrets Upgraded 2.1.1+: source-owned planetary turret tiers
- Celestial Weather Next 1.6.0+: combined core weather and planetary additions
- Frost Biters 2.3.0+: cold-world enemies, guarded by source presence
- Science Tab 1.13.0+: grouped science UI; Razi's cards fall back to
  Intermediate Products when it is absent
- Big Monsters 2.2.1+: source-owned enemy encounters
- Frozeta: Nuclear Winter 1.12.1+: self-contained Frozeta progression and original hard-dependency stack; no Outer Rim required

## Orbital and industry companions (October 2026)

See [Frontier Companions](FRONTIER_COMPANIONS.md) for the source-owned
research weave, Catapult opt-in rules and full in-game test matrix.

Six Factorio 2.1 mods are advertised as **recommended**, not required.
Each belongs to a concrete gameplay niche without replacing Razi's
original star map, courier freight rules, tech cards or endgame:

| Recommended mod | Role | Razi integration |
| --- | --- | --- |
| [Various Cargo Bays](https://mods.factorio.com/mod/Various_Cargo_Bays) 1.1.0+ | Throughput-specialized pod bays and storage bays | Source recipes untouched; Cargo Network companion field notes |
| [Space Age Railway Expansion](https://mods.factorio.com/mod/space-age-railway-expansion) 0.0.18+ | Nuclear/fusion rail progression | Source-checked optional research weave, guard-skips unavailable labs |
| [Shield Generators](https://mods.factorio.com/mod/shield-generators) 0.7.0+ | Base and turret shields | Late superconducting-shield science integration only when resolvable |
| [Circuit Launchable Rockets](https://mods.factorio.com/mod/CircuitLaunchableRockets) 1.4.6+ | Physical automated launches | Preserve native launcher behavior and settings |
| [Cargo Bay Limit Research](https://mods.factorio.com/mod/CargoBayLimitResearch) 1.1.2+ | Opt-in capacity-research challenge | Preserve dynamic source science and player limit settings |
| [Platform Logistics Overhaul](https://mods.factorio.com/mod/platform-logistics-overhaul) 2.1.2+ | Same-orbit pod priority logistics | No changes to its real-pod transport behavior |

**Orbital Catapult** (https://mods.factorio.com/mod/orbital-cannon) has
special upstream instructions: its author requests only `~ orbital-cannon`
as a dependency to avoid breaking final-fixes starmap order. That form would
make the mod required, so Razi deliberately does **not** declare it as
recommended or required. Instead, its prototype-link bridge is off by
default, detects the source mod if manually installed, and offers only
Muria/Aquilo reversible local links. It does **not** touch the mandatory
Aquilo -> Vespera belt -> Rubia crossing or any inter-system route.
This experimental link still requires full in-game load and unlock testing.

Warning: Cargo Bay Limit Research **changes placement limits even if Razi
does not touch its code**; backup a save before enabling it. Shield Generators
loads the author's `migratus-orchestrus` dependency and has Lua-driven
shields, so large combat saves need UPS measurements. Platform Logistics
Overhaul and Space Age Railway Expansion are recent and should be evaluated
on disposable saves first. These are portal recommendations, not blanket
compatibility certifications.

## Recommended versus excluded choices

The supported companions use `+` recommendation declarations, but players
should not enable every installed third-party mod without checking conflicts.

**Always off for the curated Razi route graph:** `! outer-rim`,
`! kry-asteroid-belt`, `! AsteroidBelt`, `! Hephaestus` and other declared
starmap conflicts. Hephaestus's oversized native H labels and repeated markers
have no place in Razi's curated star map.
Outer Rim recommends the forbidden Better Asteroid Belt and explicitly excludes
the recommended Secretas orbit patch.

**Weather source:** Use `celestial-weather-additions-updated >= 1.6.0`
(Celestial Weather Next) alone. It replaces the original two weather
packages and declares `celestial-weather-updated` incompatible. Disable
that previously recommended fork when updating your enabled mod profile.

**Staff optional planets:** `? moon-eneas >= 1.0.10` and
`? shchierbin >= 0.3.19`. Eneas retains the native Unit-05 gantry and
moon gameplay; recommended Construction Drones/RPG packages from the Eneas
author are not Razi hard requirements. Shchierbin stays on the outside of
Vibrant's rocks and connects to Paracelsin if its native connection is
missing. Neither becomes an expedition progression requirement.

**Still excluded:** Nulla 1.0.2 crashed during its own final-fixes pass
when electric-furnace was absent; Planet Athos 1.1.3 generated a circular
technology dependency. Ask upstream authors to repair these before removal
of the explicit exclusions. Do not enable on your only existing save.

**Experimental manual install only:** `(?) FluxWorks >= 0.2.12`. The
integration minimum must be released and validated before promotion.
Unported Pelagos and Dea Dia are not declared.

**Suggested installation order:** curated required universe first, then
research UI and logistics companions, then enemy variants, then additional
planets and deep-space systems one category at a time. Test fresh saves and
copies of existing saves. Recommendations are not proof of complete playability.

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
