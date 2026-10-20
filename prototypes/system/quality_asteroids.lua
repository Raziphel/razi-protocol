-- Inject one lightweight quality carrier per hostile asteroid species.
-- Runs after ALL route authors, Razi balancing and final route visuals.
-- Resource chunks are never altered. The carriers are immediately replaced
-- by real quality asteroids in control.lua, avoiding fake drop duplication.
local M={}
local engine=require("scripts.razi_asteroid_difficulty")
local PREFIX="razi-quality-asteroid-"
M.prefix=PREFIX
local registered={}
local function clone(x)
  if type(x)~="table" then return x end
  local copy={}
  for k,v in pairs(x) do copy[k]=clone(v) end
  return copy
end
local function settings_value(name,default)
  return require("scripts.razi_difficulty_presets").effective(name,default)
end
local function is_enemy(def,entities)
  return type(def)=="table" and (def.type==nil or def.type=="entity")
    and type(def.asteroid)=="string"
    and def.asteroid:sub(1,#PREFIX)~=PREFIX
    and entities[def.asteroid]~=nil
end
local function proxy_for(name,entities)
  if registered[name] then return PREFIX..name end
  local original=entities[name]
  if not original then return nil end
  local alias=PREFIX..name
  if entities[alias] then
    registered[name]=true
    return alias
  end
  -- Original asteroid implementations use this minimal prototype strategy
  -- to invoke a script upon native spawn. Preserve icons and resistances.
  local proxy={
    type="asteroid",name=alias,hidden=true,hidden_in_factoriopedia=true,
    localised_name=original.localised_name or {"entity-name."..name},
    created_effect={
      type="direct",action_delivery={type="instant",target_effects={
        type="script",effect_id=alias
      }}
    },resistances=clone(original.resistances)
  }
  if original.icons then
    proxy.icons=clone(original.icons)
  elseif original.icon then
    proxy.icon=original.icon
    proxy.icon_size=original.icon_size
  else
    -- Some custom asteroids expose their icon via nonstandard fields; avoid
    -- shipping a prototype with no icon whose graphics could fail loading.
    return nil
  end
  if original.quality_indicator_scale then
    proxy.quality_indicator_scale=original.quality_indicator_scale
  end
  data:extend({proxy})
  registered[name]=true
  return alias
end
local sizes={small=1,medium=1.04,big=1.12,huge=1.18}
local function native_multiplier(name,level)
  local size=name:match("^(small)%-") or name:match("^(medium)%-")
    or name:match("^(big)%-") or name:match("^(huge)%-")
  local material=name:match("%-([%a]+)%-asteroid$")
  if not size or not ({metallic=true,carbonic=true,
      oxide=true,promethium=true})[material] then return 1 end
  local factor=1+(level-1)*.035
  if level>=6 then factor=factor*(sizes[size] or 1) end
  return math.min(1.55,factor)
end
-- The SLP solar passages carry custom plasma-clot enemies with their own
-- source-specific effects. Increasing their difficulty must not turn them
-- into Razi proxy asteroids or alter source ownership. Vanilla Space Age
-- hostiles still get the endgame quality tiers on these connections.
local function vanilla_hostile(name)
 if type(name)~="string" then return false end
 local size=name:match("^(small)%-") or name:match("^(medium)%-")
   or name:match("^(big)%-") or name:match("^(huge)%-")
 local material=name:match("%-([%a]+)%-asteroid$")
 return size~=nil and ({metallic=true,carbonic=true,
   oxide=true,promethium=true})[material]==true
end
function M.preserve_stellar_source_enemy(target,name)
 return engine.stellar_route_tier(target)~=nil and not vanilla_hostile(name)
end
local function rewrite(target,level,entities,scale)
  local definitions=target.asteroid_spawn_definitions
  if type(definitions)~="table" then return 0 end
  local transformed=0
  local result={}
  for i,entry in ipairs(definitions) do
    local def=entry
    if is_enemy(entry,entities)
      and not M.preserve_stellar_source_enemy(target,entry.asteroid) then
      local proxy=proxy_for(entry.asteroid,entities)
      if proxy then
        def=clone(entry)
        local m=scale and native_multiplier(entry.asteroid,level) or 1
        if type(def.probability)=="number" then
          def.probability=def.probability*m
        end
        for _,point in ipairs(def.spawn_points or {}) do
          if type(point.probability)=="number" then
            point.probability=point.probability*m
          end
        end
        def.asteroid=proxy
        def.type="entity"
        transformed=transformed+1
      end
    end
    result[i]=def
  end
  if transformed>0 then target.asteroid_spawn_definitions=result end
  return transformed
end
function M.data_final_fixes()
  if not settings_value("razi-quality-asteroids",true) then return 0 end
  if mods and (mods["Quality-Asteroids-Expanded"]
    or mods["quality-asteroids"]) then
    -- These mods use their own creation triggers. Never double-convert.
    return 0
  end
  -- Use the same fully reconciled stage map as the route tooltip and art.
  engine.prepare_routes(data.raw["space-connection"])
  local entities=data.raw.asteroid or {}
  local count,all=0,0
  local mode=settings_value("razi-asteroid-difficulty-scale","balanced")
  for _,route in pairs(data.raw["space-connection"] or {}) do
    if not route.hidden then
      local lo,hi=engine.route_range(route,mode)
      if hi>=2 then
        count=count+rewrite(route,(lo+hi)/2,entities,true)
        all=all+1
      end
    end
  end
  for _,category in ipairs({"planet","space-location"}) do
    for name,location in pairs(data.raw[category] or {}) do
      if engine.location_level(name)>=2 then
        count=count+rewrite(location,engine.location_level(name),
          entities,false)
      end
    end
  end
  if type(log)=="function" then
    log("[Razi Protocol/asteroid-quality] Converted "..count..
      " hostile spawn entries across "..all..
      " routes, without affecting resource chunks")
  end
  return count
end
return M
