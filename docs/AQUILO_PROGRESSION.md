# Aquilo: research power pacing

Aquilo is no longer the end of the expedition. Its original three major
endgame rewards could invalidate the logistics and terrain challenges of the
planets that come afterward in Razi Protocol's seven-system campaign.

## Balanced unlock stages (default)

| Technology | Earliest required later milestones | Purpose |
| --- | --- | --- |
| Foundation | Paracelsin and Maraxsis discoveries | Solve the earlier lava/oil terrain constraints after the exotic frontier has been explored |
| Fusion reactor | Cubium and Tenebris discoveries | Keep reactor fuel, heating, supply routes and power planning relevant during the first outer expeditions |
| Legendary quality | Outer Frontier Mastery (Frozeta, Vesta and Linox) | Reward completing the late outer campaign before transceiver and deep-space engineering |

- Aquilo continues to unlock cryogenic science, cryogenic processing,
  ice platforms and other native survival tools at their original times.
- Epic quality and all earlier tiers are unchanged.
- Only existing technology prerequisites are added. No new science packs,
  labs, recipes, entities or placement prohibitions are introduced.
- The final pass skips an entire rule if a required technology is missing,
  disabled or would introduce a prerequisite cycle. It logs the reason.
- This does not stop players importing stockpiled reactors or foundations
  from a pre-existing save or scenario. Previously completed research stays
  completed. New campaigns experience the intended progression.
- To use the original Space Age research timings, switch off
  **Stage Aquilo's major upgrades** in startup settings. The stage is
  independent of optional industrial interdependence.

## Design intent

A late planet should have its own setup puzzle before industrial imports
make it easy. Aquilo remains a major engineering milestone, but it is not a
single button that solves all future power, terrain and quality problems.
Fusion and legendary equipment still become powerful endgame rewards; the
player earns them through multiple expeditions rather than a single landing.

## Release verification

Run the isolated Lua fixture in tests/lua/test_aquilo_breakthroughs.lua and
the Python structural test in tests/test_aquilo_breakthroughs.py. Then load
the complete Factorio modpack with default and legacy settings, inspect
the three research trees, and test a migrated save. Runtime/loaded-modpack
validation is still required; local static tests alone cannot establish that
every third-party technology remains reachable.

## Phase 2: Late-power bypass screening (October 2026)

The three guarded Aquilo stages continue to be **Foundation after Paracelsin
and Maraxsis discovery**, **Fusion after Cubium and Tenebris discovery**, and
**Legendary after Outer Frontier Mastery**. No further research gates are
imposed without evidence from the full installed modpack.

To detect compatibility mistakes or shortcuts, export final Factorio 2.1
prototypes and run:

```bash
python scripts/audit_late_power.py --dump-data-raw data-raw-dump.json --json
python -m unittest tests.test_late_power_audit
```

The auditor flags missing stage prerequisites, hidden/disabled ancestors,
research cycles, enabled foundation/fusion recipes, alternate source research
that unlocks those recipes, and alternate Legendary-quality unlock effects.
These are candidate bypasses for manual review, **not proof that a player
can craft or research an item early**. Explicitly verify available labs,
producers, surface restrictions, physical planet visits and migrated saves.
Its optional `--strict` mode returns nonzero for installed review items.

Razi's 10-level quality asteroid ladder increases **hostile asteroid
difficulty**. The quality carrier does not introduce collectable quality
chunks; it does not itself bypass the delayed Legendary player technology.

