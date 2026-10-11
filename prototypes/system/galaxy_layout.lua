-- A compact branching constellation. Calidus is the apex; the two
-- expedition branches descend through a shared midgame asteroid frontier,
-- then reunite at Deep Space. Coordinates are display-only; km and hazards
-- live in route_reconcile.lua and the source AsteroidBelt crossing.
-- Directions are Factorio turns: north=0, east=.25, south=.5, west=.75.
local M = {}

local anchors = {
  -- Paired stellar chambers widen gently down the map instead of forming
  -- oversized left-to-right columns with huge empty regions.
  {"space-location","solaris","star",82.0731,0.6195141},
  {"space-location","nyxaris","star",82.0731,0.3804859},
  {"space-location","vibrant","star",154.7385,0.5747118},
  {"space-location","vespera","star",154.7385,0.4252882},
  {"space-location","beetlejuice","star",234.3502,0.5598028},
  {"space-location","umbra","star",234.3502,0.4401972},
  {"space-location","solar-system-edge","star",310,0.5},
  -- Calidus is the top of the constellation; portals sit ABOVE each star
  -- and on the outward face of their own branch.
  {"space-location","sye-calidus","star",24,0.5},
  {"space-location","sye-solaris","solaris",28.0631,0.8999657},
  {"space-location","sye-vibrant","vibrant",28.0631,0.8999657},
  {"space-location","sye-beetlejuice","beetlejuice",28.0631,0.8999657},
  {"space-location","sye-nyxaris","nyxaris",28.0631,0.1000343},
  {"space-location","sye-vespera","vespera",28.0631,0.1000343},
  {"space-location","sye-umbra","umbra",28.0631,0.1000343},
  -- Local discovery chains form concise, nonintersecting planetary crescents.
  {"planet","vulcanus","solaris",46.3249,0.8407248},
  {"planet","castra","solaris",42.72,0.7046837},
  {"planet","arig","solaris",41.7612,0.5463868},
  {"planet","hyarion","solaris",40.3113,0.4802083},
  {"planet","tellus","solaris",30,0.3524164},
  {"planet","corrundum","solaris",27.2947,0.2265918},
  {"planet","gleba","nyxaris",41.7852,0.1915625},
  {"planet","moshine","nyxaris",38.833,0.345857},
  {"space-location","apia-carnova-orbit","nyxaris",35.8469,0.4361425},
  {"planet","panglia","nyxaris",40.0125,0.003978},
  {"planet","fulgora","vibrant",41.4367,0.8048523},
  {"planet","ribbonia","vibrant",35.609,0.6440077},
  {"planet","paracelsin","vibrant",29.2746,0.5218148},
  {"planet","shchierbin","vibrant",29.0689,0.3633752},
  {"planet","muria","vespera",28.0179,0.2443183},
  {"planet","aquilo","vespera",33.0151,0.347595},
  {"space-location","razi-vespera-belt-inner","vespera",31.9531,0.4440658},
  {"space-location","razi-vespera-belt-outer","vespera",32.0156,0.504972},
  {"planet","rubia","vespera",31.9061,0.5894326},
  {"planet","maraxsis","vespera",30.0832,0.7071607},
  {"planet","cubium","beetlejuice",28.0179,0.7556817},
  {"planet","linox-planet_linox","beetlejuice",35.609,0.6440077},
  {"space-location","secretas","beetlejuice",31.6228,0.4487918},
  {"planet","tenebris","umbra",28.0179,0.2443183},
  {"space-location","crucible-orbit","umbra",36.4005,0.3532909},
  {"space-location","razi-umbra-belt-inner","umbra",34.0147,0.4324874},
  {"space-location","razi-umbra-belt-outer","umbra",33.0151,0.4951786},
  {"planet","vesta","umbra",32.8024,0.6043572},
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

  -- The old ring forest was much larger than the planets themselves. Keep
  -- native moon orbits, but suppress cosmetic rings around our six stars.
  for _, kind in ipairs({"planet","space-location"}) do
    for _, location in pairs(data.raw[kind] or {}) do
      local orbit = location.orbit
      local parent = orbit and orbit.parent
      if parent and parent.type=="space-location" and stars[parent.name] then
        location.draw_orbit=false
      end
    end
  end
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
