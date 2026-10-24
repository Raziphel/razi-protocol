-- Factory speed and wall strength of the difficulty level, for the machines
-- and walls of every installed mod. One data stage pass, from the values the
-- source mods defined; Normal (x1) writes nothing.
--
-- Only what a player builds is scaled. These are left alone:
--   * hidden prototypes (internal machines and removed duplicates);
--   * assembling machines with a fixed recipe: scanners, construction
--     stages, towers, gas miners, wrecks and other machines whose speed is
--     part of a mechanic of their mod;
--   * prototypes that no item can place: map objects and script helpers.
-- Enemy units, turrets and weapons are never touched.
local M={}
local preset=require("scripts.razi_difficulty_presets")

local factors={
 throughput={boosted=1.15,normal=1,constrained=.92,strained=.82},
 fortifications={reinforced=1.25,normal=1,fragile=.90,brittle=.78}
}
M.factors=factors

-- The first value a prototype had, so a second call never compounds.
local originals=setmetatable({},{__mode="k"})

-- Names of the entities some item places (place_result) or that name their
-- item themselves (placeable_by).
local function placeable(raw)
 local names={}
 for _,group in pairs(raw or {}) do
  if type(group)=="table" then
   for name,proto in pairs(group) do
    if type(proto)=="table" then
     if type(proto.place_result)=="string" then names[proto.place_result]=true end
     local by=proto.placeable_by
     if type(by)=="table" and (by.item or by[1]) then names[name]=true end
    end
   end
  end
 end
 return names
end

local function is_player_built(proto,name,placed)
 return not proto.hidden and placed[name]==true
end

local function scale_group(group,field,factor,round,filter)
 local changed,skipped=0,0
 for name,proto in pairs(group or {}) do
  if type(proto)=="table" then
   local original=originals[proto]
   if not original then original={} originals[proto]=original end
   if original[field]==nil then original[field]=proto[field] end
   local base=original[field]
   if type(base)=="number" and base>0 then
    if filter(proto,name) then
     local value=round(base*factor)
     if proto[field]~=value then
      proto[field]=value
      changed=changed+1
     end
    else
     skipped=skipped+1
    end
   end
  end
 end
 return changed,skipped
end

-- raw: data.raw; resolver: scripts.razi_difficulty_presets.
-- Returns the number of changed machines (factories), walls and gates
-- (defenses) and the machines left out (skipped).
function M.apply(raw,resolver)
 local speed=factors.throughput[
  resolver.effective("razi-factory-throughput","normal")] or 1
 local health=factors.fortifications[
  resolver.effective("razi-fortification-durability","normal")] or 1
 local count={factories=0,defenses=0,skipped=0}
 raw=raw or {}
 if speed~=1 or health~=1 then
  local placed=placeable(raw)
  if speed~=1 then
   for _,type_name in ipairs({"assembling-machine","furnace"}) do
    local changed,skipped=scale_group(raw[type_name],"crafting_speed",speed,
     function(value) return math.max(.001,value) end,
     function(proto,name)
      return not proto.fixed_recipe and is_player_built(proto,name,placed)
     end)
    count.factories=count.factories+changed
    count.skipped=count.skipped+skipped
   end
  end
  if health~=1 then
   for _,type_name in ipairs({"wall","gate"}) do
    local changed=scale_group(raw[type_name],"max_health",health,
     function(value) return math.max(1,math.floor(value+.5)) end,
     function(proto,name) return is_player_built(proto,name,placed) end)
    count.defenses=count.defenses+changed
   end
  end
  log("razi-protocol: factory throughput x"..speed.." changed "
   ..count.factories.." machines ("..count.skipped.." hidden, fixed-recipe or "
   .."unplaceable machines left out), fortification durability x"..health
   .." changed "..count.defenses.." walls and gates")
 end
 return count
end

function M.data_final_fixes()
 return M.apply(data.raw,preset)
end

return M
