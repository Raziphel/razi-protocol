-- Research links between the planet branches.
-- Apply this after the main star-system gates so the opening choices stay free.
-- Every rule must agree with the gate order: the science of a planet is only asked for by planets
-- that come after it, and never by planets whose own research needs the target in turn.
local M = {}
local interdependence = require("prototypes.compat.interdependence_mode")
local Science = require("__razi_lib__/lib/science")
local rules = {
{"planet-discovery-castra", {}, {{"metallurgic-science-pack", "planet-discovery-vulcanus"}}},
{"planet-discovery-arig", {}, {{"battlefield-science-pack", "planet-discovery-castra"}}},
{"planet-discovery-hyarion", {}, {{"battlefield-science-pack", "planet-discovery-castra"}}},
{"planet-discovery-tellus", {"planet-discovery-gleba"}, {{"planetaris-compression-science-pack", "planet-discovery-arig"}, {"planetaris-polishing-science-pack", "planet-discovery-hyarion"}, {"agricultural-science-pack", "planet-discovery-gleba"}}},
-- No pathological science here: its research asks for Fulgora's science, a later system than Corrundum.
{"planet-discovery-corrundum", {}, {{"planetaris-bioengineering-science-pack", "planet-discovery-tellus"}}},
-- No thermodynamic science here: its research needs natrocarbonatite, which pulls Dea Dia, Lemures and
-- Prosephina into the research of every later system. Dea Dia reaches the gateways through the Nyxaris card
-- and regional_research_bridges.lua.
{"planet-discovery-apia-carnova", {"planet-discovery-gleba", "planet-discovery-moshine"}, {{"agricultural-science-pack", "planet-discovery-gleba"}}},
-- Link Panglia to actual upstream industries while keeping source-authored
-- Moshine data cells, DNA triggers, cloning and timewarp machines unchanged.
{"panglia_tech_timewarp_data", {"planet-discovery-moshine"},
 {{"thermodynamic-science-pack", "planet-discovery-moshine"}}},
{"panglia_advanced_optics_nanotech", {"planet-discovery-apia-carnova"}, {}},
{"panglia_dna_manipulation", {"planet-discovery-tellus", "planet-discovery-apia-carnova"},
 {{"planetaris-bioengineering-science-pack", "planet-discovery-tellus"},
  {"apicultural-science-pack", "planet-discovery-apia-carnova"}}},
{"panglia_sentient_processor", {"planet-discovery-tellus"},
 {{"planetaris-bioengineering-science-pack", "planet-discovery-tellus"}}},
{"planet-discovery-ribbonia", {"planet-discovery-fulgora"}, {{"electromagnetic-science-pack", "planet-discovery-fulgora"}}},
{"planet-discovery-paracelsin", {}, {{"ribbonia-alien-science-pack", "planet-discovery-ribbonia"}}},
-- Muria's science is called acidworking since Muria 1.7.
{"planet-discovery-aquilo", {"planet-discovery-fulgora"}, {{"acidworking-science-pack", "planet-discovery-muria"}}},
-- Rubia has no rule: Aquilo comes after Rubia, so Aquilo's cryogenic science cannot be asked for here.
{"planet-discovery-maraxsis", {"planet-discovery-paracelsin"}, {{"rubia-biofusion-science-pack", "planet-discovery-rubia"}}},
-- Secretas has no rule: golden science is made on Secretas itself, its research follows the discovery.
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
  return Science.exists(pack)
end

-- Every campaign milestone used to scan the entire recipe catalogue, then
-- every locked producer scanned every technology again. This final-stage
-- index is rebuilt on each pass, after all source mods have registered their
-- recipes. Dependencies still use the LIVE technology graph at query time.
local producers_by_pack, unlockers_by_recipe = {}, {}

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
  -- There's no need to retain unlocks for every unrelated recipe
  -- installed by this modpack. Only science producers are queried below.
  local relevant={}
  for _,recipes in pairs(producers) do
    for _,recipe_name in ipairs(recipes) do relevant[recipe_name]=true end
  end
  if next(relevant) then
    for name, tech in pairs(data.raw.technology or {}) do
      for _, effect in ipairs(tech.effects or {}) do
        if effect.type=="unlock-recipe" and relevant[effect.recipe] then
          local matches=unlockers[effect.recipe]
          if not matches then matches={} unlockers[effect.recipe]=matches end
          matches[#matches+1]=name
        end
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

local lab_inputs
local function has_compatible_lab(ingredients, pack)
  if not lab_inputs then
    lab_inputs={}
    for _,lab in pairs(data.raw.lab or {}) do
      if lab.inputs then
        local accepted={}
        for _,item in ipairs(lab.inputs) do accepted[item]=true end
        lab_inputs[#lab_inputs+1]=accepted
      end
    end
  end
  for _,accepted in ipairs(lab_inputs) do
    if accepted[pack] then
      local valid=true
      for _,ingredient in ipairs(ingredients) do
        if not accepted[ingredient.name or ingredient[1]] then
          valid=false
          break
        end
      end
      if valid then return true end
    end
  end
  return false
end

local function add_science(target, pack, owner)
  local t = technology(target)
  if not (t and t.unit and t.unit.ingredients) then return end
  if not has_production_recipe_before(pack, target, owner) then return end
  -- Research is valid only if one existing lab handles all ingredients.
  if has_compatible_lab(t.unit.ingredients, pack) then
    Science.add_pack(t.unit.ingredients, pack)
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
        add_science(target,pack,owner)
      end
    end
  end
end

return M
