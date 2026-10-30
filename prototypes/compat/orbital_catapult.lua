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
return M
