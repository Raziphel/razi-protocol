-- Orbital Catapult 0.15+ supplies powered transport. Razi only declares
-- directed, nearby corridors; native science, power and freight are source-owned.
-- Preserve original Vespera IDs for saves and external integrations.
local M={}
M.links={
  {"razi-muria-aquilo-catapult","muria","aquilo"},
  {"razi-aquilo-muria-catapult","aquilo","muria"},
  {"razi-muria-rubia-catapult","muria","rubia"},
  {"razi-rubia-muria-catapult","rubia","muria"},
  {"razi-rubia-aquilo-catapult","rubia","aquilo"},
  {"razi-aquilo-rubia-catapult","aquilo","rubia"}
}
-- Second, independently switchable freight layer on real local planet
-- corridors. No asteroid belt, cross-star lane, or new location prototype.
M.regional_links={
  {"razi-vulcanus-castra-catapult","vulcanus","castra"},
  {"razi-castra-vulcanus-catapult","castra","vulcanus"},
  {"razi-gleba-moshine-catapult","gleba","moshine"},
  {"razi-moshine-gleba-catapult","moshine","gleba"},
  {"razi-rubia-maraxsis-catapult","rubia","maraxsis"},
  {"razi-maraxsis-rubia-catapult","maraxsis","rubia"}
}
function M.active_links(local_enabled,regional_enabled)
  local result={}
  if local_enabled then
    for _,spec in ipairs(M.links) do result[#result+1]=spec end
  end
  if regional_enabled then
    for _,spec in ipairs(M.regional_links) do result[#result+1]=spec end
  end
  return result
end
-- Fourth argument defaults to OFF for older callers/tests that inspect only
-- the original three Vespera corridors.
function M.definitions(raw,loaded,enabled,regional_enabled)
  if not loaded then return {} end
  local planets=raw and raw.planet or {}
  local occupied=raw and raw["orbital-cannon-link"] or {}
  local links={}
  local seen={}
  for _,spec in ipairs(M.active_links(enabled,regional_enabled)) do
    local name,source,target=spec[1],spec[2],spec[3]
    if not seen[name] and not (occupied and occupied[name])
      and source~=target and planets[source] and planets[target] then
      seen[name]=true
      links[#links+1]={
        type="orbital-cannon-link",name=name,
        source=source,target=target,link_type="transport"
      }
    end
  end
  return links
end
function M.data()
  local loaded=mods and mods["orbital-cannon"]
  local primary=settings and settings.startup
    and settings.startup["razi-orbital-catapult-local-links"]
  local regional=settings and settings.startup
    and settings.startup["razi-orbital-catapult-regional-links"]
  local links=M.definitions(data.raw,loaded,
    primary and primary.value==true,regional and regional.value==true)
  if #links>0 then data:extend(links) end
end
-- Orbital Catapult adds its recipe locked and leaves the unlock to the mods that
-- use it. Razi opens it once the first corridor (Muria and Rubia) is reachable and
-- the recipe's superconductors and efficiency modules are researched.
M.technology_name="razi-orbital-catapult"
M.prerequisites={"planet-discovery-rubia","electromagnetic-plant","efficiency-module-2"}
M.research_count=500
local function unlocked(raw,recipe)
  for _,technology in pairs(raw.technology or {}) do
    for _,effect in ipairs(technology.effects or {}) do
      if effect.type=="unlock-recipe" and effect.recipe==recipe then return true end
    end
  end
  return false
end
-- The technology, or nil when the mod, its recipe or a prerequisite is missing,
-- or another mod already unlocks the recipe. Its science is that of the Rubia
-- discovery, so it follows whatever cards the gates gave that discovery.
function M.technology(raw,loaded)
  if not loaded then return nil end
  local technologies=raw and raw.technology or {}
  if technologies[M.technology_name] or not (raw.recipe and raw.recipe["orbital-cannon"])
    or unlocked(raw,"orbital-cannon") then return nil end
  for _,name in ipairs(M.prerequisites) do
    if not technologies[name] then return nil end
  end
  local unit=technologies[M.prerequisites[1]].unit
  if not (unit and unit.ingredients) then return nil end
  local ingredients={}
  for _,ingredient in ipairs(unit.ingredients) do
    ingredients[#ingredients+1]={ingredient[1] or ingredient.name,ingredient[2] or ingredient.amount}
  end
  return {
    type="technology",name=M.technology_name,
    localised_name={"entity-name.orbital-cannon"},
    localised_description={"technology-description."..M.technology_name},
    icon="__orbital-cannon__/graphics/icon/orbital-interlink-tech-icon.png",icon_size=256,
    prerequisites={table.unpack(M.prerequisites)},
    effects={{type="unlock-recipe",recipe="orbital-cannon"}},
    unit={count=M.research_count,time=60,ingredients=ingredients},
    order="e[orbital-catapult]"
  }
end
function M.data_final_fixes()
  local technology=M.technology(data.raw,mods and mods["orbital-cannon"])
  if technology then data:extend({technology}) end
end
return M
