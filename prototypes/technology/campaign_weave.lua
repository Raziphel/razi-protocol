-- Intertwine existing planet sciences without new items or optional requirements.
-- Run after the authoritative seven-system discovery gates.
local M = {}
local interdependence = require("prototypes.compat.interdependence_mode")
local rules = {
{"planet-discovery-castra", {}, {{"metallurgic-science-pack", "planet-discovery-vulcanus"}}},
{"planet-discovery-arig", {}, {{"battlefield-science-pack", "planet-discovery-castra"}}},
{"planet-discovery-hyarion", {}, {{"battlefield-science-pack", "planet-discovery-castra"}}},
{"planet-discovery-tellus", {"planet-discovery-gleba"}, {{"planetaris-compression-science-pack", "planet-discovery-arig"}, {"planetaris-polishing-science-pack", "planet-discovery-hyarion"}, {"agricultural-science-pack", "planet-discovery-gleba"}}},
{"planet-discovery-corrundum", {}, {{"planetaris-bioengineering-science-pack", "planet-discovery-tellus"}, {"planetaris-pathological-science-pack", "planet-discovery-tellus"}}},
{"planet-discovery-apia-carnova", {"planet-discovery-gleba", "planet-discovery-moshine"}, {{"agricultural-science-pack", "planet-discovery-gleba"}, {"thermodynamic-science-pack", "planet-discovery-moshine"}}},
{"panglia_planet_discovery_panglia", {"planet-discovery-apia-carnova", "planet-discovery-moshine"}, {{"apicultural-science-pack", "planet-discovery-apia-carnova"}, {"thermodynamic-science-pack", "planet-discovery-moshine"}}},
{"planet-discovery-ribbonia", {"planet-discovery-fulgora"}, {{"electromagnetic-science-pack", "planet-discovery-fulgora"}}},
{"planet-discovery-paracelsin", {}, {{"ribbonia-alien-science-pack", "planet-discovery-ribbonia"}}},
-- Shchierbin is BEFORE Paracelsin, not after it.
{"planet-discovery-shchierbin", {"planet-discovery-muria"},
 {{"ribbonia-alien-science-pack","planet-discovery-ribbonia"},
  {"muriatic-science-pack","planet-discovery-muria"}}},
{"planet-discovery-aquilo", {"planet-discovery-fulgora"}, {{"muriatic-science-pack", "planet-discovery-muria"}}},
{"planet-discovery-rubia", {}, {{"cryogenic-science-pack", "planet-discovery-aquilo"}}},
{"planet-discovery-maraxsis", {"planet-discovery-paracelsin"}, {{"rubia-biofusion-science-pack", "planet-discovery-rubia"}}},
{"planet-discovery-secretas", {}, {{"golden-science-pack", "planet-discovery-cubium"}}},
{"planet-discovery-frozeta", {"planet-discovery-tenebris"}, {{"bioluminescent-science-pack", "planet-discovery-tenebris"}}},
{"planet-discovery-crucible", {}, {{"bioluminescent-science-pack", "planet-discovery-tenebris"}}},
{"planet-discovery-vesta", {"planet-discovery-cubium"}, {{"planet-crucible-science-pack", "planet-discovery-crucible"}}}
}

local function technology(name)
  return data.raw.technology and data.raw.technology[name]
end

local function depends_on(start, name, visited)
  if start == name then return true end
  local t = technology(start)
  if not t then return false end
  visited = visited or {}
  if visited[start] then return false end
  visited[start] = true
  for _, parent in ipairs(t.prerequisites or {}) do
    if depends_on(parent, name, visited) then return true end
  end
  return false
end

local function link(target_name, prerequisite_name)
  local t = technology(target_name)
  if not t or not technology(prerequisite_name) then return false end
  if depends_on(prerequisite_name, target_name) then return false end
  if not depends_on(target_name, prerequisite_name) then
    t.prerequisites = t.prerequisites or {}
    t.prerequisites[#t.prerequisites + 1] = prerequisite_name
  end
  return true
end

local function pack_exists(pack)
  return (data.raw.tool and data.raw.tool[pack])
      or (data.raw.item and data.raw.item[pack])
end

local function produces(recipe, pack)
  if not recipe then return false end
  if recipe.result == pack then return true end
  for _, result in ipairs(recipe.results or {}) do
    if (result.name or result[1]) == pack then return true end
  end
  return false
end

-- Every campaign milestone used to scan the entire recipe catalogue, then
-- every locked producer scanned every technology again. This final-stage
-- index is rebuilt on each pass, after all source mods have registered their
-- recipes. Dependencies still use the LIVE technology graph at query time.
local producers_by_pack, unlockers_by_recipe

local function record_producer(pack, name, wanted, index)
  if not wanted[pack] then return end
  local list = index[pack]
  if not list then list = {}; index[pack] = list end
  if list[#list] ~= name then list[#list + 1] = name end
end

local function index_variant(recipe, name, wanted, index)
  if not recipe then return end
  if recipe.result then record_producer(recipe.result, name, wanted, index) end
  for _, result in ipairs(recipe.results or {}) do
    record_producer(result.name or result[1], name, wanted, index)
  end
end

local function build_indexes()
  local wanted = {}
  for _, rule in ipairs(rules) do
    for _, milestone in ipairs(rule[3]) do wanted[milestone[1]] = true end
  end
  local producers, unlockers = {}, {}
  for recipe_name, recipe in pairs(data.raw.recipe or {}) do
    index_variant(recipe, recipe_name, wanted, producers)
    index_variant(rawget(recipe, "normal"), recipe_name, wanted, producers)
    index_variant(rawget(recipe, "expensive"), recipe_name, wanted, producers)
  end
  for name, tech in pairs(data.raw.technology or {}) do
    for _, effect in ipairs(tech.effects or {}) do
      if effect.type == "unlock-recipe" and effect.recipe then
        local matches = unlockers[effect.recipe]
        if not matches then
          matches = {}; unlockers[effect.recipe] = matches
        end
        matches[#matches + 1] = name
      end
    end
  end
  producers_by_pack, unlockers_by_recipe = producers, unlockers
end

-- Existence of a recipe alone is not evidence that the pack can be made.
-- An otherwise valid science requirement softlocks its discovery when the
-- recipe can only be unlocked *by* that same discovery or a later research.
-- Do not silently force a sibling world to be researched just
-- because its discovery happens to unlock a producer for this science.
local function world_discovery(name)
  return name:match("^planet%-discovery%-")
    or name:match("^moon%-discovery%-")
    or name:match("^panglia_planet_discovery_")
end

local function recipe_accessible_before(recipe_name,recipe,target,owner)
  if recipe.enabled~=false then return true end
  for _,name in ipairs(unlockers_by_recipe[recipe_name] or {}) do
    local requires_peer=world_discovery(name) and name~=owner
      and not depends_on(target,name)
    if not requires_peer and not depends_on(name,target) then return true end
  end
  return false
end

local function has_production_recipe_before(pack,target,owner)
  for _,recipe_name in ipairs(producers_by_pack[pack] or {}) do
    local recipe=data.raw.recipe[recipe_name]
    if recipe and recipe_accessible_before(recipe_name,recipe,target,owner)
      then return true end
  end
  return false
end

local function has_compatible_lab(ingredients, pack)
  for _, lab in pairs(data.raw.lab or {}) do
    if lab.inputs then
      local accepted = {}
      for _, item in ipairs(lab.inputs) do accepted[item] = true end
      local valid = accepted[pack] == true
      for _, ingredient in ipairs(ingredients) do
        if not accepted[ingredient.name or ingredient[1]] then
          valid = false
          break
        end
      end
      if valid then return true end
    end
  end
  return false
end

local function add_science(target, pack)
  local t = technology(target)
  if not (t and t.unit and t.unit.ingredients) then return end
  if not has_production_recipe_before(pack, target) then return end
  for _, ingredient in ipairs(t.unit.ingredients) do
    if (ingredient.name or ingredient[1]) == pack then return end
  end
  -- Research is valid only if one existing lab handles all ingredients.
  if has_compatible_lab(t.unit.ingredients, pack) then
    t.unit.ingredients[#t.unit.ingredients + 1] = {pack, 1}
  end
end

-- Never add a prerequisite before verifying that the associated
-- planet science is producible before the target and a lab can use it.
-- Otherwise merely skipping the ingredient can still leave a softlock.
local function safely_deliverable(target,pack,owner)
  local destination,material,source_tech=technology(target),
    technology(pack),technology(owner)
  if not (destination and material and source_tech and pack_exists(pack))
    then return false end
  if not (destination.unit and destination.unit.ingredients) then return false end
  if depends_on(pack,target) or depends_on(owner,target)
    or depends_on(owner,pack) then return false end
  if not has_production_recipe_before(pack,target,owner) then return false end
  return has_compatible_lab(destination.unit.ingredients,pack)
end

function M.data_final_fixes()
  -- The core seven-system technology gates are handled separately.
  if not interdependence.enabled() then return end
  -- Required-planet connections first; early star entries are untouched.
  for _, rule in ipairs(rules) do
    for _, parent in ipairs(rule[2]) do link(rule[1], parent) end
  end
  -- Index only the science packs the campaign actually references.
  -- This is an ephemeral data-stage cache and never enters the save game.
  build_indexes()
  -- Existing science techs must follow their source planets. Never insert
  -- an impossible technology cycle or assume a missing optional mod exists.
  for _, rule in ipairs(rules) do
    local target = rule[1]
    for _, milestone in ipairs(rule[3]) do
      local pack, owner = milestone[1], milestone[2]
      if safely_deliverable(target,pack,owner)
        and link(pack,owner) and link(target,pack) then
        add_science(target,pack)
      end
    end
  end
end

return M
