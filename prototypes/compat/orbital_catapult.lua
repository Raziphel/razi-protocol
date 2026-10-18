-- Razi's short-haul Vespera freight lanes for Orbital Catapult >=0.15.
-- Orbital Catapult registers its custom link type during data stage and
-- consumes these records in data-final-fixes, AFTER Razi remaps the planets.
-- Keep the two original Muria/Aquilo identifiers stable for old saves.
-- A corridor needs TWO directional source-owned link prototypes.
-- No technology, launch recipe, platform route or destination is unlocked.
local M={}
M.links={
  {"razi-muria-aquilo-catapult","muria","aquilo"},
  {"razi-aquilo-muria-catapult","aquilo","muria"},
  {"razi-muria-rubia-catapult","muria","rubia"},
  {"razi-rubia-muria-catapult","rubia","muria"},
  {"razi-rubia-aquilo-catapult","rubia","aquilo"},
  {"razi-aquilo-rubia-catapult","aquilo","rubia"}
}
function M.definitions(raw,loaded,enabled)
  if not (loaded and enabled) then return {} end
  local planets=raw and raw.planet or {}
  local occupied=raw and raw["orbital-cannon-link"] or {}
  local links={}
  local seen={}
  for _,spec in ipairs(M.links) do
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
  -- The mod is REQUIRED in info.json, but this guard makes the link
  -- exporter testable and avoids adding unknown custom prototypes.
  local loaded=mods and mods["orbital-cannon"]
  local switch=settings and settings.startup
    and settings.startup["razi-orbital-catapult-local-links"]
  local enabled=switch and switch.value==true
  local links=M.definitions(data.raw,loaded,enabled)
  if #links>0 then data:extend(links) end
end
return M
