## Card production and laboratory tiers (2.1.54)

System cards now have an intentional five-stage laboratory ladder:

| Lab | Permitted Razi system cards | Construction requirements |
| --- | --- | --- |
| Ordinary Lab | Calidus | Existing lab, no new research |
| Frontier Laboratory | Calidus, Solaris, Nyxaris | Lab + advanced processors and low-density structure |
| Constellation Laboratory | Earlier cards + Vibrant, Vespera | Frontier lab, Vulcanus rare metals, Gleba bioflux and Moshine optics |
| Astral Laboratory | Earlier cards + Beetlejuice, Umbra | Constellation lab, Fulgoran holmium, Aquilo controls, Rubia frames |
| Deep Space Laboratory | All eight cards, including Deep Space | Astral lab, Linox rare earths and Vesta supermagnets |

The four laboratory research milestones are also tracked in the optional
Codex Network chapter. Missing lab research prototypes are filtered from
the active quest list; completion is based on actual research.

The Frontier lab is unlocked through Calidus science; the Constellation
lab requires Solaris and Nyxaris cards; Astral uses Vibrant and Vespera
cards; Deep Space uses Beetlejuice and Umbra cards. No lab technology
demands a card that only that laboratory tier could accept.

Source-mod labs keep their native non-Razi science packs. Razi adds
card restrictions to the regular lab (Calidus), biolab/thermodynamic
lab/advanced K2SO lab (first frontier), K2SO singularity and pressure
labs (outer), and Omega lab (all tiers). Because planet mods sometimes
add unusual mixed-pack technologies, a final compatibility pass checks
each installed technology with Razi cards against a **single real lab**.
Only if no lab supports the combination does it add the missing Razi
cards to the best available specialist lab that already accepts all
other native science ingredients. This prevents a hard lock, but in
specific mod combinations it may relax the ideal tier restriction.
No lab gets unrelated science packs copied into its inputs.

### Card manufacturing choices

Every primary one-card recipe survives. Five guarded supplementary
**two-to-three** multiplex recipes become available only after
their native supplier world research: Solaris (Corrundum tungsten +
Vulcanus rare metals), Nyxaris (Apia milestone + Gleba bioflux +
Moshine optics), Vibrant (Paracelsin electrocoils + Fulgoran holmium),
Vespera (Rubia composites + Gleba carbon fiber) and Deep Space
(Aegis/Bellicos logistics and pulsar science). Each requires two complete
original card ingredient sets and produces three cards. They disable
productivity and are optional, not prerequisites for arrival research.

This pass also eliminates a concrete circular dependency: the Solaris
card no longer consumes Paracelsin electrochemical science, which is
only obtainable after Vibrant. Similarly, first-tier Vibrant and Vespera
cards no longer directly demand later optional galvanisation/hydraulic
packs, and the first Deep Space card no longer demands Aegis/Bellicos
post-edge science.

**Validation still required**: full data-raw dump, real source research
and crafting reachability, every required science combination in a
single physical lab, recipe availability with optional mod sets, and
fresh plus older Factorio saves. No mod-owned non-card lab capability
or player research state is deliberately removed.

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

## Native science returns to late factories (2.1.31)

The new `planetary_science_weave` pass only considers Razi's existing
optional component and premium factory technologies. It never rewrites
the native discovery science costs, science production recipes or lab
prototype inputs. These eight original packs have additional *possible*
research customers:

| Native science pack | World of origin | Existing Razi industry targeted |
| --- | --- | --- |
| Thermodynamic | Moshine | Precision Matrix, Panglia Optic Bond |
| Electrochemical | Paracelsin | Precision Matrix, bonded coils |
| Cryogenic | Aquilo | Precision Matrix controllers, pressure-frame controllers |
| Rubia biofusion | Rubia | Rubia logistics, Extreme Lattice |
| Linox science | Linox | Panglia-bond refining, Deep Vesta pressure foundations |
| Bioluminescent | Tenebris | Extreme Lattice, Deep Balack shielding |
| Gas manipulation | Vesta | Lattice magnets, Lattice foundations, Deep pressure frame |
| Crucible science | Crucible | Deep pressure frame, Vesta/Aquilo pressure-frame upgrades |

There are 18 planned guarded science-to-research connections across
the four component families. **A line is only activated when all
conditions hold:** the native science item exists, an actual production
recipe exists with valid direct ingredients, that recipe is available
before the Razi technology, the originating planet's discovery is
already upstream, any surface-specific recipe requirements match its
source world, and a single existing laboratory already accepts the
entire combined science list. The native producer's unlocking
technology becomes an explicit prerequisite when necessary and safe.

The result is deliberately different for each optional mod configuration.
An unsupported source recipe or incompatible lab **skips the extra
science**. No Razi science recipe, new laboratory, or fake world is
generated as a fallback. Balanced interdependence offers established
planet sciences to industrial projects; Deep additionally connects the
Crucible, Vesta, Linox and Tenebris sciences to extreme outer-industry
research. With interdependence Off, nothing is changed.

### In-game inspection

The Galactic Operations **Cargo Network** tab now displays each
expanded component's actual research count and science ingredients,
including these integrations when they are registered. A Codex jump
to a factory upgrade also shows its actual researched science mix
in the expanded downstream research. No source lab data is inferred,
and tooltips do not assert that a required science has already been
manufactured, delivered or consumed.

### How to validate

Run both the Lua fixture and the post-load research auditor:

```bash
lua5.2 tests/lua/test_planetary_science_weave.lua
python3 -m unittest discover -s tests -p 'test_planetary_science_weave.py'
python3 -m unittest discover -s tests -p 'test_research_balance.py'
python3 scripts/audit_research_balance.py /path/to/data-raw-dump.json --json
```

The audit now also flags any native world-discovery technology, or
any prerequisite technology on its discovery path, that demands that
world's own science pack. It reports which of these eight sciences are
actually reused in the loaded Razi industries, rather than claiming
that all 18 optional rules were accepted. Native lab acceptance and
recipe existence alone cannot prove supply in an in-game factory.
