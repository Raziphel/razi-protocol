-- Official source-owned Big-Monsters activation and surface registry.
-- Triggered on init/configuration/surface creation; NEVER on tick.
-- We cannot assign other mods' runtime-global setting values.
local M={}
local difficulty=require("scripts.razi_difficulty_presets")
-- Source-owned native difficulty level. Razi can request the adjustment,
-- but cannot write Big Monsters' saved runtime-global setting.  The public
-- source does not expose this setter yet; missing methods are safe no-ops.
local source_levels={hard=5,nightmare=7}
function M.target_level()
 local preset=difficulty.selected()
 return source_levels[preset]
end
local function api(action,...)
 if not (remote and remote.interfaces
   and remote.interfaces["bigmonster"]
   and remote.interfaces["bigmonster"][action]) then return false end
 local ok,err=pcall(remote.call,"bigmonster",action,...)
 if not ok and log then
   log("[Razi Protocol] Big-Monsters API "..action..": "..tostring(err))
 end
 return ok
end
function M.active()
 return difficulty.effective("razi-big-monsters-events",false)==true
end
function M.surface(surface)
 if not (M.active() and surface and surface.valid and surface.planet
   and not surface.platform) then return false end
 return api("add_surface",surface.name)
end
function M.sync()
 if not (script and script.active_mods and script.active_mods["Big-Monsters"]) then return false end
 -- Only the owning mod may adjust the true difficulty level. An optional
 -- remote interface provides this without rewriting foreign settings.
 local requested=M.target_level()
 if requested then api("set_difficulty_level",requested) end
 local mode=difficulty.active()
 if mode=="custom" then
   -- Explicit custom settings own the source toggle, but a manual RP3
   -- "enabled" choice is still honored. Don't override user's source on/off.
   if M.active() then api("on") end
 else
   api(M.active() and "on" or "off")
 end
 if M.active() and game and game.surfaces then
   for _,surface in pairs(game.surfaces) do M.surface(surface) end
 end
 return true
end
return M
