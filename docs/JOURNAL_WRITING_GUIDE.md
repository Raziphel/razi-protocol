# Journal and starmap writing guide

Keep the prose readable at Factorio's normal UI scale. A location tooltip
should help someone understand where the place is and what they can do there.
A journal entry should feel like something somebody actually saw, built,
measured, sent, lost or wrote down.

## Voice by surface

**Location briefings:** One to three short sentences. State the important
route or environmental constraint first. Add one concrete detail when it helps.
Never invent travel links, technology gates or items.

**Quest stories:** A short scene, workplace observation, flight log or piece
of history. The subject should be the work being done, not an abstract sermon
about how worlds, machines or the expedition "learn" something.

**Quest tips:** Plain instructions. Preserve real technology names, quantities,
conditions and installed-mod behavior. Tips are allowed to be boring when a
wrong instruction would waste a player's time.

**Archive records:** Sound like documents written by different people.
Try incident forms, letters, signed shift logs, repairs that were never
authorized, a row from a manifest, or a note left for the next crew.
The corporate voice may be cold and absurd. Don't make every archive page end
with a moral. Give the player enough detail to draw their own conclusions.

**Recovered signals:** Keep some uncertainty, but ground it in instruments,
timestamps, unusual materials, recorded speech or a specific failed test.
Do not make every signal a grand question about the universe.

**Chapter summaries:** Tell readers what they will actually do. Save the
longer lore for archive entries. A chapter doesn't need three paragraphs
explaining its importance.

## A few editing rules

- Name the object, the place and the problem. "A pump failed in the dust" is
  better than "The harsh frontier challenged the limits of industry."
- Vary rhythm. Some records need three short sentences. Others deserve one
  longer paragraph with names, dates and consequences.
- A small dry joke about warehouse capacity or an unhelpful approval system
  is welcome; don't use one in every entry.
- Let the human story live in details like an empty chair, a crossed-out
  invoice, an emergency stop or a lamp somebody refused to switch off.
- Avoid stock constructions such as "not merely X but Y", "more than just",
  "a testament to", "the language of", "a world that teaches", "the
  expedition learns", "what it means to", and variations of "in a world
  where". Use them only if the phrase is genuinely needed and specific.
- Don't claim the Continuity Engine is magically evil. BLACKOUT-SEVEN is a
  human executive order and the system followed inherited bad authority.
- Avoid repeating the same lesson about voluntary cooperation in every
  mission. The archive already contains several well-grounded examples.
- Preserve the mod authors' actual terrain, recipes, achievements and
  hazards. Razi can add context, not replace their story with invented lore.

## Current starmap facts

- Aegis is the **shared southern frontier** reached from Solaris and Nyxaris.
  It is not part of northern Deep Space.
- Aegis route: Frontier Gate → Outer Edge → Inner Edge → Point Warden.
  Near Bellicos Orbit is a side survey. The far-side Bellicos stargate was
  removed; don't describe it as a destination.
- Vibrant: Fulgora, Ribbonia and Khemia are **inside** the metallic asteroid
  belt; Paracelsin and Shchierbin are **outside**. Its actual crossing runs
  between Inner Rim and Outer Rim, near the southwest debris band.
- Khemia is reachable from **Ribbonia**. Do not place its spur at Paracelsin
  or claim that it is beyond the belt.
- Northern Deep Space is separate: Nexus → Oort Cloud → Sol, the Black Hole
  branch, and the Shattered Planet expedition.
- Convergence is a physical five-shipment endgame with independently powered
  witnesses. Research alone does not complete any delivery.

## Editing safely

Keep Factorio locale section names and keys unchanged. They are used by
Lua and existing save games. Keep `__1__` placeholder tokens, Factorio
rich-text tags and source game mechanics intact. English journal strings live
in `locale/en/razi_journal_*.cfg`; the planet field notes and primary
location prose live in `locale/en/names.cfg`.

Run `python -m unittest discover -s tests -p 'test_*.py'` and the Lua
journal/description fixtures before a release. These are source checks, not
a substitute for opening the full modpack in Factorio.
