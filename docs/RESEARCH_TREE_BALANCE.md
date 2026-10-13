# Research tree and science pacing

Razi Protocol's technology tree links seven planetary systems into a long
campaign. This document separates the **travel spine** (core star-system
entry research), **parallel worlds** (optional or sibling discoveries),
**planet industry** (native source-mod production), and **shared factory
technology** (Razi's optional cross-world manufacturing).

## Paired system entrances

| Campaign passage | Independent gateways | Price principle |
| --- | --- | --- |
| Depart Calidus | Solaris / Nyxaris | Both use the same early science and neither depends on the other |
| Reach the middle stars | Vibrant / Vespera | Both depend on the earlier pair, not on each other |
| Reach the outer stars | Beetlejuice / Umbra | Both depend on the middle tier, not on each other |

The original gates and their first native science routes are protected
by `seven_system_gates`, `campaign_weave`,
`linox_science_guard` and `outer_science_arrival_guard`.
Never append a native world-science requirement to the technology that
first unlocks that world.

## Research family polish (2.1.30)

Only Razi-owned industrial technologies have their research order refined:

- **Precision Matrix:** foundation with separate Aquilo, Rubia and Linox upgrades
- **Panglia Optic Bond:** Panglia science/optics plus Paracelsin and Linox upgrades
- **Extreme Lattice:** extreme-material components with Vesta and Balack upgrades
- **Umbra Pressure Frame:** Deep-only late manufacturing with Vesta and Aquilo return routes

A factory component's industry research is optional, so having it depend
on previously established source discoveries is an opportunity for richer
interplanetary trade without destroying first-landings.

**Balanced:** Panglia's advanced optical research is now a precursor to
the two optional Panglia-bond factory upgrades, where all relevant
technologies are installed.

**Deep:** The Umbra Pressure Frame follows Extreme Lattice research;
Panglia's bonds feed the Vesta Lattice branch; Vesta's pressure-frame
foundations follow its upgraded magnets; and the return to Aquilo follows
Precision Matrix cryogenic controls. Balack's optional shielding upgrade
also receives the Panglia bond research connection. Each link is
skipped if either node is unavailable or adding it would form a cycle.

**Off:** This polishing layer does not change any tech or costs.

## Smoother Razi factory research costs

The following are **maximum research-unit budgets**. Existing smaller
values are never raised; completed technologies keep their research
IDs for save compatibility. Native mod technologies are not rebalanced.

| Razi research technology | Maximum count |
| --- | ---: |
| Matrix cryogenic controllers | 800 |
| Matrix Rubia logistics | 820 |
| Matrix Linox refining | 820 |
| Lattice Vesta magnets | 1,050 |
| Lattice Vesta foundations | 1,320 |
| Lattice Balack shielding | 1,360 |

The component technologies themselves retain their carefully tuned
research counts. Each of the four component nodes is also marked
`essential` and its Razi-owned upgrades are given a consistent order
so the Factorio technology overview is easier to browse.

## Automatic technology research audit

`scripts/audit_research_balance.py` runs against a real Factorio
post-load `data.raw` JSON dump. It inventories major milestone
costs and Razi science pack usage, checks whether star-system entry
pairs remain truly independent, and reports source research price
outliers, missing science prototypes and lab combinations.

Use `--strict` for a nonzero exit on definite source-prototype
research contradictions. Cost spikes remain advisory. The full campaign
auditor incorporates these findings alongside technology cycles,
manufacturing provenance, laboratory compatibility, and freight economy.

```bash
python3 scripts/audit_research_balance.py /path/to/data-raw-dump.json --json
python3 scripts/audit_full_campaign.py /path/to/data-raw-dump.json --output full-campaign-audit.json
```

Research availability is not proof that science can physically be made.
No static audit can validate every platform arrival, specialized
machine, surface restriction or scripted source-mod unlock without
running Factorio. Build-cost and logistics balance require playtesting.
