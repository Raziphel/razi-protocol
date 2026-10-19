-- Research handoffs between nearby systems.
-- Discovery techs are found from their unlock effects.
local M={}
local interdependence=require("prototypes.compat.interdependence_mode")
M.bridges={
  {"planet-discovery-corrundum","planet-discovery-apia-carnova"},
  {"planet-discovery-secretas","planet-discovery-tenebris"},
  {"planet-discovery-crucible","planet-discovery-cubium"},
  {"planet-discovery-frozeta","planet-discovery-crucible"}
}
M.phases={
  -- Pairwise gateways remain independent; only previously researched
  -- planet discoveries are candidates for the next paired frontier.
  {gates={"vibrant-discovery","vespera-discovery"},
   worlds={"igrys","foliax"}},
  -- Obsidiax now opens AFTER Umbra; using it to unlock either parallel
  -- outer system would create a research cycle / permanent chapter softlock.
  {gates={"beetlejuice-discovery","umbra-discovery"},
   worlds={"cerys"}}
}
local function tech(name) return (data.raw.technology or {})[name] end
local function present(name)
  return (data.raw.planet or {})[name]
    or (data.raw["space-location"] or {})[name]
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
  -- Only the few worlds involved in paired frontier research matter here.
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
  for _,phase in ipairs(M.phases) do
    for _,name in ipairs(phase.worlds) do
      local candidate=native_unlock(name,sources)
      local safe=candidate~=nil
      if safe then
        -- Check BOTH parallel gates BEFORE touching either. An optional
        -- source that depends on a new frontier must not destroy the
        -- freedom to choose its paired systems in either order.
        for _,gateway in ipairs(phase.gates) do
          if not active(gateway) or ancestor(candidate,gateway) then
            safe=false;break
          end
        end
      end
      -- A direct science technology or its recipe may itself require the
      -- destination gateway even when the candidate tech graph does not.
      if safe and science_after_gateway(candidate,phase,producers,unlockers)
        then safe=false end
      if safe then
        for _,gateway in ipairs(phase.gates) do
          M.safe_link(gateway,candidate)
        end
      end
    end
  end
end
return M
