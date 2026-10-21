# Big Monsters: native difficulty level integration

## Requested mapping

| Razi difficulty | Big Monsters `bm-difficulty-level` |
|---|---:|
| Easy | Leave the source value unchanged |
| Normal | **Leave the source value unchanged** |
| Hard | **5** |
| Nightmare | **7** |
| Custom | **Leave the source value unchanged** |

**The previous boss HP prototype scaling has been completely removed.**
No monster health, attack damage, event frequency, evolution thresholds,
belts, recipes or optional gameplay toggles are modified by this integration.

## Engine/API limitation and current status

`bm-difficulty-level` is Big Monsters' **runtime-global Map setting**
(range 1–10; source default 1). Its `control.lua` copies that setting
to `storage.difficulty_level` in `ReadRunTimeSettings()`, which drives
wave counts, invasion size, certain monster health calculations, and
other *native* difficulty effects.

Factorio only allows each mod to write its **own** runtime settings.
Razi Protocol therefore **cannot** assign
`settings.global["bm-difficulty-level"] = {value=5}` or `{value=7}`.
The existing public Big Monsters `bigmonster` remote interface
contains event creation, planet/surface registration and other
functions, but NO method that sets its stored difficulty.

The Razi integration bridge now computes exactly 5 or 7 and will call
`remote.call("bigmonster", "set_difficulty_level", level)` **only when
that function exists**. As of the inspected public source, it does
not exist. Thus the requested values are **not yet applied
automatically by the published Big Monsters release**. No fabricated
Razi-side enemy balancing substitutes for the real setting.

The installed Big Monsters release is 2.2.1, while the publicly
available source mirror inspected is 2.1.2. Validate any owner-side
change against the actual 2.2.1 code.

## Owner-side native Lua implementation

Big Monsters' own source can implement the behaviour in Factorio's
standard `.lua` files without an external executable or launcher.
There are two legitimate ways:

**Preferred: direct Razi-aware source integration.** In Big Monsters'
`ReadRunTimeSettings()`, immediately after its line loading
`storage.difficulty_level = settings.global["bm-difficulty-level"].value`,
add:

```lua
local rp = settings.startup["razi-difficulty-preset"]
if script.active_mods["razi-protocol"] and rp then
  if rp.value == "hard" then
    storage.difficulty_level = 5
  elseif rp.value == "nightmare" then
    storage.difficulty_level = 7
  end
end
```

This applies the source's own wave/event logic, not a facsimile. It
never writes the player's saved Map setting. All other Razi modes
retain Big Monsters' native `bm-difficulty-level`. It also survives
Big Monsters' `on_runtime_mod_setting_changed` refreshes.

**Optional remote adapter:** If Big Monsters instead adds
`set_difficulty_level(level)` to its `bigmonster` remote interface,
Razi's existing bridge will call it on init/configuration. The source
implementation must update `storage.difficulty_level` **inside Big
Monsters** and ensure that later setting-change events do not reset
the override. An owner patch is still required.

The Big Monsters mod portal lists the source as unavailable and its
license is CC BY-NC-ND 4.0; do not redistribute a modified build without
the author's permission.

## Verification

- Launch Big Monsters 2.2.1 with Razi Protocol and confirm 5 on Hard,
  7 on Nightmare **only after installing a cooperating source version**.
- Test Normal, Custom, and Easy with manually configured source values
  such as 2 and 9; neither the Razi bridge nor source adapter may change
  them.
- Confirm Big Monsters' real invasion sizes and event behaviour respond
  to its internal `storage.difficulty_level`, and saved source Mod
  Settings remain unchanged.
- Test save/load, configuration changes, multiplayer, and repeated
  runtime setting changes.
- Razi bridge tests should verify no remote calls if the setter does
  not exist and no calls for modes other than Hard/Nightmare.

Source references:
- [Factorio LuaSettings API](https://lua-api.factorio.com/latest/classes/LuaSettings.html)
- [Big Monsters portal](https://mods.factorio.com/mod/Big-Monsters)
- [Public 2.1.2 control.lua mirror](https://github.com/FactorioParanoidal/ParanoidalModpack/blob/master/mods/Big-Monsters/control.lua)
