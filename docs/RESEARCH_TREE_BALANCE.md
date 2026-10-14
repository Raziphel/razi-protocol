## 2.1.68: Practical science economy and factory return freight

The seven post-arrival **freight-assisted system-card recipes** now process
four unchanged source-card batches plus regional imported materials into
five cards. That saves 20% of the original source ingredients per finished
card (25% extra cards per four native batches), before valuing the additional
freight. Crafting takes 1.15 times the normal time for four native batches,
providing about 8.7% more cards per machine-hour. Productivity and automatic
recycling remain disabled. The original one-card recipe and technology
identifiers are preserved; no laboratories or science-pack types were added.

Two new guarded alternatives give the last two stars an export economy:
Beetlejuice combines Linox rare earths and Secretas gold after Secretas;
Umbra combines Tenebris chitosan, Vesta supermagnets and Linox rare earths
after Vesta. They only register when the relevant source items and native
research unlocks exist. These are *production rewards*, never additional
costs on native first discovery or mandatory card manufacture.

The first-frontier Razi discovery costs are also lighter: Arig/Hyarion
750 to 650, Tellus 900 to 800, Corrundum 1,100 to 950, and the Moshine /
Apia-Carnova discoveries 850 to 800 units. Solaris and Nyxaris retain
independent 650-unit system entries; the subsequent paired gateways remain
1,200 and 1,600, with Outer Frontier Mastery at 1,900. Panglia's source
data-cell discovery is untouched.

The science audit now reports both first-frontier Razi card demand and
the effective gross bonus, crafting rate and extra imported resources for
each installed multiplex recipe. It flags any bonus above the 25% ceiling,
missing ordinary inputs, insufficient crafting time or enabled productivity /
automatic recycling. No static report certifies freight travel efficiency.

## 2.1.67: Visible card demand and real-lab compatibility

`scripts/audit_research_balance.py` now reports the direct system-card
items consumed by the technology researches in each campaign stage.
These numbers multiply the final science pack ingredients by actual
research units; they do **not** silently double nested predecessor
recipes, change a source mod's technology, or pretend crafting throughput
has been measured. Compare the report with real factory output before
adjusting the next balance tier.

Galactic Operations now also displays direct pack totals for each pending
system-entry technology using the installed force's research price and
science ingredients. It shows up to four pack types per gate, and does not
invent a science bill for native trigger-only research.

`science_lab_coverage` lists the existing installed labs that accept the
entire science combination for each tracked Razi technology; an empty list
with a populated lab prototype table raises the existing hard lab-coverage
error. No new laboratory prototypes or blanket source-lab inputs are added.

## 2.1.63: System card manufacturing and science pacing

Razi now accounts for the *real manufacturing cost* of science cards before
charging thousands of those cards to unlock the next star. The seven-system
route structure and existing technology identifiers remain unchanged.

| Research gateway | Old units per gateway | New units per gateway |
| --- | ---: | ---: |
| Solaris / Nyxaris | 1,000 | 650 |
| Vibrant / Vespera | 1,500 | 1,200 |
| Beetlejuice / Umbra | 1,900 | 1,600 |
| Outer Frontier Mastery | 2,200 | 1,900 |

**System-card production:** Calidus crafts in 10 seconds; Solaris/Nyxaris
in 12; Vibrant/Vespera in 16; Beetlejuice/Umbra in 22; Deep Space in 28.
Only native planetary science ingredients double for the two outer cards
and Deep Space. Prerequisite **system cards always remain one per recipe**,
so a late science recipe cannot recursively double the cost of every
earlier card. No new factories, laboratories, planets or ingredients
have been added. The seven optional freight batch recipes use the final
ordinary recipes as their baseline.

Four foundational industrial technologies and ten associated Razi
factory upgrades now have more manageable upper research-cost limits.
Existing overrides with lower prices are respected. Deep interdependence
adds three further cycle-checked cross-factory research links.

The guarded planetary science catalog grows from **18 to 30 candidate
connections**, eight of them Deep-only. Added sources include Apia/Carnova,
Muria, Ribbonia, Linox and established mid/outer-world sciences.
Each extra science pack is applied only to an *existing Razi-owned,
post-arrival factory technology* when its source world's research is
already upstream, its actual manufacturing recipe is supported, and
one installed lab can consume the **complete** science mixture. The
recipe lookup now indexes native outputs once instead of rechecking
every recipe once per wanted science pack. No source labs receive
new science inputs through this optional weave.

**Modes:** Off leaves the optional industrial research weave unchanged,
while keeping the main campaign's science pacing and card manufacturing
consistent. Balanced enables proven industrial reuse. Deep adds the
cycle-checked remote-world science and factory link requirements.

The research audit now reports each existing system card's direct input
items, predecessor cards, ingredient counts and craft time, and treats
card-to-card production cycles as hard errors. Audits remain advisory
about *physical* manufacturing, which requires a real Factorio run.

## 2.1.62: Three native-machine Ignition assemblies

Ignition now consumes three assembled physical components instead of
putting ten or more ingredients into a single crafting machine:
Calidus Stellar Frame, Outer-System Engineering Matrix and
Deep-Space Resonance Lens. Across their existing-native-assembler
recipes, they still consume all eight required system tech cards.
Optional source materials are limited to the installed machine's
input-slot capacity. This neither creates a lab nor rewrites source
recipes.

Old Convergence deliveries and research history remain intact.
The read-only /razi-audit now checks all five Mandate recipes plus
these three component recipes. A full modpack startup and source
research-path verification remain outstanding.

## Loaded-technology verification (2.1.61)

Administrators can now run `/razi-audit` to compare the three
Convergence research packs with the installed native laboratories,
check that the current force has all five Mandate recipes, detect
missing/disabled recipe unlocks, verify a native machine handles
each Mandate's ingredient count and crafting category, and flag
direct cycles in the final research ancestry. It also lists actual source recipe producer
visibility and real Dyson receiver counts when known.

This is a live, read-only compatibility *screening*, not a complete
proof that each source planet is reachable or that all supplied
recipes can be manufactured in the correct order. Real modpack
startup plus a full research/craft progression test remain essential.

## 2.1.60: Endgame research guidance, no source rewrite

The updated Convergence console reads the installed `ForceTechnology`
prerequisites and `force.recipes` states to explain why a physical
Mandate cannot yet be manufactured or delivered. It does not
reprice native planetary technology or fabricate new labs. Codex
recommendations distinguish already-researched physical freight from
available native research. No recipe, technology, Dyson supplier or
Nexus boss prototype is changed by this UI pass.

**Release blocker:** Validate real K2SO, SLP, Aegis, Nexus and optional
planet inputs in a full post-load data-raw dump. Static producer
existence does not prove accessibility; check genuine recipe unlock
prerequisites, the first craftable assemblers, surface conditions,
and a single existing lab accepting each combined research set.
Without the full modpack and actual save, no research-cost rebalance
should be advertised as tested or complete.

## True endgame science and freight (2.1.56)

The transceiver science chain remains the **pre-edge gate**. The
Convergence Commission research is strictly **post-edge**, optionally
requiring completed, safely upstream Aegis and Dyson research. Both
The Convergence Commission and Deep-Space Synchronization technologies
are researched in existing compatible labs, never custom Razi labs.
When optional Nexus Omega Lab is unavailable, authorization research
falls back to the two outer system cards accepted by source K2SO labs,
but the final manufactured cargo still requires Deep Space cards.

The three physical mandates consume native system cards and real
industrial goods in normal crafting recipes. The first two follow
Calidus/Solaris/Nyxaris and Vibrant/Vespera; the final one requires
Beetlejuice/Umbra/Deep Space. Optional completed planet products are
included only if their actual item and source recipe both exist. The
source can be missing without creating a phantom item. All three
recipes disable productivity, decomposition and automatic recycling.

Winning requires real cargo delivered in three stages at a real,
distant, force-owned space platform. Research unlocks the stages but
does not grant or simulate production. Completion is recorded by
force in durable storage and has no connection to automatic win
conditions from the earlier K2SO transceiver.

## Native laboratory science tiers (2.1.55)

Razi Protocol does **not** introduce new laboratories. All four prototype
labs from 2.1.54 are retired, including their items, technologies and
Codex missions. Existing 2.1.54 placed labs and stored lab items migrate
back into ordinary vanilla Labs at save load. The specialty materials
previously consumed are not returned.

| Science-card tier | Existing source laboratory |
| --- | --- |
| Calidus | Vanilla Lab |
| Solaris / Nyxaris | K2SO Advanced Lab, Gleba Biolab |
| Vibrant / Vespera | Moshine Thermodynamics Lab |
| Beetlejuice / Umbra | K2SO Singularity Lab and existing Pressure Lab |
| Deep Space | Nexus Omega Lab |

If Moshine's native lab is missing, K2SO Advanced Lab can step in for
Vibrant/Vespera. Razi edits only its own **system-card input lists**:
all other source science inputs are left as their original mods intend.
A targeted research-coverage check may allow a narrowly scoped exception
when no lab accepts the complete combination of Razi and native science
for an installed technology. It never grants extra native science packs.

The source-lab recipe polish is conditional: an existing locked recipe
may gain appropriate native industrial ingredients only when its
technology already inherits the research unlock for those inputs.
This prevents an ordinary Moshine, K2SO or Nexus lab from needing a
material unlocked after itself. Source recipes, graphics, entities and
building costs remain otherwise intact.

The five original bulk card recipes from 2.1.54 remain intact. Their
first-available ordinary card recipe is preserved.

## Revised Deep Space access (2.1.55)

The **physical activation of the K2SO intergalactic transceiver** is a
gateway to the Solar System Edge, not the campaign ending. Research the
three Razi singularity stages with obtainable Calidus through Umbra
system cards; the final transceiver recipe remains the real source K2SO
machine. After its activation, the native signal research becomes a
prerequisite of the Solar System Edge discovery, provided its installed
research path is not circular.

Razi asks the installed K2SO transceiver's supported remote interface
(if available) to suppress its original victory popup, leaving the
native power charge and activation intact. This is done on new-game
initialisation and configuration changes only, not in a per-tick loop.

The final act has not been designated yet. Promethium, Shattered Planet,
Nexus and the source-owned Deep Space branches remain available for a
larger galaxy-wide construction or discovery objective. Full-modpack
access checks and science-chain verification are required.

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
