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

Six independent corporate transmissions use existing quest milestones:
First Signal, Castra, Moshine, Precision Matrix, Outer Mastery and
Convergence Commission. They coexist with all fifteen previous archival
records. Progress comes from actual game research, not flags set by prose.
Players can discover the locations in different valid orders.

### World identity pilot

Twelve quest dossiers gain industrial opportunity notes using the original
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
Experimental spoilable-intermediate grouping is OFF by default until verified
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
and `scripts/audit_research_balance.py` with a loaded Factorio `data.raw`
export, plus fresh-game and migrated-save testing. Check prerequisite cycles,
lab science-pack support, route availability and optional-mod absence.

Alex's compatibility/porting changes and Podrick's narrative work must be
reviewed rather than overwritten. Make changes on `feat/razi-3.0`;
do not merge to public release `main` before contributors finish reviews.

## Pass 01 results and follow-up

| Area | Implemented here | Still needed before release |
| --- | --- | --- |
| Identity | Corporate dispatches under the current Journal | Agree on canon, tone and finale |
| Crafting | Barreling grouping and opt-in perishable grouping | Full-pack crafting UI verification |
| Planet roles | Twelve source-aligned industrial dossier notes | Rewards and supply-chain validation |
| Progression | Retained existing graph and economy audits | Loaded-pack research, lab and route review |
| Developer workflow | Stable IDs, localized content and consistency tests | Contributor review and in-game smoke test |
