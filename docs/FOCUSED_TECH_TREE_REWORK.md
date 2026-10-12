# Razi Protocol: Intertwined Tech Tree, October 2026

## Target: connected, without a science-pack soup

The native Factorio 2.1 technology graph remains authoritative. The
first Solaris and Nyxaris systems can open independently from Calidus.
Discoveries inside a system may branch instead of being a single mandatory
sequence. Razi builds a limited set of bridges between already available
worlds and merges source-owned science in recipes only when safe.

## New native research bridges

| From | To | Why |
| --- | --- | --- |
| Apia/Carnova | Corrundum | Biology and chemistry share their frontier |
| Tellus | Panglia | Solaris engineering helps Nyxaris biology |
| Tenebris | Secretas | Umbra's biological industry feeds precious-metal processing |
| Cubium | Crucible | Beetlejuice's early metallurgy helps Umbra's later industry |
| Crucible | Frozeta | Exotic processing informs endgame salvage |
| Igrys + Foliax | Vibrant / Vespera | One early source world per frontier contributes to the next tier |
| Cerys + Obsidiax | Beetlejuice / Umbra | Both midgame source industries contribute to opening outer stars |

These are **existing discoveries**, never new mandatory science packs or
third-party recipes. New world milestones are only wired when their exact
native `unlock-space-location` technology exists, has a valid research
unit or trigger, and is independent of *both* destination-system gateways.
No gate to visit Vulcanus, Gleba, Fulgora or Muria changes.

The source tech tree and full source mod factory progression remain intact.
The other installed planet discoveries continue to matter through the
existing planetary-unification singularity finale, rather than imposing
all of their research costs on the first two star departures.

## Fixed science prerequisite trap

The earlier `campaign_weave.lua` associated a science-pack technology
with a future planet even when the actual recipe could only be unlocked
by the destination itself. It now requires **all** of these BEFORE linking:
the pack tech exists, the producing recipe is available prearrival, its
source world does not depend on the destination, and one installed lab can
accept the full existing research combination plus the new science.

Shchierbin is earlier than Paracelsin. The old Paracelsin galvanization
requirement for Shchierbin was inverted. A source pack gated behind a different, parallel planet discovery is no longer treated as available beforehand. This preserves Arig and Hyarion as independent branches. Shchierbin now uses earlier
Ribbonia and Muria milestones, when real, legal and producible.

## Validation and caveats

The graph guards prevent known technology cycles, duplicated edges,
missing optional prototypes, and source science generated only after
the destination. Production still needs a post-load data-raw audit
and actual game validation. Source mods with scripted or trigger-only
unlock mechanics may need a dedicated adapter. No dynamically modified
research tree has been playtested in-engine yet.

The change includes no new planets, recipes, technologies, icons,
background scheduled scripts or additional GitHub Actions workflows.

## Full required-planet finale coverage audit

The existing `scripts/audit_tech_tree.py` now parses
`planetary_unification.worlds`, inventories installed native
`unlock-space-location` effects, walks the complete final singularity
research graph, and reports any mapped planets with native discoveries
that are **not** actually required along the finale's ancestry.
It separately reports special/scripted planet unlocks that cannot be
verified from data-stage technology effects. The latter are review
targets rather than an excuse to add impossible gates.

Run with a real post-load Factorio data-raw dump:

```bash
python scripts/audit_tech_tree.py --dump-data-raw script-output/data-raw-dump.json
```

The script is advisory. No full data-raw dump exists in this connector
session, so the actual campaign-wide coverage numbers are unknown.
