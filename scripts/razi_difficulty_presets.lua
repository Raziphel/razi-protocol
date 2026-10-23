-- Difficulty levels: one startup setting selects a value for every managed
-- lever (a Razi startup setting that a level may set for the player).
--
-- Rules:
--   * Normal is the baseline: every lever keeps the default of its setting,
--     so Normal behaves exactly like a mod with no levels at all.
--   * A lever changed by hand keeps the saved value; the other levers still
--     follow the level.
--   * Custom uses only the saved values.
--   * A lever whose setting is not declared (small test fixtures, settings
--     removed in a later version) is not managed and returns the fallback.
-- Everything is resolved from startup settings, so data and control stages
-- always agree, and nothing here runs per tick.
local M={}

-- Default value of each lever's setting. settings.lua must declare the same
-- defaults (checked by tests/lua/test_razi_difficulty_presets.lua).
M.baseline={
 ["razi-asteroid-difficulty-scale"]="balanced",
 ["razi-asteroid-population"]="standard",
 ["razi-belt-threats"]="standard",
 ["razi-belt-resource-richness"]="standard",
 ["razi-planetary-interdependence"]="balanced",
 ["razi-distributed-technology"]=false,
}

-- Declaration order; the one list every loop walks, so results are stable.
M.managed={
 "razi-asteroid-difficulty-scale",
 "razi-asteroid-population",
 "razi-belt-threats",
 "razi-belt-resource-richness",
 "razi-planetary-interdependence",
 "razi-distributed-technology",
}

local function copy(source)
 local result={}
 for key,value in pairs(source) do result[key]=value end
 return result
end

-- Dense is the ceiling for Hard and Nightmare: Swarm is an avoidable UPS
-- risk in multiplayer.
M.presets={
 easy={
  ["razi-asteroid-difficulty-scale"]="balanced",
  ["razi-asteroid-population"]="sparse",
  ["razi-belt-threats"]="relaxed",
  ["razi-belt-resource-richness"]="rich",
  ["razi-planetary-interdependence"]="balanced",
  ["razi-distributed-technology"]=false,
 },
 normal=copy(M.baseline),
 hard={
  ["razi-asteroid-difficulty-scale"]="challenging",
  ["razi-asteroid-population"]="dense",
  ["razi-belt-threats"]="severe",
  ["razi-belt-resource-richness"]="scarce",
  ["razi-planetary-interdependence"]="deep",
  ["razi-distributed-technology"]=true,
 },
 nightmare={
  ["razi-asteroid-difficulty-scale"]="relentless",
  ["razi-asteroid-population"]="dense",
  ["razi-belt-threats"]="severe",
  ["razi-belt-resource-richness"]="scarce",
  ["razi-planetary-interdependence"]="deep",
  ["razi-distributed-technology"]=true,
 },
}

local function saved(name)
 local startup=settings and settings.startup
 local item=startup and startup[name]
 if item==nil or item.value==nil then return nil end
 return item
end

-- The selected level: easy, normal, hard, nightmare or custom.
function M.selected()
 local item=saved("razi-difficulty-preset")
 local name=item and item.value or "normal"
 if name=="custom" then return "custom" end
 return M.presets[name] and name or "normal"
end

-- Levers whose saved value differs from the baseline, in declaration order.
function M.manual_overrides()
 local found={}
 for _,name in ipairs(M.managed) do
  local item=saved(name)
  if item and item.value~=M.baseline[name] then found[#found+1]=name end
 end
 return found
end

-- The level the player gets: a named level with a lever changed by hand is
-- reported as custom, whatever the other levers do (see effective).
function M.active()
 local choice=M.selected()
 if choice=="custom" then return choice end
 if #M.manual_overrides()>0 then return "custom" end
 return choice
end

function M.is_overridden(name)
 local item=saved(name)
 return item~=nil and M.baseline[name]~=nil and item.value~=M.baseline[name]
end

-- The value the game uses for a lever. Also fine for settings that are not
-- managed: they return the saved value, or the fallback when missing.
function M.effective(name,fallback)
 local item=saved(name)
 if item==nil then return fallback end
 local selected=M.selected()
 if selected=="custom" or M.is_overridden(name) then return item.value end
 local preset=M.presets[selected]
 if preset and preset[name]~=nil then return preset[name] end
 return item.value
end

return M
