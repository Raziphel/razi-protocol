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

### World-generation difficulty across all installed planets

On New Game, RP3 automatically selects **Razi Protocol · Normal** for
fresh installs. Changing the RP3 startup difficulty to Easy, Hard or
Nightmare and restarting automatically selects that named preset instead.
The old Recommended (Auto) and Custom map-generator entries were removed.
The **Custom difficulty** remains in Mod Settings for manual overrides,
where the safe Normal world-generation baseline is used unless players
select a different map profile.

**Before starting a new save**, open Settings > Mod settings > Razi
Protocol and select your difficulty and individual gameplay preferences.
Restart Factorio to apply startup settings, then verify the selected
world-generation profile before generating the map. You can still edit
individual sliders on the Resources, Terrain, Enemy and Advanced tabs.

Map profiles now inspect every registered `autoplace-control` from the
complete loaded modpack. Resources receive separate **frequency, patch
size, richness** changes; enemies receive frequency and size changes;
cliffs and supported tree/water terrain controls receive conservative
frequency changes. Special terrain noises, planetary climate expression
functions, disabled source controls, and other mods' script-defined boss
events are never overwritten. In addition to named preset GUI controls,
the startup-selected profile scales **all already-present controls on
every planet prototype**, preserving planet-specific multipliers and zero
(disabled) entries.

Advanced settings also vary enemy evolution, enemy expansion frequency/
group size, scientific research costs, pollution absorption and pollution
consumption per enemy attack, and asteroid spawning rate (capped at 1.12×
on Nightmare to protect UPS). These are legitimate Factorio map settings,
not periodic scripted scans.

| Map tuning | Easy | Normal | Hard | Nightmare |
|---|---:|---:|---:|---:|
| Resource frequency | 130% | 105% | 82% | 68% |
| Resource patch size | 130% | 108% | 85% | 75% |
| Resource richness | 155% | 120% | 75% | 60% |
| Enemy nest frequency | 48% | 85% | 135% | 170% |
| Enemy nest size | 72% | 100% | 118% | 128% |
| Nauvis starting area | 255% | 165% | 115% | 90% |
| Science cost | 100% | 100% | 125% | 175% |

**Factorio 2.1 limitation:** A `default=true` map-gen preset must not
contain any other fields except `order`. RP3 makes the selected difficulty
the default marker and places its actual prototype defaults into MapSettings
and source planet map-gen controls. Other named profiles carry explicit,
fully editable mapgen data. There is no post-start world mutation.
A manually chosen map profile does not write RP3 startup difficulty.
The base game Freeplay scenario remains unchanged, other mods' claimed
defaults take precedence, and opting out via **Select Razi's map preset by
default** preserves the vanilla selection.

For compatibility, player-modded planets with custom noise functions can
still diverge from percentage sliders. Always visually test the generated
planet, because frequency/size/richness scaling cannot guarantee exactly
those output quantities. Existing saves retain generated terrain; no forced
regeneration of explored chunks. Changes should be verified in the full
Factorio build before multiplayer rollout.
