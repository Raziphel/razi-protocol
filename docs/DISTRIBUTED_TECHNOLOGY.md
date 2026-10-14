# Distributed Technology: planetary industry research

## Why

Nauvis is Razi Protocol's launch foundation, not a place where every
significant technology can be mastered before leaving home. This
first implementation moves a small selection of *existing* technology
research to the worlds whose factories and science suit them.

**This is actual research gating**, not icon grouping. Existing technology
identifiers, recipe unlocks, research progress, research counts, rocket
manufacturing and planet discovery technologies are preserved.

| Existing technology | Planetary laboratory science | Gameplay reward |
| --- | --- | --- |
| `construction-robotics` | Gleba: agricultural science | Your first construction network |
| `nuclear-power` | Vulcanus: metallurgy + Gleba: agriculture | Nuclear reactor and fuel engineering |
| `logistic-robotics` | Vulcanus: metallurgy + Gleba: agriculture | Logistic robots and planetary automation |
| `personal-roboport-equipment` | Gleba: agriculture | Mobile construction support |
| `logistic-system` | Fulgora: electromagnetic science | Requester and buffer logistics |
| `nuclear-fuel-reprocessing` | Cerys: nuclear science | Efficient spent-fuel processing |
| `interplanetary-trade-logistics` (Planet Express) | Vulcanus + Gleba, when installed | Specialized freight research |
| `aai-signal-transmission` (AAI and recognized source aliases) | Fulgora electromagnetic science, when installed | Interplanetary communication |

A planet's native research must still be completed and its science
pack actually manufactured. Requiring only an unlock milestone would
let a player research these technologies from Nauvis immediately after
paying for a destination without ever visiting it. Razi therefore
adds **real existing planetary science packs**, plus the appropriate
existing planet-discovery technologies.

## First-rocket bootstrap is intentionally untouched

Razi does **not** move `robotics` or flying robot frames,
`electric-engine`, `rocket-fuel`, `low-density-structure`,
`rocket-silo`, `space-platform`, `space-science-pack`,
the first Solaris/Nyxaris gateways or early lab unlocks.

Players should be able to leave Nauvis, build a functional platform,
land, manufacture planetary science and import it for research before
they get construction/logistic robots or nuclear power. Native rockets,
inserters, belts and platforms provide the early manual freight chain.
The paired Solaris and Nyxaris entrances remain independent.

## Compatibility design

`razi-distributed-technology` is a **startup setting** defaulting to
enabled. Disabling it restores the native/source technologies' original
science/prerequisites on the next full prototype load. No migrations
delete researched technology progress or existing items.

The final-pass module runs *after* source mods, all seven-system gates,
factory integrations, source labs and Convergence registration. It
checks each technology independently and skips that change if any
prerequisite is absent/disabled/hidden, a source pack or producer is
missing, a technology dependency would cycle, no required research
unit exists, or no suitable early/middle lab accepts every required
pack. The accepted lab set is restricted to existing `lab`, `biolab`,
`kr-advanced-lab` and `thermodynamics-lab` to prevent an endgame
omega lab being counted as the only way to finish early research.
No new labs, recipes or planet IDs are introduced.

Some source mods can install unexpected recipe unlock chains invisible
to a basic prerequisite check. A post-load tech graph audit can
identify lab gaps and missing sciences, **but it cannot prove** the
planet's real factories can run without robotics, or that a particular
source mod hasn't moved a critical recipe. These still need full
gameplay smoke tests.

## Manual release gates

1. Start a fresh Nauvis save with the complete Razi modpack. Unlock
   rockets, Space Platform, Solaris and Nyxaris without any newly
   distributed technology. Physically arrive on Vulcanus and Gleba
   using belts, inserters and ordinary space platform mechanics.
2. Produce metallurgic and agricultural science using the source
   planet recipes. Research nuclear power, construction robotics
   and logistic robotics in their intended order in a *real* lab.
   Verify a newly researched roboport and reactor can be crafted.
3. Reach Fulgora; import electromagnetic science and verify
   `logistic-system`. Reach Cerys, verify its existing nuclear-science
   technology, producer and fuel-reprocessing research when installed.
4. With Planet Express and AAI enabled, verify their actual
   named technologies resolve, that freight can still travel
   by native platforms before Planet Express research, and that
   AAI's signal transmitter does not become an accidental requirement
   for any earlier discovery or its own science.
5. Back up an existing save with reactor/robotics already researched.
   Confirm finished research stays finished, unlocked recipes
   remain unlocked, and platform schedules are unchanged.
6. Toggle **Spread major technologies across planets** off in a
   controlled test profile; restart. Check native research science,
   technology order and availability return.

Focused fixtures and post-load audit (do not auto-run Actions):
```sh
lua5.2 tests/lua/test_distributed_industry.lua
python3 -m unittest discover -s tests -p 'test_distributed_industry.py'
python3 -m unittest discover -s tests -p 'test_research_balance.py'
python3 scripts/audit_research_balance.py /path/to/razi-data-raw.json --strict
```

If one target is skipped, search `factorio-current.log` for
`[Razi Protocol/industry-distribution]` and inspect its reason.
`no-early-compatible-lab` or `missing-native-science` indicates a
source-mod compatibility review is required before moving that technology.

The early cost balance is **not yet confirmed** in a running modpack.
Make adjustments from real recipe/lab availability and the cost audits
rather than adding more arbitrary research locks.
