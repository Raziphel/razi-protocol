# RAZI Industries: first 3.0 integration pass

**Status:** pilot narrative direction for the development branch, not finalized
canon. The visual language is restrained corporate engineering: safety-orange
accents, charcoal machinery, precise typography and useful status labels.

## The experience we are building

Razi Protocol should feel like a unified Factorio expansion, not a pile of
planet mods. The expedition is first and foremost an engineering campaign.
The corporate narrative adds context through things players actually do:
build power, research systems, colonize worlds, link factories and construct
physical megaprojects. It must never interrupt production with forced fiction.

The working premise is an old interstellar corporation whose automated
operational systems may have outlived their staff. Whether that is the whole
truth is deliberately unresolved. The Shattered Planet revelation and the
true purpose of the Protocol are left for a joint narrative decision.

### Narrative pilot

Ten independent corporate transmissions now use existing source milestones.
The original six retain their stable IDs, while Gleba, Fulgora, Aquilo
and Tenebris provide additional independent archive records. The pilot's
initial sequence includes:
First Signal, Castra, Moshine, Precision Matrix, Outer Mastery and
Convergence Commission. They coexist with all fifteen previous archival
records. Progress comes from actual game research, not flags set by prose.
Players can discover the locations in different valid orders.

### World identity pilot

Twelve quest dossiers gain industrial opportunity notes plus links to actual,
available *related* journal milestones. These connections are optional
reading shortcuts, not a required planet order. All notes use the original
game content: Castra, Moshine, Gleba, Fulgora, Paracelsin, Aquilo, Rubia,
Panglia, Athos, Nulla, Tenebris and Vesta. These are *editorial* summaries,
not guaranteed automated production chains or claimed shipped items.

Future planet passes should document: unique native industry, first useful
export, inbound logistical requirement, follow-up reward, where the player's
next relevant technology becomes available, and why the world is memorable.
Validate every claim against loaded source prototypes.

### Crafting navigation

An enabled-by-default, display-only fluid barreling subgroup groups recognized
fill/empty barrel recipes, when Factorio exposes its fluids item group.
Recipe classification now checks actual fluid and barrel components instead
of relying on recipe name alone. Existing source-owned custom tabs remain
untouched. Experimental spoilable-intermediate grouping is OFF by default until verified
with the full installed pack. Neither changes crafting categories, ingredients,
results, technology unlocks, recipe availability or item prototypes.

Do not automatically hide recipes players cannot handcraft: valid recipes
for machines can be obscured. A safe future visibility change needs in-game
validation and an explicit setting.

### Contributions: minimal friction for writers

1. Choose a stable, existing journal quest ID. Inspect
   `scripts/razi_journal_data.lua` and its imported expansion modules.
2. Add a unique record in `scripts/razi_journal_corporate.lua`.
3. Supply `journal-record-title`, `journal-record-origin` and
   `journal-record-body` in `locale/en/razi_journal_corporate.cfg`.
4. To add a planet brief, map an actual quest ID in
   `scripts/razi_planet_briefs.lua` and add `razi-industries-brief` locale.
5. Run `python tools/journal_locale.py` and
   `python -m unittest tests.test_razi_3_0_first_pass`.
6. Verify the old-save journal and that missing optional prototypes do
   not create misleading progress.

Keep authored English sentences in locale, not runtime Lua. Translators should
not need to understand game scripting to rewrite a story.

### Progression and compatibility gate

For meaningful balance changes use the existing `scripts/audit_tech_tree.py`
and `scripts/audit_research_balance.py`, and the new
`scripts/audit_crafting_navigation.py`, with a loaded Factorio `data.raw`
export, plus fresh-game and migrated-save testing. Check prerequisite cycles,
lab science-pack support, route availability and optional-mod absence.

Alex's compatibility/porting changes and Podrick's narrative work must be
reviewed rather than overwritten. Make changes on `feat/razi-3.0`;
do not merge to public release `main` before contributors finish reviews.

## Pass 02: deeper game-ready integration

- Ten corporate transmissions share the existing archive, in a labeled
  RAZI Industries section. The late narrative remains deliberately open.
- Every industrial brief can link to other *installed* quest dossiers.
  No new technology, route or shipping obligation is created.
- Barreling grouping verifies ingredients/results and respects mod-owned tabs.
  The opt-in spoilable subgroup still requires a full gameplay review.
- A new recipe-navigation auditor reports verified candidates, unusual barrel
  recipes, custom-group conflicts and perishable intermediate candidates.
- The existing technology audit additionally reports missing research-science
  item prototypes and Razi-owned unlocks pointing to missing recipes.
  These checks are advisory and require a complete loaded data dump.
- Authoring consistency catches missing or repeated cross-planet links.

Commands:

```sh
python -m unittest tests.test_razi_3_0_first_pass tests.test_razi_3_0_second_pass tests.test_galactic_tech_audit
python tools/journal_locale.py
python scripts/audit_campaign_consistency.py
python scripts/audit_crafting_navigation.py --dump-data-raw loaded-data-raw.json
python scripts/audit_tech_tree.py --dump-data-raw loaded-data-raw.json
```

**Unverified:** Full Factorio 2.1 + K2SO startup, recipe GUI tabs,
science labs, migrations and all source-mod combinations. Do not
merge into public release `main` without these checks and contributor review.

## Pass 01 results and follow-up

| Area | Implemented here | Still needed before release |
| --- | --- | --- |
| Identity | Corporate dispatches under the current Journal | Agree on canon, tone and finale |
| Crafting | Barreling grouping and opt-in perishable grouping | Full-pack crafting UI verification |
| Planet roles | Twelve source-aligned industrial dossier notes | Rewards and supply-chain validation |
| Progression | Retained existing graph and economy audits | Loaded-pack research, lab and route review |
| Developer workflow | Stable IDs, localized content and consistency tests | Contributor review and in-game smoke test |

## Pass 03: useful factories and a measurable industry pipeline

The Cargo Network's **Optional Factory Partnerships** ledger now discovers
existing researched/available Razi industry quests using their real loaded
technology and recipe prototypes. It previews up to eight relevant upgrades
(prioritizing ready research, then researched production) and links directly to
the original Codex dossier. Counts reflect installed prototypes and researched
technology, **not actual shipments or factory throughput**.

The shared source-recipe exchange engine now refuses to scale native templates
containing probabilistic or range-based byproducts or missing deterministic
amounts. This avoids data-stage arithmetic errors when third-party planet
mods change a native recipe unexpectedly. It may suppress an optional bonus
rather than crashing a pack. It never removes the native source recipe.

### How to evaluate freight rewards

Run the **combined one-dump review** against a full post-load Factorio export:

```sh
python tools/factory_review.py --dump-data-raw loaded-data-raw.json
python tools/factory_review.py --dump-data-raw loaded-data-raw.json --json
```

It includes four compatible independent checks:

1. `scripts/audit_industry_portfolio.py`: expected optional research/recipe
   pairings, unlock effects, deterministic output, productivity/recycling
   safeguards, loaded category-capable machines, and lab science combinations.
2. `scripts/audit_exchange_economy.py`: native vs. freight batch output and
   per-machine throughput for the existing watched premium recipes.
3. `scripts/audit_crafting_navigation.py`: unusual barrel and spoilable
   recipe categories.
4. `scripts/audit_tech_tree.py`: missing prerequisites, science lab coverage,
   and the existing galaxy/finale research graph checks.

These audits distinguish deliberately absent optional integrations from
installed-but-suspicious recipes. A valid prototype is **not** proof of positive
net economic benefit. Shipping time, source material costs, upstream machine
throughput, planetary resource availability and route hazards must be measured
in-game before modifying production yield or research cost.

### Required playtest before approving economy changes

- Start Factorio 2.1 with the actual required K2SO pack and recommended mods.
- Confirm the Cargo Network ledger only lists installed bonus recipes.
- Select a factory partnership and verify its existing Codex dossier opens.
- Test a previously saved factory: no former technology or recipe is removed.
- Inspect optional alt recipes and the native output side by side in machines
  able to craft both. Verify byproducts, productivity and recycling are safe.
- Check source worlds, route distance, travel fuel, production throughput and
  the real inventory consumed per finished item before altering rewards.
- Review results with the developers before merging into `main`.

### Economy design rule

Prefer **small, worthwhile bonuses for importing completed useful goods**
over compulsory imports or new raw resources. A normal source recipe must
always be available when its original research permits it. Keep performance
stable and make every extra industrial connection clear in the UI.

## Pass 04: freight break-even, route evidence and honest economy design

**New in the game:** Cargo Network premium factories now show a deterministic
product's real per-craft output when the installed recipe provides one. This
is not displayed as a profit margin. Source-mod factories retain their
original names, recipes and technologies.

**New in data stage:** An optional interplanetary recipe is only registered
when at least one compatible machine has enough declared ingredient capacity
*as well as* the required fluid ports, category and surface support.
Repeated imported/native ingredients count as one distinct input. Machines
with no explicit ingredient_count limit are handled as before.

**New in diagnostics:** The source-vs-premium recipe audit flags a recipe
that omits a native material, even when the advertised bonus looks attractive.
Its companion break-even model examines the eight established, explicitly
mapped native/premium recipe pairs. Missing optional integrations are normal.

### Interpreting a freight budget

For equal native batches, with all other native inputs preserved:

```text
Freight budget per premium craft
  = extra finished products × value per finished product
    - extra imported ingredients × factory-gate input value
    - max(0, extra machine seconds) × machine-second value
```

The result is the **maximum combined freight expense** that this
specific user-provided value scenario can afford before the output
bonus stops paying for itself. Negative budgets mean the hypothetical
extra input and processing costs already exceed the extra output value.

Do not read it as measured profit. Power, platform loading, technology
costs, quality, modules, recycling, spoilage and geographic availability
still need in-game validation. Actual source-native freight differences,
if any, must be reviewed before using a scenario for balance changes.

### Running the report

1. Export a complete post-data-final-fixes Factorio `data.raw` JSON, using
   the same actual mods/settings used for gameplay.
2. Record realistic local factory-gate values in a JSON file, in arbitrary
   but **consistent** units per item/fluid unit. All values must be finite
   and nonnegative. Example values below are TEST ASSUMPTIONS, not prices:

   ```json
   {
     "item:vesta-foundation": 2.0,
     "item:razi-network-umbra-pressure-frame": 5.0
   }
   ```

3. Record observed **shipping credits per craft** for premium recipe IDs in
   a separate JSON file. You decide how to value loading, travel, return
   flights and platform losses. The model never invents them.
4. Review the output:

   ```sh
   python tools/factory_review.py --dump-data-raw loaded-data-raw.json --json
   python scripts/audit_freight_break_even.py --dump-data-raw loaded-data-raw.json \
     --values factory-values.json --shipping-costs freight-costs.json \
     --machine-second-value 0.25 --lane moshine,fulgora --json
   ```

   The `--lane` comparison adds shortest registered map kilometres only.
   It does not multiply distance into credits or assume platform speed.
   When source values are missing, the report says so instead of charging 0.

### Design and review protocol

- If a source recipe's native inputs or deterministic byproducts were
  reduced, **fix the integrity issue first**. The margin is deliberately
  suppressed. Optional bonuses must never erase native factory value.
- Compare recipes by output bonus, machine seconds, upstream input cost,
  platform capacity and typical journey, not raw output percentage alone.
- Favor modest optional batches that produce something players genuinely
  need. Do not punish a solo planet run or make optional mods mandatory.
- Never rebalance a recipe on assumptions alone. Share the loaded audit
  output and real factory measurements with Alex and the other developers.
- A player who never uses the freight bonus must still complete the
  entire intended science/planetary progression.

The default economic values remain unchanged in Pass 04, pending real
prototype dumps and playtesting. This is a deliberate release-safety limit,
not a claim that all existing recipes are perfectly balanced.
