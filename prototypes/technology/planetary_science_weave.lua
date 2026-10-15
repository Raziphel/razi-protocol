-- Reuse native planetary science in Razi's optional freight research.
-- This runs after native arrival guards and component registration.
local M={}
local mode=require("prototypes.compat.interdependence_mode")
-- All targets are Razi-owned, post-arrival factory technology. The owner
-- must already be an ancestor of the target before any science is added.
M.rules={
  {"razi-network-precision-matrix","thermodynamic-science-pack","planet-discovery-moshine"},
  {"razi-network-precision-matrix","electrochemical-science-pack","planet-discovery-paracelsin"},
  {"razi-network-panglia-optic-bond","thermodynamic-science-pack","planet-discovery-moshine"},
  {"razi-network-matrix-cryo-controllers","cryogenic-science-pack","planet-discovery-aquilo"},
  {"razi-network-matrix-rubia-logistics","rubia-biofusion-science-pack","planet-discovery-rubia"},
  {"razi-network-bond-paracelsin-coils","electrochemical-science-pack","planet-discovery-paracelsin"},
  {"razi-network-bond-linox-refining","linox-item_linox-science-pack","linox-technology_planet-discovery-linox"},
  {"razi-network-extreme-lattice","rubia-biofusion-science-pack","planet-discovery-rubia"},
  {"razi-network-extreme-lattice","bioluminescent-science-pack","planet-discovery-tenebris"},
  {"razi-network-lattice-vesta-magnets","gas-manipulation-science-pack","planet-discovery-vesta"},
  {"razi-network-lattice-vesta-foundations","gas-manipulation-science-pack","planet-discovery-vesta"},
  {"razi-network-frame-vesta-foundations","planet-crucible-science-pack","planet-discovery-crucible"},
  {"razi-network-frame-aquilo-controllers","cryogenic-science-pack","planet-discovery-aquilo"},
  -- Deep-only side requirements create later destinations for familiar packs.
  {"razi-network-umbra-pressure-frame","planet-crucible-science-pack","planet-discovery-crucible",true},
  {"razi-network-umbra-pressure-frame","gas-manipulation-science-pack","planet-discovery-vesta",true},
  {"razi-network-lattice-balack-shielding","bioluminescent-science-pack","planet-discovery-tenebris",true},
  {"razi-network-frame-vesta-foundations","linox-item_linox-science-pack","linox-technology_planet-discovery-linox",true},
  {"razi-network-frame-aquilo-controllers","planet-crucible-science-pack","planet-discovery-crucible",true},
  -- Return familiar native sciences to factories which already need
  -- finished materials from those worlds. Arrival stays source-owned.
  {"razi-network-matrix-rubia-logistics","electrochemical-science-pack","planet-discovery-paracelsin"},
  {"razi-network-matrix-linox-refining","thermodynamic-science-pack","planet-discovery-moshine"},
  {"razi-network-panglia-optic-bond","apicultural-science-pack","planet-discovery-apia-carnova"},
  {"razi-network-bond-paracelsin-coils","apicultural-science-pack","planet-discovery-apia-carnova"},
  {"razi-network-extreme-lattice","cryogenic-science-pack","planet-discovery-aquilo"},
  {"razi-network-lattice-vesta-magnets","planet-crucible-science-pack","planet-discovery-crucible"},
  {"razi-network-frame-vesta-foundations","gas-manipulation-science-pack","planet-discovery-vesta"},
  {"razi-network-frame-aquilo-controllers","muriatic-science-pack","planet-discovery-muria"},
  {"razi-network-bond-paracelsin-coils","ribbonia-alien-science-pack","planet-discovery-ribbonia"},
  -- Deep mode makes the most remote upgrades better science customers.
  {"razi-network-matrix-linox-refining","linox-item_linox-science-pack","linox-technology_planet-discovery-linox",true},
  {"razi-network-lattice-balack-shielding","gas-manipulation-science-pack","planet-discovery-vesta",true},
  {"razi-network-umbra-pressure-frame","bioluminescent-science-pack","planet-discovery-tenebris",true}
}

local function raw(kind,name)
  return (data.raw[kind] or {})[name]
end
local function active(name)
  local node=raw("technology",name)
  return node and node.enabled~=false and not node.hidden
end
local function ancestor(start,wanted,seen)
  if start==wanted then return true end
  local node=raw("technology",start)
  if not node then return false end
  seen=seen or {}
  if seen[start] then return false end
  seen[start]=true
  for _,parent in ipairs(node.prerequisites or {}) do
    if ancestor(parent,wanted,seen) then return true end
  end
  return false
end
local function pack_exists(pack)
  local item=raw("tool",pack) or raw("item",pack)
  return item and not item.hidden
end
local function result_name(entry)
  return entry.name or entry[1]
end
local function inputs_exist(recipe)
  if not recipe or not recipe.ingredients then return false end
  for _,entry in ipairs(recipe.ingredients) do
    local name=result_name(entry)
    if entry.type=="fluid" then
      if not raw("fluid",name) then return false end
    elseif not (raw("item",name) or raw("tool",name)
      or raw("module",name) or raw("ammo",name)
      or raw("capsule",name)) then
      return false
    end
  end
  return true
end

-- Index only the native science products requested by the guarded rules.
-- One pass over recipe outputs avoids scanning every recipe for every pack.
local function sources()
  local wanted={}
  for _,rule in ipairs(M.rules) do wanted[rule[2]]=true end
  local makers,unlockers={},{}
  for name,recipe in pairs(data.raw.recipe or {}) do
    if not recipe.hidden then
      local recorded={}
      local function add_variant(variant)
        if not variant then return end
        local found={}
        local function mark(pack)
          if pack and wanted[pack] and not recorded[pack] then
            found[#found+1]=pack
            recorded[pack]=true
          end
        end
        mark(variant.result)
        for _,entry in ipairs(variant.results or {}) do
          if entry.type~="fluid" then mark(result_name(entry)) end
        end
        -- Do not treat a result icon or an expensive-only recipe with
        -- missing ingredients as proof of native science production.
        if #found==0 then return end
        if not inputs_exist(variant) then
          for _,pack in ipairs(found) do recorded[pack]=nil end
          return
        end
        for _,pack in ipairs(found) do
          local bucket=makers[pack] or {}
          bucket[#bucket+1]=name
          makers[pack]=bucket
        end
      end
      add_variant(recipe)
      add_variant(recipe.normal)
      add_variant(recipe.expensive)
    end
  end
  local needed={}
  for _,list in pairs(makers) do
    for _,recipe in ipairs(list) do needed[recipe]=true end
  end
  for name,tech in pairs(data.raw.technology or {}) do
    if active(name) then
      for _,effect in ipairs(tech.effects or {}) do
        if effect.type=="unlock-recipe" and needed[effect.recipe] then
          local list=unlockers[effect.recipe] or {}
          list[#list+1]=name
          unlockers[effect.recipe]=list
        end
      end
    end
  end
  for _,list in pairs(makers) do table.sort(list) end
  for _,list in pairs(unlockers) do table.sort(list) end
  return makers,unlockers
end
-- If a native producer is surface-bound, confirm that it can run
-- on the science's source world rather than assuming any factory works.
local source_world={
  ["planet-discovery-moshine"]="moshine",
  ["planet-discovery-paracelsin"]="paracelsin",
  ["planet-discovery-aquilo"]="aquilo",
  ["planet-discovery-rubia"]="rubia",
  ["planet-discovery-tenebris"]="tenebris",
  ["planet-discovery-crucible"]="crucible",
  ["planet-discovery-vesta"]="vesta",
  ["planet-discovery-apia-carnova"]="apia-carnova",
  ["planet-discovery-muria"]="muria",
  ["planet-discovery-ribbonia"]="ribbonia",
  ["linox-technology_planet-discovery-linox"]="linox-planet_linox"
}
local function source_surface(recipe,owner)
  local conditions=recipe.surface_conditions or {}
  if #conditions==0 then return true end
  local world=source_world[owner]
  local planet=world and (raw("planet",world) or raw("space-location",world))
  local properties=planet and planet.surface_properties
  if not properties then return false end
  for _,condition in ipairs(conditions) do
    local value=properties[condition.property]
    if type(value)~="number" then return false end
    if condition.min and value<condition.min then return false end
    if condition.max and value>condition.max then return false end
  end
  return true
end
local function supplier(pack,target,owner,makers,unlockers)
  for _,recipe_name in ipairs(makers[pack] or {}) do
    local recipe=raw("recipe",recipe_name)
    if recipe and source_surface(recipe,owner) then
      if recipe.enabled~=false then return true end
      for _,source in ipairs(unlockers[recipe_name] or {}) do
        -- Do not make a technology consume science whose native recipe
        -- is unlocked by that same technology or one of its descendants.
        -- The source must be available on the owning world's branch.
        if source~=target and not ancestor(source,target)
          and (source==owner or ancestor(source,owner)
            or ancestor(target,source)) then
          return source
        end
      end
    end
  end
end
local function accepted(ingredients,pack)
  local needs={[pack]=true}
  for _,entry in ipairs(ingredients) do needs[result_name(entry)]=true end
  for _,lab in pairs(data.raw.lab or {}) do
    local inputs={}
    for _,name in ipairs(lab.inputs or {}) do inputs[name]=true end
    local all=true
    for name in pairs(needs) do
      if not inputs[name] then all=false;break end
    end
    if all then return true end
  end
  return false
end
function M.try_add(rule,makers,unlockers)
  local target,pack,owner=rule[1],rule[2],rule[3]
  local tech=raw("technology",target)
  if not (active(target) and active(owner) and pack_exists(pack)
    and tech.unit and tech.unit.ingredients
    and not tech.research_trigger
    and ancestor(target,owner)) then return false end
  for _,entry in ipairs(tech.unit.ingredients) do
    if result_name(entry)==pack then return false end
  end
  if not accepted(tech.unit.ingredients,pack) then return false end
  local source=supplier(pack,target,owner,makers,unlockers)
  if not source then return false end
  -- If the native science recipe unlock is a separate later technology,
  -- it becomes a genuine prerequisite rather than a hidden instruction.
  if type(source)=="string" and not ancestor(target,source) then
    if ancestor(source,target) then return false end
    tech.prerequisites=tech.prerequisites or {}
    tech.prerequisites[#tech.prerequisites+1]=source
  end
  tech.unit.ingredients[#tech.unit.ingredients+1]={pack,1}
  return true
end
function M.data_final_fixes()
  if not mode.enabled() then return end
  local makers,unlockers=sources()
  for _,rule in ipairs(M.rules) do
    if not rule[4] or mode.deep() then
      M.try_add(rule,makers,unlockers)
    end
  end
end
return M
