-- Native 2.1 starmap polish. Applies after PlanetsLib and planet patches.
-- Only Razi's known interstellar corridors receive route shape adjustments.
-- Tooltip fields are additive, so other mods can keep their own details.
local polish = {}

local regions = {
  ["star"] = "calidus", nauvis = "calidus", vulcanus = "calidus",
  fulgora = "calidus", gleba = "calidus", aquilo = "vibrant",
  muluna = "calidus", cerys = "calidus", eneas = "calidus",
  ["sye-calidus"] = "calidus",
  solaris = "solaris", ["sye-solaris"] = "solaris",
  castra = "solaris", arig = "solaris", hyarion = "solaris",
  tellus = "solaris", corrundum = "solaris",
  nyxaris = "nyxaris", ["sye-nyxaris"] = "nyxaris",
  ["apia-carnova-orbit"] = "nyxaris", ["apia-carnova"] = "nyxaris",
  moshine = "nyxaris", pelagos = "nyxaris",
  ["star-dea-dia"] = "nyxaris", ["dea-dia-system-edge"] = "nyxaris",
  ["dea-dia"] = "nyxaris", lemures = "nyxaris", prosephina = "nyxaris",
  vibrant = "vibrant", ["sye-vibrant"] = "vibrant",
  ribbonia = "vibrant", paracelsin = "vibrant", rubia = "vibrant",
  maraxsis = "vibrant", muria = "vibrant",
  beetlejuice = "beetlejuice", ["sye-beetlejuice"] = "beetlejuice",
  cubium = "beetlejuice", secretas = "beetlejuice",
  frozeta = "beetlejuice", tenebris = "beetlejuice",
  crucible = "beetlejuice", ["crucible-orbit"] = "beetlejuice",
  vesta = "beetlejuice", ["linox-planet_linox"] = "beetlejuice",
  ["solar-system-edge"] = "deep-space", ["shattered-planet"] = "deep-space",
  nexus = "deep-space", ["black-hole"] = "deep-space",
  ["black-hole-approach"] = "deep-space", ["oort-cloud"] = "deep-space",
  sol = "deep-space"
}

local deep_space_locations = {
  ["solar-system-edge"] = true, ["shattered-planet"] = true,
  nexus = true, ["black-hole"] = true,
  ["black-hole-approach"] = true, ["oort-cloud"] = true, sol = true
}

local function annotate(prototype, kind, value)
  local fields = prototype.custom_tooltip_fields or {}
  for _, existing in ipairs(fields) do
    if existing.name and type(existing.name) == "table" and
       existing.name[1] == "razi-starmap.route-type-label" and kind == "route" then
      return
    end
  end
  fields[#fields + 1] = {
    name = {"razi-starmap." .. (kind == "route" and "route-type-label" or "region-label")},
    value = {"razi-starmap." .. value},
    order = 75
  }
  prototype.custom_tooltip_fields = fields
end

local function type_for(connection)
  local from, to = connection.from, connection.to
  if deep_space_locations[from] or deep_space_locations[to] then return "route-deep-space" end
  if from:match("^sye%-") and to:match("^sye%-") then return "route-slipstream" end
  if from:match("^sye%-") or to:match("^sye%-") then return "route-gateway" end
  return "route-local"
end

function polish.data_final_fixes()
  for _, route in pairs(data.raw["space-connection"] or {}) do
    local from, to = route.from, route.to
    if type(from) == "string" and type(to) == "string" and
       (regions[from] or regions[to]) then
      local kind = type_for(route)
      annotate(route, "route", kind)
      -- A straight span reads as a deliberate long-haul corridor;
      -- preserve existing custom shapes provided by other mod authors.
      if not route.shape and (kind == "route-slipstream" or
        kind == "route-deep-space") then
        route.shape = "line"
      end
    end
  end

  for name, region in pairs(regions) do
    local location = (data.raw.planet or {})[name] or
      (data.raw["space-location"] or {})[name]
    if location then
      annotate(location, "planet", "region-" .. region)
    end
  end
end

return polish
