-- Research handoffs between nearby systems.
-- Discovery techs are found from their unlock effects.
--
-- The rule: a world of system N is researched before the gateways of system N+1. Worlds come from
-- prototypes/system/world_roster.lua, the ones the path must never need are listed in
-- prototypes/system/optional_worlds.lua. A world of a mod that is not installed has nothing to weave.
--   Solaris, Nyxaris        -> Vibrant and Vespera
--   Vibrant, Vespera        -> Beetlejuice and Umbra
--   Beetlejuice, Umbra      -> Outer Frontier Mastery
-- A world is left out, with a line in the log, when its research would wait for the gateway it should open.
local M={}
local interdependence=require("prototypes.compat.interdependence_mode")
local roster=require("prototypes.system.world_roster")
local optional=require("prototypes.system.optional_worlds")
M.bridges={
  {"planet-discovery-corrundum","planet-discovery-apia-carnova"},
  {"planet-discovery-secretas","planet-discovery-tenebris"},
  {"planet-discovery-crucible","planet-discovery-cubium"},
  {"planet-discovery-frozeta","planet-discovery-crucible"}
}
-- Gateways of the stage after each group of systems. Pairwise gateways remain independent; only
-- previously researched planet discoveries are candidates for the next paired frontier.
M.stages={
  {systems={"solaris","nyxaris"},
   gates={"vibrant-discovery","vespera-discovery"}},
  {systems={"vibrant","vespera"},
   gates={"beetlejuice-discovery","umbra-discovery"}},
  -- Obsidiax opens AFTER Umbra; using it to unlock either parallel outer system would create a
  -- research cycle / permanent chapter softlock. Mastery comes after both.
  {systems={"beetlejuice","umbra"},
   gates={"razi-outer-frontier-mastery"}}
}
-- Worlds that are not in the roster but follow the same rule.
M.extra_worlds={
  -- The Aegis survey opens in the first systems, but Bellicos itself waits for Beetlejuice.
  {world="bellicos-orbit",system="beetlejuice"}
}
-- Locations of the worlds that stay out: the path must not need them (optional_worlds.lua).
local function excluded_worlds()
  local result={}
  for _,world in ipairs(optional.worlds) do
    for _,location in ipairs(world.locations) do result[location]=true end
  end
  return result
end
local function build_phases()
  local skipped=excluded_worlds()
  local by_system={}
  for _,system in ipairs(roster.order) do
    local list={}
    for _,world in ipairs(roster.systems[system]) do
      if not skipped[world] then list[#list+1]=world end
    end
    by_system[system]=list
  end
  for _,extra in ipairs(M.extra_worlds) do
    if not skipped[extra.world] then
      local list=by_system[extra.system]
      list[#list+1]=extra.world
    end
  end
  local phases={}
  for _,stage in ipairs(M.stages) do
    local worlds={}
    for _,system in ipairs(stage.systems) do
      for _,world in ipairs(by_system[system]) do worlds[#worlds+1]=world end
    end
    phases[#phases+1]={gates=stage.gates,worlds=worlds}
  end
  return phases
end
M.phases=build_phases()
local function tech(name) return (data.raw.technology or {})[name] end
local function present(name)
  return (data.raw.planet or {})[name]
    or (data.raw["space-location"] or {})[name]
end
local function note(text)
  if log then log("razi-protocol: regional research: "..text) end
end
local function ancestor(start,wanted,seen)
  if start==wanted then return true end
  local node=tech(start)
  if not node then return false end
  seen=seen or {}
  if seen[start] then return false end
  seen[start]=true
  for _,parent in ipairs(node.prerequisites or {}) do
    if ancestor(parent,wanted,seen) then return true end
  end
  return false
end
local function active(name)
  local t=tech(name)
  return t and t.hidden~=true and t.enabled~=false
end
function M.safe_link(target,parent)
  if target==parent or not active(target) or not active(parent)
    or ancestor(parent,target) then return false end
  if not ancestor(target,parent) then
    local t=tech(target)
    t.prerequisites=t.prerequisites or {}
    t.prerequisites[#t.prerequisites+1]=parent
  end
  return true
end
local watched_worlds={}
for _,phase in ipairs(M.phases) do
  for _,world in ipairs(phase.worlds) do watched_worlds[world]=true end
end
local function native_unlocks()
  -- Only the worlds of the roster matter here.
  local by_world={}
  for id,t in pairs(data.raw.technology or {}) do
    if active(id) then
      for _,effect in ipairs(t.effects or {}) do
        if effect.type=="unlock-space-location"
          and watched_worlds[effect.space_location] then
          local list=by_world[effect.space_location]
          if not list then list={} by_world[effect.space_location]=list end
          list[#list+1]=id
        end
      end
    end
  end
  for _,list in pairs(by_world) do table.sort(list) end
  return by_world
end
local function native_unlock(name,by_world)
  if not present(name) then return nil end
  for _,id in ipairs(by_world[name] or {}) do
    local t=tech(id)
    if t and (t.research_trigger
      or (t.unit and t.unit.ingredients and #t.unit.ingredients>0)) then
      return id
    end
  end
end

-- A source discovery can look early while the science used to research it
-- is manufactured by a recipe locked behind the *next* paired star.
-- Index only once and require a known producer not gated by either frontier.
local function production_index(wanted)
  local products,unlockers,recipes={},{},{}
  if not next(wanted) then return products,unlockers end
  local function record(recipe_name,variant)
    if not variant then return end
    local function add(name,kind)
      if not name or kind=="fluid" or not wanted[name] then return end
      local list=products[name]
      if not list then list={} products[name]=list end
      list[#list+1]=recipe_name
      recipes[recipe_name]=true
    end
    add(variant.result,"item")
    for _,entry in ipairs(variant.results or {}) do
      add(entry.name or entry[1],entry.type)
    end
  end
  for name,recipe in pairs(data.raw.recipe or {}) do
    if not recipe.hidden then
      record(name,recipe)
      record(name,rawget(recipe,"normal"))
      record(name,rawget(recipe,"expensive"))
    end
  end
  -- A matching science product is the only reason to inspect an unlock.
  if not next(recipes) then return products,unlockers end
  for id,node in pairs(data.raw.technology or {}) do
    if active(id) then
      for _,effect in ipairs(node.effects or {}) do
        if effect.type=="unlock-recipe" and recipes[effect.recipe] then
          local list=unlockers[effect.recipe]
          if not list then list={} unlockers[effect.recipe]=list end
          list[#list+1]=id
        end
      end
    end
  end
  return products,unlockers
end
local function science_after_gateway(candidate,phase,products,unlockers)
  for _,ingredient in ipairs((tech(candidate).unit or {}).ingredients or {}) do
    local pack=ingredient.name or ingredient[1]
    for _,gateway in ipairs(phase.gates) do
      if tech(pack) and ancestor(pack,gateway) then return true end
    end
    local makers=products[pack]
    if makers then
      local obtainable=false
      for _,recipe_name in ipairs(makers) do
        local recipe=(data.raw.recipe or {})[recipe_name]
        if recipe and recipe.enabled~=false then
          obtainable=true;break
        end
        for _,unlocker in ipairs(unlockers[recipe_name] or {}) do
          local future=false
          for _,gateway in ipairs(phase.gates) do
            if ancestor(unlocker,gateway) then future=true;break end
          end
          if not future then obtainable=true;break end
        end
        if obtainable then break end
      end
      if not obtainable then return true end
    end
  end
  return false
end

-- What a technology needs, the way the pack test of my-razi-fixes counts it: its prerequisites, the packs
-- of its unit, the technologies that unlock the recipe named like each pack, and the packs that recipe
-- takes. Other recipes that give a pack (recycling, upcycling, alternatives) are one way among several.
local function research_model()
  local recipes=data.raw.recipe or {}
  local unlockers,packs={},{}
  for id,node in pairs(data.raw.technology or {}) do
    if active(id) then
      for _,effect in ipairs(node.effects or {}) do
        if effect.type=="unlock-recipe" then
          local list=unlockers[effect.recipe]
          if not list then list={} unlockers[effect.recipe]=list end
          list[#list+1]=id
        end
      end
      for _,ingredient in ipairs(node.unit and node.unit.ingredients or {}) do
        packs[ingredient.name or ingredient[1]]=true
      end
    end
  end
  local model={}
  -- the pack recipe (nil when nothing makes the pack by its own name), the packs it takes and the
  -- technologies that unlock it
  function model.recipe(pack)
    local recipe=recipes[pack]
    if not recipe or not packs[pack] then return nil end
    local taken={}
    for _,ingredient in ipairs(recipe.ingredients or {}) do
      local name=ingredient.name or ingredient[1]
      if packs[name] and name~=pack and ingredient.type~="fluid" then
        taken[#taken+1]=name
      end
    end
    return recipe,taken,unlockers[pack] or {}
  end
  function model.packs(node)
    local list={}
    for _,ingredient in ipairs(node.unit and node.unit.ingredients or {}) do
      list[#list+1]=ingredient.name or ingredient[1]
    end
    return list
  end
  return model
end
-- Technologies that the gateway needs, itself included.
local function required_by(gate,model)
  local seen,seen_pack={},{}
  local queue={{"tech",gate}}
  local index=1
  while queue[index] do
    local kind,name=queue[index][1],queue[index][2]
    index=index+1
    if kind=="tech" then
      local node=tech(name)
      if node and not seen[name] and active(name) then
        seen[name]=true
        for _,parent in ipairs(node.prerequisites or {}) do
          queue[#queue+1]={"tech",parent}
        end
        for _,pack in ipairs(model.packs(node)) do
          queue[#queue+1]={"pack",pack}
        end
      end
    elseif not seen_pack[name] then
      seen_pack[name]=true
      local recipe,taken,makers=model.recipe(name)
      if recipe then
        for _,unlocker in ipairs(makers) do queue[#queue+1]={"tech",unlocker} end
        for _,pack in ipairs(taken) do queue[#queue+1]={"pack",pack} end
      end
    end
  end
  return seen
end
-- Technologies that can be researched while the given gateways stay closed (the least fixed point).
local function open_before(gates,model)
  local closed={}
  for _,gate in ipairs(gates) do closed[gate]=true end
  local done,memo={},{}
  local function pack_open(pack,visiting)
    if memo[pack]~=nil then return memo[pack] end
    local recipe,taken,makers=model.recipe(pack)
    if not recipe then return true end
    if visiting[pack] then return false end
    visiting[pack]=true
    local open=recipe.enabled~=false or #makers==0
    if not open then
      for _,unlocker in ipairs(makers) do
        if done[unlocker] then open=true;break end
      end
    end
    if open then
      for _,name in ipairs(taken) do
        if not pack_open(name,visiting) then open=false;break end
      end
    end
    visiting[pack]=nil
    memo[pack]=open
    return open
  end
  local changed=true
  while changed do
    changed=false
    memo={}
    for name,node in pairs(data.raw.technology or {}) do
      if not done[name] and not closed[name] and active(name) then
        local ready=true
        for _,parent in ipairs(node.prerequisites or {}) do
          if active(parent) and not done[parent] then ready=false;break end
        end
        if ready then
          for _,pack in ipairs(model.packs(node)) do
            if not pack_open(pack,{}) then ready=false;break end
          end
        end
        if ready then done[name]=true changed=true end
      end
    end
  end
  return done
end

local function weave_phase(phase,model,sources,producers,unlockers)
  local reachable={} -- filled by the first candidate that gets this far
  local required={}
  for _,gateway in ipairs(phase.gates) do
    if active(gateway) then required[gateway]=required_by(gateway,model) end
  end
  for _,name in ipairs(phase.worlds) do
    local candidate=native_unlock(name,sources)
    if candidate then
      local safe=true
      local why
      -- Check BOTH parallel gates BEFORE touching either. An optional
      -- source that depends on a new frontier must not destroy the
      -- freedom to choose its paired systems in either order.
      for _,gateway in ipairs(phase.gates) do
        if not active(gateway) then
          safe=false;why=gateway.." is not in the game";break
        end
        if ancestor(candidate,gateway) then
          safe=false;why="its research needs "..gateway;break
        end
      end
      -- A direct science technology or its recipe may itself require the
      -- destination gateway even when the candidate tech graph does not.
      if safe and science_after_gateway(candidate,phase,producers,unlockers)
        then safe=false;why="its science is made behind the gateway" end
      -- The whole of what the research needs: prerequisites, packs, the
      -- recipes of the packs and the packs those recipes take.
      if safe then
        if not reachable.set then reachable.set=open_before(phase.gates,model) end
        if not reachable.set[candidate] then
          safe=false;why="its packs or prerequisites need the gateway"
        end
      end
      if safe then
        for _,gateway in ipairs(phase.gates) do
          -- already a requirement of the gateway: the world is on the path as it is
          if not required[gateway][candidate] then
            local node=tech(gateway)
            local before=#(node.prerequisites or {})
            M.safe_link(gateway,candidate)
            if #(node.prerequisites or {})>before then
              note(gateway.." now requires "..candidate.." ("..name..")")
            end
          end
        end
      else
        note(name.." is not woven before "..table.concat(phase.gates,", ")..": "..why)
      end
    end
  end
end

function M.data_final_fixes()
  if not interdependence.enabled() then return end
  for _,edge in ipairs(M.bridges) do M.safe_link(edge[1],edge[2]) end
  local has_world=false
  for name in pairs(watched_worlds) do
    if present(name) then has_world=true break end
  end
  if not has_world then return end
  local sources=native_unlocks()
  local wanted={}
  for _,phase in ipairs(M.phases) do
    for _,name in ipairs(phase.worlds) do
      local candidate=native_unlock(name,sources)
      local node=candidate and tech(candidate)
      for _,entry in ipairs(node and node.unit and node.unit.ingredients or {}) do
        wanted[entry.name or entry[1]]=true
      end
    end
  end
  local producers,unlockers=production_index(wanted)
  -- One stage after another: the links of an earlier stage are part of the graph the next one checks.
  local model=research_model()
  for _,phase in ipairs(M.phases) do
    weave_phase(phase,model,sources,producers,unlockers)
  end
end
return M
