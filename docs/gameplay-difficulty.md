# Razi Protocol difficulty presets (2.1, feat/razi-3.0)

The Razi master preset controls *effective behaviour* in Razi-owned modules;
it is not a game-wide mutation of other mods' player-selected settings.

**Default: Custom**, preserving all existing save/installation choices.
Choosing a named mode requires a Factorio restart because the option is a
startup setting. Advanced individual controls remain visible in Factorio's
settings panel; when a named mode is active, their saved UI values remain
untouched, but the supported effective values below take precedence. Return
to Custom to apply them individually.

| Effective setting | Relaxed | Standard | Hard | Extreme |
|---|---|---|---|---|
| asteroid difficulty scale | balanced | balanced | challenging | relentless |
| asteroid population | sparse | standard | dense | dense |
| belt threats | relaxed | standard | severe | severe |
| belt resource richness | rich | standard | scarce | scarce |
| HELIOS progression | late | late | late | epic |
| HELIOS route danger | challenging | extreme | extreme | extreme |
| HELIOS route distance | extended | extended | marathon | marathon |
| HELIOS commissioning | expedition | expedition | monumental | monumental |
| HELIOS coronal surges | off | occasional | volatile | volatile |

**Safety boundaries:**
- **No performance sabotage:** The Extreme preset deliberately caps asteroid
  population at **dense**, never **swarm**. The other difficulty controls
  increase challenge without forcing avoidable multiplayer UPS spikes.
- **No prototype deletion:** HELIOS construction, unlocked recipe/component
  existence, planet list, mission dependencies and the final Convergence
  victory requirements remain user-controlled. No preset silently disables
  a machine, science tree or physical megaproject.
- **No source mod setting corruption:** Big-Monsters `bm-event-days`
  retains its independent RP3 new-save default of 0. Razi cannot
  programmatically overwrite another mod's selected global mod setting
  at runtime. Third-party adapters must be explicitly audited and opt-in.
- **No presentation changes:** Per-user controls, visuals, text, route-map
  presentation, performance switches, and accessibility are independent.
- **Save safety:** Presets don't rewrite any saved settings or factory
  inventory. Changing startup balance may affect future production/progression;
  back up an existing campaign before switching.
- **Performance:** One constant-size table lookup in data or GUI setup.
  No new every-tick event handlers, world scans or runtime setting writes.

The first pass wires asteroid profiles, real quality distributions and
route colors, stellar routes/research/commissioning, and coronal surges to
the same audited resolver. Extend the mapping only after covering every
consumer of a new setting with regression tests.
