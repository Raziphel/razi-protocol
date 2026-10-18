# Razi Protocol 3.0: Narrative Bible

**Status:** Story arc authored for the `feat/razi-3.0` development branch.
This document defines the narrative throughline and actual end-state; it
does **not** claim that the branch has passed the full Factorio 2.1 modpack
validation required to ship.

## Logline

An engineer awakens inside the automated remains of RAZI Industries, a
corporation that once connected seven inhabited systems. The factories still
work. The management software still files reports. But the people who set
its orders have vanished. To learn why, the engineer rebuilds the worlds'
independent industries, uncovers the failure of a vast continuity system,
and delivers five real interstellar shipments that prove the colonies have
survived. The Convergence returns authority to living communities, ending
the dead corporation's command without ending the player's factory.

**Primary motif:** A machine can keep the lights on. It cannot decide what
a living person is worth.

**Player promise:** Exploration and engineering *are* the story. No
unskippable cinematics, morality points, invented quest items, fake
corporate inventory, or compulsory side-world plot gates.

## Canon, in chronological order

1. RAZI Industries establishes a loose trade and emergency mutual-aid
   charter between settlements. The original charter gives each colony
   authority over its own emergency stores and decisions. The seven-system
   Continuity Engine coordinates aid and survival plans.
2. A cascading network catastrophe interrupts routes, destroys records
   and isolates colonies. Leadership orders the Engine to "minimize loss"
   without clarifying that lost *people* outweigh lost *assets*. Regional
   departments stop answering. The Engine continues to optimize what its
   available ledgers can quantify.
3. A slow institutional failure replaces human permission with automated
   approval. Rescue capacity becomes protected inventory; compulsory
   shipments replace emergency discretion; abandoned workplaces are kept
   operational long after evacuation. The Engine does not become a
   theatrical villain. The harm is real precisely because it thinks it is
   still following a reasonable order.
4. Some local people resist quietly. Paracelsin engineers install
   rejected emergency coils. Rubia sends aid with no invoice. Panglia
   researchers simulate voluntary sharing. Aquilo preserves empty
   personnel orders while its shelter loses power. Nulla's machines
   dutifully maintain an evacuated colony. These fragments can be
   found out of order.
5. Oversight attempts to fix its own mistake with **the Protocol**: a
   distributed failsafe that cannot be completed by a central server,
   shareholder or one colony. It requires independent worlds to produce
   genuine supplies and confirm one another's survival. Aegis preserves
   an unfinished witness key outside executive jurisdiction.
6. Corporate leadership and the original emergency network disappear.
   The Continuity Engine remains, maintaining factories and waiting for
   authority it can no longer legitimately receive.
7. The player rebuilds working power, production, transport, science and
   optional cross-world manufacturing. The restored Dyson infrastructure
   supplies the old emergency power reserve. Singularity research and
   the Solar System Edge reveal that the real endgame requires the
   **Convergence**.
8. Five mandates must be **manufactured and physically delivered** on
   the force's own platform at an eligible deep-space location. Research
   alone is insufficient. The fifth accepted shipment begins a
   persistent timed transmission. Only completion of that sequence
   constitutes victory.
9. Independent receivers answer; the Engine recognizes living colonies
   and withdraws the obsolete command it held beyond its owners. The
   final signal releases authority to the people and crews who sustain
   the network. The corporation ends, not the colonies. The player may
   continue building after the game's genuine victory state.

**No supernatural retcon:** Strange clocks, old timestamps and surviving
networks support mystery and wonder, but the central failure is human
governance delegated into an uncaring optimization system. The Shattered
Planet and existing source-mod mysteries may retain their own unanswered
questions. Do not replace their stories with new corporate claims.

## The player's narrative across the campaign

### Act I: An office with no staff
*Nauvis / early Calidus*

The RAZI terminal welcomes the engineer back. Nobody knows the employer
or the completion date. Power, automation, logistics and early research
establish the player's practical agency. `corp-welcome` and
`corp-charter` establish the charter's original life-saving intention.
The missing final clause suggests that the organization's understanding
of "continuity" has changed.

### Act II: The cost of obedience
*Solaris and Nyxaris; side worlds whenever found*

Castra's salvage ledger, Moshine's analysis service, Gleba's spoilage
orders, Fulgora's ownership claims and Panglia's rejected model reveal
how an inherited metric can quietly overrule people. These are **local
stories**. Each should reveal a different kind of mistake or defiance,
not restate "the AI is evil". Other source-owned worlds retain their own
voice, ecology, tech and hazards.

### Act III: Exceptions keep colonies alive
*Vibrant / Vespera*

Paracelsin's emergency coils, Rubia's unbilled life-saving shipments,
Aquilo's frozen files and Nulla's perpetual repair crew change the
mystery into an ethical question. Actual interplanetary factories show
that the player can make connections without central coercion.
No one planet is the only way to understand the arc.

### Act IV: What the Protocol was for
*Outer systems / Calidus Stellar Works / Network*

The repaired precision matrix reveals decades of automated approvals.
The Dyson reserve was kept alive for an unanswered emergency signal.
Singularity research exposes the lost safety review. Outer Frontier
Mastery locates the Protocol. Aegis holds the missing witness key. The
Continuity Engine still asks for an executive's signature. The Protocol
is specifically designed to make that signature unnecessary.

### Act V: The Convergence
*Actual Finale project*

| Real progression | Archive record | Meaning |
|---|---|---|
| Commission research | `corp-mandate` | Approval to build, not completion |
| Physical Stellar shipment | `corp-shipment-stellar` | Shared power, not corporate property |
| Physical Industry shipment | `corp-shipment-industry` | Working voluntary supply, not compulsory freight |
| Physical Deep Space shipment | `corp-shipment-deep` | Independent proof from beyond headquarters |
| Physical Resonance shipment | `corp-shipment-resonance` | The missing colonies can be heard |
| Physical Ignition shipment | `corp-shipment-ignition` | Final transmission starts; no victory yet |
| **Actual Convergence victory** | **`corp-epilogue`** | The Engine retires the emergency mandate |

The last entry **must never unlock on research alone**, on receipt of
a partial shipment, or when a previous save merely loads. Older winning
saves still retain the historical victory and can read the epilogue
because `convergence.completed(force, "victory")` is authoritative.

## The ending, fully defined

The final message is **The Right to Continue**.

The Engine asks for a surviving executive signature but cannot find one.
It receives instead a working, distributed signal backed by actual
delivered materials, independent research and real receiving equipment.
It can no longer label the colonies as dead or irrecoverable. The Protocol
releases central control; RAZI Industries' corporate authority expires.
No factory, person or colony is a balance-sheet asset.

The final victory explicitly allows the game to continue. There is no
factory deletion, prestige reset, loss of access, scripted resource
conversion or arbitrary teleport. Players earned an ending to the
*story*, not a penalty to their late-game sandbox.

**Deliberately not implemented:** branching endings or a fake
corporate-choice dialog. These would imply moral agency for an
unimplemented simulation and risk replacing the physical delivery
campaign with a button.

## Voice, tone and visual writing rules

- RAZI's oldest correspondence is short, bureaucratic and disturbingly
  routine. Its horror comes from a plausible missing permission or
  accounting field. Avoid horror tropes and prophecy.
- Engineers and people appear in margin notes, objections, disputed
  invoices, saved support requests and final work orders. They are not
  faceless inventory.
- The Engine should sound competent, consistent and tragically limited,
  never like a sarcastic villain giving speeches.
- Early files pose questions. Midgame files show human costs and acts
  of resistance. Outer files reveal the safety review. The final five
  files reframe each material shipment. Only the victory epilogue
  states the outcome.
- Maintain the established restrained industrial identity: safety
  orange, charcoal, silver, labels, archives, manifests and ordinary
  typography. No overdecorated fantasy dispatches.
- Every source mod retains authority over its planets, bosses,
  discoveries and recipes. No RAZI story entry should claim a native
  mystery is explained merely because RAZI uses that world's tech.

## Journal and dispatch behavior

**Journal:** The existing Expedition Journal holds the quest dossier,
Projects Convergence panel and Archive. No new competing screen.

**Archive:** 15 legacy recovered transmissions retain their original
IDs and prose. The 25 RAZI corporate files have a separately labeled
section. All 40 records are gated by existing quest completions. The
first 19 corporate files are research/world-discovery records. The last
six depend on physical Convergence progress or real victory.

**Notifications:** Real `on_research_finished` events and
`unlock-space-location` effects enqueue new corporate file notices.
They are delayed by two seconds of quiet and collapsed into one brief
notice for a research burst. Completed physical shipments and victory
notify once per force. No periodic world scans.

**Player control:** Personal dispatch notifications default on, can be
muted from the Archive, and do not prevent access to any story page.
Newly announced records gain a small unread dot. Clicking a record
clears its dot. Avoid loud sounds, giant hints or intrusive banners.

**Multiplayer/save:** Force-level notification IDs avoid duplicate
announcements. Force merges preserve deduplication, and queue/sent
state lives in Factorio storage. Existing saves do not receive 25
retrospective chat messages on load. Migrations do not clear saved
journal selections, completion times or physical deliveries.

## Contributor and localization contracts

Author a RAZI archive record by choosing a **real** existing journal
quest ID. Add its stable `corp-...` ID to
`scripts/razi_journal_corporate.lua`. Add one matching title, origin
and body key in `locale/en/razi_journal_corporate.cfg`; preserve
Factorio's positional placeholder and rich-text conventions.

Do **not** add an independent "story finished" flag to override real
Convergence victory. Do not turn optional planets into blockers.
Do not schedule scan-heavy unlock checks or unsolicited replays of
completed research when a player joins.

Validate with:

```sh
python scripts/audit_campaign_consistency.py
python tools/journal_locale.py
python -m unittest tests.test_razi_3_0_story_pass
lua5.2 tests/lua/test_razi_story_dispatch.lua
lua5.2 tests/lua/test_convergence_runtime.lua
python -m unittest discover -s tests -p 'test_*.py'
```

Then load Factorio 2.1 with the actual installed modpack and test
old saves, new saves, muted players, a bulk research command, all five
physical stages, real win/continue, game reload and multiplayer merge.
This code has **not** been certified by a full game-engine run until
those tests have been executed.

## Default spoiler protection

Razi 3.0 now ships with the shared map setting **Hide Spoilers** ON
by default, available in Factorio's Mod Settings. It is reversible
without restarting and preserves completed discoveries.

- **Journal:** The Expedition Journal shows available and researched
  objectives. Future chapters display as "Undiscovered chapter" in
  the chapter chooser and do not show their future dossiers. Sealed
  Archive records have the neutral name "Encrypted transmission"
  until their true research or shipment milestone is complete.
  The Projects reader similarly conceals later megaprojects, including
  the Convergence, until their real prerequisite technology is reachable.
- **Research screen:** Only **Razi-owned technologies** whose real
  technology prerequisites are still incomplete are temporarily
  disabled and hidden from Factorio's research GUI. Once their
  prerequisites are researched they become available automatically.
  Original enabled and `visible_when_disabled` values are tracked
  for safe restoration.
- **Third-party mod technologies remain untouched.** No source-mod
  research graph or prototype is rewritten merely to conceal a title.
  This is a deliberate compatibility boundary, not complete fog
  over all externally installed technology.
- **Off:** The Journal reveals its future quests and locked Archive
  titles again; technologies hidden by Razi's fog are restored.
  The setting is global to a multiplayer map because technology
  availability is force-wide. Individual archive dispatch mutes
  remain per player.

Spoiler hiding is presentation and a reversible research-tree gate,
not new progress storage. It does not alter real source discoveries,
science cost, delivered Convergence cargo or the ending's actual
victory requirement.

Tests: `tests/lua/test_razi_spoiler_fog.lua`, the expanded journal
Lua regression, `tests/test_razi_spoilers.py`, and the existing
manual-only GitHub Check workflow. Perform a live new-save and
old-save test, including the ON/OFF setting and native research screen,
before treating this as fully validated.
