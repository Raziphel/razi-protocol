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
   and isolates colonies. The initial disaster is real; the continued isolation
   is deliberate. In sealed Directive BLACKOUT-SEVEN, the Executive Board
   orders surviving humanitarian routes disconnected to protect corporate
   control. Leadership orders the Engine to "minimize loss"
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
8. Five costly mandates must be **manufactured and physically delivered** on
   the force's own platform at an eligible deep-space location. The final
   mandate also requires seven live 10 MW witness stations across seven
   distinct founding systems and a 50 MW Array Core on the expedition
   platform, as well as the source Dyson receiver grid. Research
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

The Engine asks for a surviving executive signature, and the black box
proves a signature was never missing: the Board had deliberately signed
BLACKOUT-SEVEN and left its reclamation authority dormant in the network.
Restoring the old network without witnesses would have reactivated that
corporate succession key. The Engine was obeying a human directive, not
inventing evil for its own sake.

The Engine requests a new authorized executive successor, but no living
colony appoints one. Instead, seven independent witness stations submit a
working, distributed refusal backed by real delivered materials, research
and powered receiving equipment.
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
section. All 74 records are gated by existing quest completions. The
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
- **Research screen:** Future **Razi-owned technologies**, plus future research from other mods when its separate setting is enabled, whose real
  technology prerequisites are still incomplete are temporarily
  disabled and hidden from Factorio's research GUI. Once their
  prerequisites are researched they become available automatically.
  Original enabled and `visible_when_disabled` values are tracked
  for safe restoration.
- **Third-party prototypes and research graphs remain intact.** The
  expanded spoiler option temporarily conceals unresearchable external
  technology rows and restores their previous enabled/visibility state
  when turned off. If a source mod has dynamic unlocks, disable the
  expanded fog without disabling Journal protection.
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

## Spoiler control and the first-contact welcome

Do not reveal the Convergence finale in startup notices. The new
welcome provides only the scale of the expedition, Journal shortcut,
website, wiki and Discord. Spoiler concealment is default ON for
the Journal and technology tree, with an independent switch for future
research from other planet mods. This changes visibility only where
research is not yet reachable by legitimate prerequisites.

A new map's optional one-time console cleanup is intentionally
per-player and can remove important third-party warnings. Never attempt
to intercept or rewrite individual other-mod chat messages.

## 3.0 Field Accounts: the people behind the reports

The original 25 corporate case files remain stable, with the same
research/physical-shipment gates and unchanged final epilogue.
**Eighteen additional FIELD accounts** are interleaved among the
older cases rather than placed after the ending. This brings the
RAZI Industries collection to 59 files, and the entire Archive to
74 when counting 15 legacy transmissions.

These are **fictional RAZI Industries annotations**, not retcons of
Rubia, Nexuses, planetary mods' own canon or new simulated NPCs.
Every account belongs to an existing research milestone or actually
discovered planet; optional worlds can be explored in any order.

Three human signatures provide quiet continuity:

- **Rhea Calder** appears in the chemical night-shift report,
  prioritizing a shelter over quarterly production, and later in
  the rescue charter's marginal notes. The system logs both decisions
  as exceptions. They are, in fact, continuity.
- **Noor Halden** reserves a seat for an absent apprentice during
  the first orbital departure. Years of records later the same
  dispatch signature changes a transceiver test's reply destination
  to **ALL RECEIVERS** instead of corporate headquarters. Her final
  act does not take authority; it asks who is there.
- **Sera Ilyan** reroutes mail to people on Muria rather than
  corporate departments. An abbreviated signature on a voluntary
  industrial exchange appears elsewhere. Local commerce is no longer
  measured only by invoices.

Field reports from Vulcanus, Rabbasca, Foliax, Cerys, Khemia,
Maraxsis and Athos add other everyday moments: ignored safety
reports, aid to neighbors, unofficial family records, a beacon
left operating for an unknown ship, and maintenance that kept
workers safe. The robots, alliance industries and frontier
charter reveal how those acts could become distributed operational
resilience. The optional Nexus addendum carefully preserves
uncertainty rather than overwriting source-mod mythology.

**Narrative rule:** Each discovered file must stand on its own. A
repeat signature rewards attentive reading but cannot become a
hard prerequisite for understanding the Protocol or the ending.
The original Convergence Commission is permission to build,
not victory; the five real freight mandates plus timed signal
still exclusively control the final epilogue.

## How the expanded Archive works

The Archive now separates **FIELD ACCOUNT / PERSONAL
CORRESPONDENCE** from formal internal records through a small
document classification on each reader page. In spoiler mode,
unopened titles never appear and sealed records collapse into a
single neutral count instead of dozens of blank rows. With
spoiler hiding OFF, locked titles can still be previewed.

On a real research discovery, a field account emits one concise
**RAZI / FIELD CORRESPONDENCE** notification. Ordinary case files
and physical Convergence transmissions retain their distinct
archive/mandate notices. Bursts stay batched; personal mutes and
unread markers still work. Each completed milestone with an associated FIELD account now also shows a direct **Recovered Correspondence** link in its quest dossier. The link resolves only to a genuinely unlocked archive record, never a locked future file. The **Read next unread** button moves
the player through completed, unread records and never opens one
whose real quest is incomplete.

The new welcome is an **Expedition Terminal** message, not a
story spoiler: it shows only the operation level supported by
this force's *researched* automation, platforms, logistics or
Convergence Commission. It reports the current player's unread
Archive count, the verified Journal shortcut, website, wiki
and Discord, plus an optional admin testing line. Existing
per-player welcome/console-clear settings and replay command
remain intact; Factorio still cannot selectively suppress the
source mods' startup warnings.

## Witness network: sixteen additional recovered field accounts

The 3.0 Archive now comprises **74 source-gated documents**:
15 legacy expedition transmissions, 25 original corporate case files
and **34 independent field accounts**. This pass contributes 16
additional human records with real unlocks, not custom collectibles.

The story deliberately continues established names instead of
introducing an omniscient narrator. Rhea Calder reappears in the early
Nauvis blackout and the late singularity-test safety amendment.
Noor Halden's emergency circuit idea resurfaces as a fallback relay
that permits independent colonies to communicate without headquarters.
Sera Ilyan's unapproved local delivery routing already exemplifies
the same principle in ordinary life. These are optional recurring
threads, **not** mandatory reading or a fixed planet visit order.

Each new field account is a complete local incident: Arig's water
register, Hyarion's rescue run, Apia's conservation decision,
Ribbonia's repair, Maraxsis's Seadragon beacon, Abacayba's message,
Crucible's shelter valve, Vesta's navigation, Frozeta's missed
human-status field, the solar watch, Panglia's cooperative model and
the materials standard. Side-world records never claim to define
the source mod's entire history. A player arriving on any planet
first should understand its account independently.

The first 23 quest-story passages were rewritten or expanded to
reinforce this same industrial ethics theme during normal gameplay,
rather than keeping all narrative behind Archive navigation.
Research milestones and source-owned world discovery remain the
only triggers. No new chapter, research node, resource, item,
cutscene, timer or manufactured shipment is involved.

**Archive UX:** the navigator now has separate recovered counts for
legacy transmissions, corporate case files and personal accounts;
filters for each group; and an explicit **View discovery** link
from an unlocked letter to its real source milestone. Filter state
is a player's UI preference, not story progress. Hide Spoilers still
conceals titles until their actual source-backed quest completes.

**Startup terminal:** keeps the `○ ! RAZI PROTOCOL` identity and
shared website/wiki/Discord links, now adding a real researched-state
field directive. The spoiler-cover status is read from the current
map setting rather than promising that spoilers are hidden even
when the player has switched the option OFF. The welcome remains
once per user on a save; replay is explicit via `/razi-welcome`.

## In-world starmap copy and spoiler boundaries

The in-game planet and corridor notes are the field-facing voice of RAZI's old freight network. On planets, use one vivid environmental detail and one actual logistics or research purpose; on curated routes, use a short freight dispatch explaining what the connection enables. Avoid declaring native source-mod secrets to be RAZI inventions.

Keep this copy less revealing than Archive records: old ledgers, abandoned infrastructure, material shortages and lost decision-makers may be mentioned, but not the Continuity Engine's final resolution, the physical Convergence shipments or the ending. These notes are append-only to source planet descriptions, route-only on verified endpoint pairs, and available in English and Russian.

## Great Projects: the recovered array (October 2026)

Four new Projects add verified physical accomplishments: Skybridge's two-world native catapult infrastructure and signed delivered freight receipt; Beltbreaker's two genuine route crossings; a powered Archive Array spanning three different systems; and a large, defended production Ark reaching Deep Space. None creates free science or a planetary bypass.

The Array's three recovered messages appear as separate entries in the existing Archive navigation and remain unlocked for the force after physical receivers are removed. They foreshadow the unresolved Continuity records without explaining away Convergence. Corporate voice stays restrained: log timestamps, missing personnel signatures and archival orders, not a new omniscient narrator.

Skybridge's sealed manifest proves goods were physically carried between two installed catapult endpoints while a RAZI regional link exists, but **does not prove that the Orbital Catapult itself fired or transported the item**. The source mod has no publicly documented delivery callback suitable for that claim. If its physical devices cannot be identified by their actual source prototype names, the project deliberately reports that it cannot verify them rather than inventing progress. Native transportation and all third-party science remain controlled by their authors.

## Revised major twist: BLACKOUT-SEVEN and the Witness Accord

The first network disaster was real, but the isolation that killed real people was a **deliberate corporate order**. This is only disclosed after the third physically completed Mandate. The fourth Mandate reveals the second half: the Convergence as originally signed would have reactivated the dormant executive reclamation key. A dissident engineering team hid an independent seven-system countersignature into the cargo process. **No one person, including the player, can become the new owner.** The seven physically powered stations are how people reject the order without giving that power to the player instead. The final broadcast revokes the claim; it does not magically delete the Engine or its evidence.

The original five physical mandates remain in their original order but the first four now demand 24, 30, 18 and 12 manufactured units (previously 8/10/6/4); Ignition remains a three-part unique assembly with considerably more manufacturing overhead. Convergence research counts increase, with an additional Witness Accord technology after Synchronization and before Ignition. Researching the tech unlocks the RAZI Witness Anchor (10 MW), while Ignition unlocks the expedition-mounted Seven-Sun Array Core (50 MW).

The seven stations must simultaneously be **built and powered**, one on a real planet within each founding system: Calidus, Solaris, Nyxaris, Vibrant, Vespera, Beetlejuice and Umbra. Real planet-to-system mapping comes from the installed galaxy catalogue; multiple anchors in one system do not satisfy another. The final Core is physically installed and powered on the force's deep-space delivery platform. The final shipment is rejected without those prerequisites, and no inventory is consumed. Older forces with already-recorded victory keep their success and ending.

The transmission now lasts two minutes, with dispatches at 0/30/60/90 seconds, rather than a 12-second cutscene. The recovered black-box evidence appears in the Convergence dossier only after real shipments; corporate Archive records expand the same reveal. The twist is intentionally unspoiled in initial planet and route descriptions, onboarding, quests and the Project cover. No branching endings, false morality choices, teleportation, new planetary biome or artificial entity scans on every tick.

### Seven independent testimonies

Each live 10 MW witness anchor reveals one otherwise inaccessible archival testimony in the Convergence reader. The sources are specific to Calidus, Solaris, Nyxaris, Vibrant, Vespera, Beetlejuice and Umbra. No two stations share a generic witness statement, no testimony unlocks from research alone, and only the final verified cross-system accord can permanently revoke BLACKOUT-SEVEN. The different testimonies reinforce that systems contributed their own independent proof rather than submitting to a new central ruler.

### The completeness of the Outer Expedition

The final Convergence Accord also requires in-person witness passage throughout every installed navigable Deep Space destination, including the dangerous distant branches past Nexus, the Black Hole and the Shattered Planet when those routes exist. The engineer and fellow crew physically follow the old isolation routes rather than reading a research tick from a desk. This broadens the twist: the corporate BLACKOUT-SEVEN quarantine did not simply sever administrative communications; it stranded real explorers and destroyed the evidence trail across those far reaches. Only expedition crews who confront the full route network can sign the final testimony. No remote view, atlas progress, uncrewed platform or nonexisting optional world can satisfy the requirement. The final UI lists outstanding locations without pretending to know undocumented historical visits.

### Only one campaign ending

The seven-system Accord is the sole intended Factorio-level victory.
The Black Hole expedition, Nexus boss trials/Silence, optional outer
missions, K2SO's transceiver and the original Space Age route finale
retain their achievements, research, rewards and story consequences,
but none should mark the **entire campaign won**. Only Convergence's
actual, validated final transmission invokes Factorio's native win state.
Compatibility uses the source mods' documented opt-outs. Unsupported
direct game-state calls are monitored for recovery, not patched by
silently deleting the mods' gameplay.
