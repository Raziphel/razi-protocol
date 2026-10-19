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
