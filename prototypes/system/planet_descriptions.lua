-- Append campaign context to source-mod planet and space-location descriptions.
-- Keep the original author's wording, including translated descriptions and
-- gameplay rules. Optional worlds are touched only when their prototype exists.
local descriptions = {}
local configured = setmetatable({}, {__mode = "k"})

local destinations = {
  calidus = {"nauvis", "muluna", "sye-calidus", "halo-solar-orbit", "halo-solar-station"},
  solaris = {"vulcanus", "castra", "arig", "hyarion", "tellus", "corrundum", "igrys", "solaris", "sye-solaris", "igrys-orbit"},
  nyxaris = {"gleba", "moshine", "panglia", "apia", "carnova", "foliax", "rabbasca", "velora", "pelagos", "lemures", "prosephina", "nyxaris", "sye-nyxaris", "apia-carnova-orbit", "star-dea-dia", "dea-dia-system-edge", "razi-dea-dia-slip-stream"},
  vibrant = {"fulgora", "ribbonia", "paracelsin", "cerys", "shchierbin", "alchemy-planet", "vibrant", "sye-vibrant", "khemia", "asteroid-belt-inner-edge", "asteroid-belt-outer-edge"},
  vespera = {"muria", "aquilo", "nulla", "rubia", "maraxsis", "bm-balack", "athos", "vespera", "sye-vespera"},
  beetlejuice = {"cubium", "linox-planet_linox", "secretas", "frozeta", "ferrum", "beetlejuice", "sye-beetlejuice", "planet-ferrum"},
  umbra = {"tenebris", "crucible", "vesta", "abacayba", "carna", "arcanyx", "obsidiax", "umbra", "sye-umbra", "razi-umbra-belt-inner", "razi-umbra-belt-outer", "crucible-orbit"},
  aegis = {"pulsar", "calidus-bellicos-stargate-calidus",
    "aegis-inner-edge", "aegis-outer-edge",
    "near-bellicos-orbit", "bellicos-near-orbit", "near_bellicos_orbit",
    "point-warden", "aegis-point-warden"},
  deep_space = {"nexus", "shattered-planet", "skewer_shattered_planet",
    "skewer_lost_beyond", "solar-system-edge",
    "black-hole-approach", "black-hole", "oort-cloud", "sol",
    "razi-deep-space-edge"}
}

-- Native descriptions are still authoritative for mechanics, but some
-- relocated Aegis source tooltips literally describe a return to Calidus
-- or the removed Bellicos stargate. Only these MOVED chart waypoints use a
-- corrected primary geographical description. All non-location mechanics,
-- planet descriptions and ordinary source prose remain unchanged.
local relocated_source_briefs = {
  ["calidus-bellicos-stargate-calidus"]=true,
  ["aegis-inner-edge"]=true,["aegis-outer-edge"]=true,
  ["near-bellicos-orbit"]=true,["bellicos-near-orbit"]=true,
  ["near_bellicos_orbit"]=true,
  ["point-warden"]=true,["aegis-point-warden"]=true
}
local function original_description(prototype, name)
  if relocated_source_briefs[name] then
    return {"", {"razi-location-primary." .. name}, "\n\n"}
  end
  if prototype.localised_description then
    return {"", prototype.localised_description, "\n\n"}
  end
  -- Some mods provide only a locale entry. The fallback keeps missing keys
  -- from appearing as "Unknown key" if that entry does not exist.
  return {"?", {"", {"space-location-description." .. name}, "\n\n"}, ""}
end

function descriptions.data_final_fixes()
  local preference = settings and settings.startup
    and settings.startup["razi-enable-expedition-briefings"]
  if preference and preference.value == false then return end

  for region, names in pairs(destinations) do
    local heading = region == "deep_space" and "deep-space" or region
    for _, name in ipairs(names) do
      for _, kind in ipairs({"planet", "space-location"}) do
        local bucket = data.raw[kind]
        local location = bucket and bucket[name]
        if location and not configured[location] then
          location.localised_description = {
            "",
            original_description(location, name),
            {"razi-expedition-heading." .. heading},
            "\n",
            {"razi-location-briefing." .. name}
          }
          configured[location] = true
        end
      end
    end
  end
end

return descriptions
