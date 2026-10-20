# RP3 Difficulty Director and curated Freeplay map

## Modes and manual overrides

- **Normal (default):** all RP gameplay settings at their original defaults.
- **Easy:** less enemy pressure, easier belts and less disruptive HELIOS.
- **Hard:** stronger enemy populations, tougher logistics, activates
  Big-Monsters through the source mod's published `bigmonster.on` interface.
- **Nightmare:** late research gates and the strongest supported challenge,
  Big-Monsters enabled, severe Nexus ecology and HELIOS.
- **Custom:** effective automatically whenever a supported Razi *gameplay*
  option differs from its original Normal value, or when explicitly selected.
  Factorio cannot physically switch the **displayed startup preset selector**
  while the player is editing the Mod Settings UI. It will still show the
  previously chosen preset, but resolved gameplay uses the manual settings.

The 13 directly managed levers cover asteroid quality/population, belt
threat/resource richness, HELIOS travel/progression/stationkeeping/coronal
surges, enemy density, Nexus severity, Big-Monsters event activation, and
Razi's optional planetary integration setting. Eleven additional material
gameplay switches are *watched* for Custom detection but left independent
because silently toggling structural technology and recipe integrations
would be dangerous for existing campaigns. Visual, accessibility and UPS safeguards remain
independent; Nightmare caps asteroid density to **Dense**, never **Swarm**.

### Big-Monsters

- The source `bm-event-days` runtime-global **player-selected interval is
  never rewritten**. Its RP3 new-save default remains 0. An interval of 0
  is not a guaranteed off switch in the source mod.
- RP3 Normal/Easy requests the published `off` interface, Hard/Nightmare
  `on`. If the interface is absent, RP3 gracefully skips the call.
- The published `add_surface` interface includes registered planetary
  surfaces during Hard/Nightmare. New surfaces are registered on creation.
- For scheduled boss frequency, players may still need to adjust
  `bm-event-days` in **Big-Monsters settings**. RP cannot change another
  mod's runtime-global value on their behalf.

### Nexus and other enemies

- Nexus retains vanilla biter and spitter nests and worms, in addition to
  integrated Armoured, Cold, Explosive, Toxic and Arachnid nests.
- Gleba's native egg-raft spawners are source-cloned only for Nexus and
  assigned general enemy placement noise, while retaining their native
  pentapod unit lists, art and AI. No source prototype is modified.
  Valid Vulcanus territory rules are reused for demolishers.
  Both require full modpack chunk-generation validation.
- Other planets receive theme-appropriate packs only when prototypes,
  surface mapgen controls and suitable land tiles are present.
- Edits affect **new chunks**, not already explored land. No per-tick
  enemy spawner scan or scripted boss duplication was added.

### Auto-selected map preset and per-difficulty profiles

With **Select Razi's map preset by default** enabled (the default),
Factorio's New Game screen initially selects `Razi Protocol · Recommended
(Auto)`. The currently effective startup difficulty (Easy, Normal, Hard,
Nightmare, or Normal fallback for Custom) informs the default Nauvis
autoplace controls and map-settings evolution/expansion. No post-start
map generation changes or hidden scenario controller are used.

**Important 2.1 engine limitation:** `MapGenPreset.default=true` may
have only `default` and `order` properties. Thus the auto-selected
entry cannot impose custom `starting_area` or the full resource slider
values by itself. For complete, previewable hand-tuned worlds select
`Razi Protocol · Easy / Normal / Hard / Nightmare / Custom` explicitly
from the New Game dropdown.

Map presets control Nauvis generation and shared base map settings.
Choosing a named map profile does **not** write RP3's startup mod
difficulty; for consistent world/combat difficulty, select the same
difficulty in Mod Settings before restarting Factorio. The Razi default
selection may be disabled to keep the base-game/other-mod default.

The vanilla **Default** and all other named Factorio presets remain
selectable. When Razi auto-selection is enabled the default prototype's
underlying world values reflect the RP3 profile, so selecting vanilla
Default does not guarantee pre-RP3 original baselines.

### Expected New Game behavior

1. Set RP3 **Game Difficulty** in Mod Settings, then restart to apply.
2. New Game initially shows **Razi Protocol · Recommended (Auto)**,
   reflecting the active difficulty's *supported prototype defaults*.
3. For the full curated map-generation sliders, including starting-area
   radius and research-price multiplier, choose the corresponding **Razi
   Protocol · Easy / Normal / Hard / Nightmare** entry from the dropdown.
4. Or select **Razi Protocol · Custom** and edit all map settings manually.

Selecting a map-generation preset does not change your mod difficulty
setting. The auto-selected default and explicit profiles coexist with
Freeplay. Factorio's 2.1 `default=true` restriction prevents the automatic
entry from carrying a full custom `starting_area` and other mapgen
overrides. This is an engine limitation, not a hidden post-start mutation.
Existing worlds retain their already-generated chunks and settings.
