-- Razi Protocol / OPTIONAL Space Age asteroid-performance experiments.
-- Inspiration: UPS Friendly Asteroids, Remove Asteroid Particles (2.1),
-- Remove Weapon Particles and Particle Free Disposal. Independent code.
-- No changes of any kind unless an explicit startup option is enabled.
-- All work is data-final-fixes only; NO runtime handlers or ticking.
local M={}
local PREFIX="razi-performance-"
local function enabled(key)
  local item=settings and settings.startup
    and settings.startup[PREFIX..key]
  return item~=nil and item.value==true
end
local function copy(value)
  if type(value)~="table" then return value end
  local out={}
  for k,v in pairs(value) do out[k]=copy(v) end
  return out
end
local function is_array(value)
  return type(value)=="table" and rawget(value,1)~=nil
end
local function prune(node,cosmetic,fragments)
  if type(node)~="table" then return node,0,0 end
  local kind=node.type
  if cosmetic and (kind=="create-particle"
    or kind=="create-trivial-smoke") then
    return nil,1,0
  end
  if fragments and kind=="create-asteroid-chunk"
    and type(node.asteroid_name)=="string" then
    -- This mode is deliberately NOT yield-neutral. Opt-in players trade
    -- fewer collector entities for less mineable asteroid material.
    local changed=copy(node)
    changed.probability=(changed.probability or 1)*.5
    return changed,0,1
  end
  local changed=false
  local removed,halved=0,0
  local rebuilt={}
  if is_array(node) then
    for _,v in ipairs(node) do
      local out,r,h=prune(v,cosmetic,fragments)
      if out~=nil then rebuilt[#rebuilt+1]=out end
      if out~=v or r>0 or h>0 then changed=true end
      removed=removed+r
      halved=halved+h
    end
    -- TriggerEffect is an array OR an effect object. Array entries that
    -- are cosmetic-only can be safely removed without leaving nil holes.
    for k,v in pairs(node) do
      if type(k)~="number" then rebuilt[k]=v end
    end
    if #rebuilt==0 then return nil,removed,halved end
  else
    for k,v in pairs(node) do
      if type(v)=="table" then
        local out,r,h=prune(v,cosmetic,fragments)
        if out~=nil then rebuilt[k]=out end
        if out~=v or r>0 or h>0 then changed=true end
        removed=removed+r
        halved=halved+h
      else rebuilt[k]=v end
    end
    -- Empty shells left after removing visual-only effects have no valid
    -- targets. Drop the whole wrapper instead of emitting broken triggers.
    if changed and kind=="instant"
      and rebuilt.target_effects==nil and rebuilt.source_effects==nil then
      return nil,removed,halved
    end
    if changed and kind=="direct" and rebuilt.action_delivery==nil then
      return nil,removed,halved
    end
  end
  return changed and rebuilt or node,removed,halved
end
M.prune=prune
local function modify_field(proto,key,cosmetic,fragments)
  if not proto or type(proto[key])~="table" then return 0,0 end
  local altered,r,f=prune(proto[key],cosmetic,fragments)
  if r>0 or f>0 then proto[key]=altered end
  return r,f
end
local function visual_asteroids()
  local changed=0
  -- Do not alter asteroid graphics, loot, damage, or created_effect:
  -- the latter is used by Razi's quality-asteroid spawn carriers.
  for _,group in ipairs({"asteroid","asteroid-chunk"}) do
    for _,prototype in pairs(data.raw[group] or {}) do
      local a=select(1,modify_field(prototype,
        "dying_trigger_effect",true,false))
      local b=select(1,modify_field(prototype,
        "damaged_trigger_effect",true,false))
      changed=changed+a+b
    end
  end
  return changed
end
local function weapon_particles()
  local changed=0
  -- Only remove visual particle effects. Projectile impacts and explosions
  -- retain their damage, collision, light, sounds, and gameplay entities.
  for _,group in ipairs({"projectile","artillery-projectile","beam"}) do
    for _,prototype in pairs(data.raw[group] or {}) do
      for _,field in ipairs({"action","created_effect",
        "hit_effects","dying_trigger_effect"}) do
        changed=changed+select(1,
          modify_field(prototype,field,true,false))
      end
    end
  end
  return changed
end
local function trim_fragments()
  local affected=0
  -- Avoid modifying Secretas Auric, Imersite and other source-owned
  -- custom drops; only native large hostile asteroids opt into this pass.
  for name,prototype in pairs(data.raw.asteroid or {}) do
    if name:match("^(big)%-") or name:match("^(huge)%-") then
      local family=name:match("%-([%a]+)%-asteroid$")
      if ({metallic=true,carbonic=true,oxide=true,promethium=true})
        [family] then
        local _,n=modify_field(prototype,
          "dying_trigger_effect",false,true)
        affected=affected+n
      end
    end
  end
  return affected
end
local function reduce_outer_hostiles()
  local changed=0
  local ladder=require("scripts.razi_asteroid_difficulty")
  local asteroid=data.raw.asteroid or {}
  local function apply(target)
    local source=target.asteroid_spawn_definitions
    if type(source)~="table" then return end
    local definitions=nil
    for index,entry in ipairs(source) do
      -- Native quality carriers are asteroids too. Resource chunks are
      -- never affected, even on 100% legendary Deep Space routes.
      if type(entry)=="table" and
        (entry.type=="entity" or entry.type==nil) and
        asteroid[entry.asteroid] then
        local edited=copy(entry)
        if type(edited.probability)=="number" then
          edited.probability=edited.probability*.72
        end
        for _,sample in ipairs(edited.spawn_points or {}) do
          if type(sample.probability)=="number" then
            sample.probability=sample.probability*.72
          end
        end
        if not definitions then
          definitions={}
          for k,v in pairs(source) do definitions[k]=v end
        end
        definitions[index]=edited
        changed=changed+1
      end
    end
    if definitions then target.asteroid_spawn_definitions=definitions end
  end
  for _,route in pairs(data.raw["space-connection"] or {}) do
    if not route.hidden then
      local _,peak=ladder.route_range(route)
      if peak>=8 then apply(route) end
    end
  end
  for _,category in ipairs({"planet","space-location"}) do
    for name,location in pairs(data.raw[category] or {}) do
      if ladder.location_level(name)>=8 then apply(location) end
    end
  end
  return changed
end
-- Reduce explicitly space-combat-themed explosion smoke and purely
-- decorative particle effects. Avoid touching generic ground combat
-- explosions, damage triggers, animations, or sounds.
local function space_explosion_smoke()
  local affected=0
  local keywords={"asteroid","rocket","railgun","artillery",
    "flak","space%-","missile"}
  for name,proto in pairs(data.raw.explosion or {}) do
    local space_effect=false
    for _,key in ipairs(keywords) do
      if name:find(key) then space_effect=true;break end
    end
    if space_effect then
      if type(proto.smoke_count)=="number" and proto.smoke_count>0 then
        proto.smoke_count=0
        affected=affected+1
      end
      affected=affected+select(1,
        modify_field(proto,"explosion_effect",true,false))
    end
  end
  return affected
end
M.space_explosion_smoke=space_explosion_smoke
M.trim_fragments=trim_fragments
M.visual_asteroids=visual_asteroids
M.weapon_particles=weapon_particles
M.reduce_outer_hostiles=reduce_outer_hostiles
local already=false
function M.data_final_fixes()
  if already then return 0 end
  local debris=enabled("asteroid-particles")
  local weapon=enabled("weapon-particles")
  local fragments=enabled("reduced-fragments")
  local density=enabled("outer-hostile-density")
  local smoke=enabled("space-explosion-smoke")
  if not (debris or weapon or fragments or density or smoke) then return 0 end
  already=true
  local results={
    asteroid_visuals=debris and visual_asteroids() or 0,
    weapon_visuals=weapon and weapon_particles() or 0,
    native_fragments=fragments and trim_fragments() or 0,
    hostile_spawns=density and reduce_outer_hostiles() or 0,
    explosion_smoke=smoke and space_explosion_smoke() or 0
  }
  if type(log)=="function" then
    log(("[Razi Protocol/performance] Optional asteroid passes: "..
      "visuals=%d; weapon-particles=%d; fragment-triggers=%d; "..
      "late-hostile-spawns=%d; explosion-smoke=%d"):format(
        results.asteroid_visuals,results.weapon_visuals,
        results.native_fragments,results.hostile_spawns,
        results.explosion_smoke))
  end
  return results.asteroid_visuals+results.weapon_visuals+
    results.native_fragments+results.hostile_spawns+
    results.explosion_smoke
end
return M
