# Interwoven planetary progression

Razi Protocol uses the original planet mods' technologies and scientific
production chains to build a connected seven-system research campaign. This
is an incremental first implementation, not a claim that every upstream mod
recipe has been validated in-engine.

## Research handoffs

| Next destination | Research inherited from earlier planets |
| --- | --- |
| Castra | Vulcanus metallurgy |
| Arig and Hyarion | Castra battlefield science |
| Tellus | Arig compression, Hyarion polishing, Gleba agriculture |
| Corrundum | Tellus bioengineering and pathology |
| Apia / Carnova | Gleba agriculture and Moshine thermodynamics |
| Panglia | Apia/Carnova biology and Moshine research |
| Ribbonia | Fulgora electromagnetics |
| Paracelsin | Ribbonia science |
| Shchierbin | Paracelsin galvanization and Muria chemistry |
| Aquilo | Muria chemistry and Fulgora discovery |
| Rubia | Aquilo cryogenics and the Vespera belt survey |
| Maraxsis | Rubia biofusion and Paracelsin discovery |
| Secretas | Cubium science |
| Frozeta | Secretas branch and Tenebris biology |
| Crucible | Tenebris bioluminescent science |
| Vesta | Crucible science, Cubium discovery and the Umbra belt survey |

The **opening choices stay free**: Solaris and Nyxaris are independent first
expeditions; Arig and Hyarion branch after Castra; Gleba and Moshine are
initial Nyxaris worlds; Fulgora/Muria and Cubium/Tenebris open their
respective paired frontiers separately. Later worlds weave together across
systems, and system tech cards still demand actual science production before
the next frontier opens.

## Research safety rules

- Razi adds no new planets, items, labs or science packs.
- Existing discovery prerequisites remain; only safe new dependencies are
  appended, after `seven_system_gates.lua` has established campaign gates.
- Native science technology is anchored to its production planet and required
  by the next discovery **only when both exist without a research cycle**.
- A later discovery consumes an existing science item only when a recipe makes
  it and **one existing lab can accept its entire set of science ingredients**.
  If not, the technology milestone remains but the unusable research-pack
  requirement is skipped. We never make all labs universal.
- No recommended/optional planet becomes a mandatory dependency.
- Tech IDs, recipe outputs, space routes and native planet production
  restrictions are unchanged. Reloading the pass cannot duplicate links.

## Further work before release

Factorio 2.1 must load the full required modpack, then the complete data-raw
dump needs auditing. Although research cycles and complete-lab combinations
are tested, source mods can have recipes whose inputs are obtainable only
later in the campaign. Those actual material chains need playtesting, with
targeted conditional fixes when verified. Existing saves also need testing.

Implementation: `prototypes/technology/campaign_weave.lua`. Regression:
`tests/lua/test_campaign_weave.lua`.
