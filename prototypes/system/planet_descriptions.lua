-- Append campaign context to source-mod planet and space-location descriptions.
-- Keep the original author's wording, including translated descriptions and
-- gameplay rules. Optional worlds are touched only when their prototype exists.
local descriptions = {}
local configured = setmetatable({}, {__mode = "k"})

local destinations = {
  calidus = {"nauvis", "muluna", "eneas", "sye-calidus"},
  solaris = {"vulcanus", "castra", "arig", "hyarion", "tellus", "corrundum", "igrys", "athos", "solaris", "sye-solaris"},
  nyxaris = {"gleba", "moshine", "apia", "carnova", "panglia", "foliax", "rabbasca", "pelagos", "lemures", "prosephina", "nyxaris", "sye-nyxaris", "apia-carnova-orbit", "star-dea-dia", "dea-dia-system-edge"},
  vibrant = {"fulgora", "ribbonia", "paracelsin", "shchierbin", "cerys", "vibrant", "sye-vibrant"},
  vespera = {"muria", "aquilo", "rubia", "maraxsis", "obsidiax", "vespera", "sye-vespera", "razi-vespera-belt-inner", "razi-vespera-belt-outer"},
  beetlejuice = {"cubium", "linox-planet_linox", "secretas", "frozeta", "beetlejuice", "sye-beetlejuice"},
  umbra = {"tenebris", "crucible", "vesta", "carna", "umbra", "sye-umbra", "razi-umbra-belt-inner", "razi-umbra-belt-outer", "crucible-orbit"},
  deep_space = {"nexus", "shattered-planet", "solar-system-edge", "pulsar", "calidus-bellicos-stargate-calidus", "calidus-bellicos-stargate-bellicos", "black-hole-approach", "black-hole", "oort-cloud", "sol"}
}

local function original_description(prototype, name)
  if prototype.localised_description then
    return {"", prototype.localised_description, "\n\n"}
  end
  -- Some mods provide only a locale entry. The fallback keeps missing keys
  -- from appearing as "Unknown key" if that entry does not exist.
  return {"?", {"", {"space-location-description." .. name}, "\n\n"}, ""}
end

function descriptions.data_final_fixes()
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
