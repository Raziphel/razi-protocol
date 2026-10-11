-- Calidus-centered hexagonal star ring with an isolated northern endgame.
local M = {}

-- Campaign order follows the ring from south to north: first, middle, outer.
-- Physical route lengths, unlock prerequisites and native moons stay unchanged.
-- Six equally spaced campaign systems around the original Calidus center.
-- North is NEGATIVE Y (Factorio orientation 0); Deep Space is far north.
-- Local planets keep their native route graphs and readable spacing.
local anchors = {
  {"space-location","solaris","star",121.938509,0.415109},
  {"space-location","nyxaris","star",121.938509,0.584891},
  {"space-location","vibrant","star",124,0.25},
  {"space-location","vespera","star",124,0.75},
  {"space-location","beetlejuice","star",121.938509,0.084891},
  {"space-location","umbra","star",121.938509,0.915109},
  {"space-location","solar-system-edge","star",248,0},
  {"space-location","sye-calidus","star",25,0.5},
  {"space-location","sye-solaris","solaris",27,0.75},
  {"space-location","sye-vibrant","vibrant",28.017851,0.653265},
  {"space-location","sye-beetlejuice","beetlejuice",27,0.5},
  {"space-location","sye-nyxaris","nyxaris",27,0},
  {"space-location","sye-vespera","vespera",26,0.25},
  {"space-location","sye-umbra","umbra",27,0.5},
  {"planet","vulcanus","solaris",41.80359,0.690759},
  {"planet","castra","solaris",38.550528,0.554718},
  {"planet","arig","solaris",37.706964,0.408472},
  {"planet","hyarion","solaris",22.324113,0.389024},
  {"planet","tellus","solaris",33.571265,0.249329},
  {"planet","corrundum","solaris",24.630737,0.076626},
  {"planet","gleba","nyxaris",37.706964,0.091528},
  {"planet","moshine","nyxaris",35.042899,0.245823},
  {"space-location","apia-carnova-orbit","nyxaris",32.348243,0.316108},
  {"planet","panglia","nyxaris",36.10728,0.903944},
  {"planet","fulgora","vibrant",37.392478,0.558152},
  {"planet","ribbonia","vibrant",32.133562,0.397307},
  {"planet","paracelsin","vibrant",26.417399,0.275114},
  {"planet","shchierbin","vibrant",26.231775,0.116675},
  {"planet","muria","vespera",25.283353,0.394284},
  {"planet","aquilo","vespera",29.792826,0.497561},
  {"space-location","razi-vespera-belt-inner","vespera",28.834477,0.594031},
  {"space-location","razi-vespera-belt-outer","vespera",28.890877,0.654938},
  {"planet","rubia","vespera",28.792065,0.739398},
  {"planet","maraxsis","vespera",27.14708,0.857126},
  {"planet","cubium","beetlejuice",25.283353,0.355716},
  {"planet","linox-planet_linox","beetlejuice",32.133562,0.244042},
  {"space-location","secretas","beetlejuice",28.536415,0.048826},
  {"planet","tenebris","umbra",25.283353,0.644284},
  {"space-location","crucible-orbit","umbra",32.847811,0.753257},
  {"space-location","razi-umbra-belt-inner","umbra",30.694865,0.832453},
  {"space-location","razi-umbra-belt-outer","umbra",29.792826,0.895144},
  {"planet","vesta","umbra",29.600886,0.004323},
}

local stars = {
  solaris=true, nyxaris=true, vibrant=true, vespera=true,
  beetlejuice=true, umbra=true
}

local function exists(kind, name)
  local bucket = data.raw[kind]
  return bucket and bucket[name]
end

function M.data_final_fixes()
  local updates = {}
  for _, item in ipairs(anchors) do
    local kind, name, parent, radius, turn =
      item[1], item[2], item[3], item[4], item[5]
    if exists(kind, name) and exists("space-location", parent) then
      updates[#updates+1] = {
        type=kind, name=name,
        orbit={
          parent={type="space-location",name=parent},
          distance=radius, orientation=turn
        }
      }
    end
  end
  if #updates>0 then PlanetsLib:update(updates) end

  -- PlanetsLib >= 2.0 uses Factorio's native origin-based orbit renderer.
  -- Previously we drew only six signature rings, hiding every other orbit.
  -- Native planet rings should remain enabled around Razi's six stars, even
  -- when an upstream mod explicitly disabled them for the old sprite system.
  -- Do NOT overwrite moons: their native planet-parent orbit and any custom
  -- sprites (Apia-Carnova, Frozeta, etc.) belong to their source mods.
  for _, planet in pairs(data.raw.planet or {}) do
    local orbit = planet.orbit
    local parent = orbit and orbit.parent
    if parent and parent.type == "space-location" and stars[parent.name] then
      planet.draw_orbit = true
    end
  end

  -- Secretas is represented by a space-location rather than a planet; it is
  -- an actual orbiting world, unlike the artificial slipstream and belt nodes.
  local secretas=exists("space-location","secretas")
  if secretas then
    local parent=secretas.orbit and secretas.orbit.parent
    if parent and parent.type=="space-location" and stars[parent.name] then
      secretas.draw_orbit=true
    end
  end

  -- Keep synthetic transit locations and sprite-only star anchors free of
  -- spurious sun-centered rings. This does not affect the planet orbits.
  for _, name in ipairs({
    "solaris","nyxaris","vibrant","vespera","beetlejuice","umbra",
    "solar-system-edge","sye-calidus","sye-solaris","sye-nyxaris",
    "sye-vibrant","sye-vespera","sye-beetlejuice","sye-umbra"
  }) do
    local location=exists("space-location",name)
    if location then location.draw_orbit=false end
  end
end

return M
