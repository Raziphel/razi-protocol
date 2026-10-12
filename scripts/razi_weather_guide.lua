-- Read-only atmosphere notes for the world's installed visual effects.
-- Never edits the weather mod settings or manufactures fake weather events.
local M={}
local worlds={
  panglia={"panglia_planet_discovery_panglia","shibadisaster-cwa-enable-panglia-changes"},
  muria={"planet-discovery-muria","shibadisaster-cwa-enable-muria-changes"},
  vesta={"planet-discovery-vesta","shibadisaster-cwa-enable-vesta-changes"},
  rubia={"planet-discovery-rubia","shibadisaster-cwa-enable-rubia-changes"},
  paracelsin={"planet-discovery-paracelsin","shibadisaster-cwa-enable-paracelsin-changes"},
  cubium={"planet-discovery-cubium","shibadisaster-cwa-enable-cubium-changes"},
  rabbasca={"rabbasca","shibadisaster-cwa-enable-rabbasca-changes"},
  igrys={"igrys","shibadisaster-cwa-enable-igrys-changes"},
  khemia={"khemia","shibadisaster-cwa-enable-khemia-changes"},
  carna={"carna","shibadisaster-cwa-enable-carna-changes"},
  pelagos={"pelagos","shibadisaster-cwa-enable-pelagos-changes"}
}
local by_tech={}
for world,config in pairs(worlds) do by_tech[config[1]]=world end

function M.for_quest(quest)
  if not (quest and script and script.active_mods
    and script.active_mods["celestial-weather-additions-updated"]) then
    return nil
  end
  local world=quest.weather_world or quest.world or by_tech[quest.tech]
  local config=worlds[world]
  if not config then return nil end
  local setting=settings and settings.startup
    and settings.startup[config[2]]
  -- An absent source setting indicates the effect isn't defined for the
  -- installed optional planet. Do not report it active.
  return {world=world,enabled=setting~=nil and setting.value==true}
end

M.worlds=worlds
return M
