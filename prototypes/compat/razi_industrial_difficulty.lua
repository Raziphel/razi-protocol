-- Factory speed and wall strength of the difficulty level, for the machines
-- and walls of every installed mod. One data stage pass, from the values the
-- source mods defined; Normal (x1) writes nothing.
--
-- Only what a player builds is scaled: a prototype that an item places, or
-- that gives back such an item when mined (the variants that mods put in
-- place of a machine on some surfaces). Left alone:
--   * assembling machines with a fixed recipe: scanners, construction
--     stages, towers, gas miners, wrecks and other machines whose speed is
--     part of a mechanic of their mod;
--   * prototypes that no item places and no mining returns: map objects,
--     fluid filters and other script helpers;
--   * Balack's bio fabricators on Easy, Hard and Nightmare: their speed
--     follows Balack's own setting (biological_machines_difficulty.lua).
-- Enemy units, turrets and weapons are never touched.
local M={}
local preset=require("scripts.razi_difficulty_presets")
local balack=require("prototypes.compat.biological_machines_difficulty")

local factors={
 throughput={boosted=1.15,normal=1,constrained=.92,strained=.82},
 fortifications={reinforced=1.25,normal=1,fragile=.90,brittle=.78}
}
M.factors=factors

-- The first value a prototype had, so a second call never compounds.
local originals=setmetatable({},{__mode="k"})

-- The entities some item places (place_result) or that name their item
-- themselves (placeable_by), and the items that place something.
local function placeable(raw)
 local entities,items={},{}
 for _,group in pairs(raw or {}) do
  if type(group)=="table" then
   for name,proto in pairs(group) do
    if type(proto)=="table" then
     if type(proto.place_result)=="string" then
      entities[proto.place_result]=true
      items[name]=true
     end
     local by=proto.placeable_by
     if type(by)=="table" and (by.item or by[1]) then entities[name]=true end
    end
   end
  end
 end
 return entities,items
end

local function mined_items(proto)
 local minable=proto.minable
 local found={}
 if type(minable)~="table" then return found end
 if type(minable.result)=="string" then found[#found+1]=minable.result end
 for _,result in pairs(type(minable.results)=="table" and minable.results or {}) do
  if type(result)=="table" and (result.type==nil or result.type=="item")
     and type(result.name)=="string" then
   found[#found+1]=result.name
  end
 end
 return found
end

local function is_player_built(proto,name,entities,items)
 if entities[name] then return true end
 for _,item in ipairs(mined_items(proto)) do
  if items[item] then return true end
 end
 return false
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
  local entities,items=placeable(raw)
  if speed~=1 then
   local own_speed=balack.covers_speed(settings and settings.startup,
    rawget(_G,"mods"))
   for _,type_name in ipairs({"assembling-machine","furnace"}) do
    local changed,skipped=scale_group(raw[type_name],"crafting_speed",speed,
     function(value) return math.max(.001,value) end,
     function(proto,name)
      return not proto.fixed_recipe
       and not (own_speed and balack.crafts_cubes(proto))
       and is_player_built(proto,name,entities,items)
     end)
    count.factories=count.factories+changed
    count.skipped=count.skipped+skipped
   end
  end
  if health~=1 then
   for _,type_name in ipairs({"wall","gate"}) do
    local changed=scale_group(raw[type_name],"max_health",health,
     function(value) return math.max(1,math.floor(value+.5)) end,
     function(proto,name)
      return is_player_built(proto,name,entities,items)
     end)
    count.defenses=count.defenses+changed
   end
  end
  log("razi-protocol: factory throughput x"..speed.." changed "
   ..count.factories.." machines ("..count.skipped.." fixed-recipe or unbuildable machines "
   .."left out), fortification durability x"..health
   .." changed "..count.defenses.." walls and gates")
 end
 return count
end

function M.data_final_fixes()
 return M.apply(data.raw,preset)
end

return M
