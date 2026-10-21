-- Native multiplier-only Razi difficulty for XY K2SO Enhancements.
-- Source: xy-k2so-enhancements-nulls-fork/patches/technology.lua.
-- Reconcile ONLY its ten hardcoded technology counts after its final fixes.
-- Never turn on source inflation, modify recipes, or change belt speeds.
local M = {}
M.profiles = { easy=0.75, hard=1.5, nightmare=2 }
M.owner = "xy-k2so-enhancements-nulls-fork"
M.hardcoded = {
 "planet-discovery-aquilo",
 "planet-discovery-maraxsis",
 "planet-discovery-paracelsin",
 "planet-discovery-moshine",
 "planet-discovery-secretas",
 "legendary-quality",
 "quantum-processor",
 "kr-intergalactic-transceiver",
 "kr-advanced-card",
 "biolab",
}
local allowed = {["25%"]=0.25,["50%"]=0.5,["75%"]=0.75,
 ["100%"]=1,["150%"]=1.5,["200%"]=2}
local originals = setmetatable({},{__mode="k"})
local function valid(v) return type(v)=="number" and v>0 and v==v and v<math.huge end
function M.apply(raw,startup,enabled)
 raw=raw or (data and data.raw) or {}
 startup=startup or (settings and settings.startup) or {}
 enabled=enabled or mods or {}
 local difficulty=startup["razi-difficulty-preset"]
 local target=M.profiles[difficulty and difficulty.value]
 -- Normal and Custom must NEVER touch foreign prototype values.
 if not target or not enabled[M.owner] then return 0 end
 local toggle=startup["xy-tech-inflation"]
 local scale=startup["xy-tech-inflation-scale"]
 -- Preserve the actual source enable toggle: this is opt-in, not a new mode.
 if not toggle or toggle.value~=true or not scale then return 0 end
 local saved=allowed[scale.value]
 if not saved then return 0 end
 local changed=0
 for _,name in ipairs(M.hardcoded) do
  local proto=raw.technology and raw.technology[name]
  local unit=proto and proto.unit
  if type(unit)=="table" and valid(unit.count) then
   local base=originals[unit]
   if base==nil then base=unit.count;originals[unit]=base end
   -- Source multiplier cancels. Razi changes only the original percentage.
   local desired=math.max(1,math.ceil(base*target/saved))
   if unit.count~=desired then
    unit.count=desired
    changed=changed+1
   end
  end
 end
 return changed
end
function M.data_final_fixes()
 return M.apply(data.raw,settings.startup,mods)
end
return M
