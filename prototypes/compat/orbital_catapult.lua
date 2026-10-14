-- Experimental local shuttle lane using the source Orbital Catapult
-- extension point; source mod is intentionally NOT a hard dependency.
local M={}
M.links={
  {"razi-muria-aquilo-catapult","muria","aquilo"},
  {"razi-aquilo-muria-catapult","aquilo","muria"}
}
function M.definitions(raw,loaded,enabled)
  if not (loaded and enabled) then return {} end
  local planets=raw and raw.planet or {}
  local links={}
  for _,spec in ipairs(M.links) do
    if planets[spec[2]] and planets[spec[3]] then
      links[#links+1]={type="orbital-cannon-link",
        name=spec[1],source=spec[2],target=spec[3],
        link_type="transport"}
    end
  end
  return links
end
function M.data()
  local active=mods and mods["orbital-cannon"]
  local switch=settings and settings.startup
    and settings.startup["razi-orbital-catapult-local-links"]
  local enabled=switch and switch.value==true
  local links=M.definitions(data.raw,active,enabled)
  if #links>0 then data:extend(links) end
end
return M
