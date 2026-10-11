-- The visual composition follows the original Calidus-centered Razi starmap.
local M = {}

-- Calidus-centered radial gallery: six stars with preserved local crescents.
-- Visual coordinates do not modify route lengths or research.
local anchors = {
  {"space-location","solaris","star",189.010582,0.1459},
  {"space-location","nyxaris","star",171.723615,0.339985},
  {"space-location","vibrant","star",181.107703,0.482388},
  {"space-location","vespera","star",198.010101,0.627273},
  {"space-location","beetlejuice","star",181.727818,0.771964},
  {"space-location","umbra","star",182.222392,0.905448},
  {"space-location","solar-system-edge","star",330.588869,0.827668},
  {"space-location","sye-calidus","star",36.400549,0.603291},
  {"space-location","sye-solaris","solaris",37.20215,0.649295},
  {"space-location","sye-vibrant","vibrant",32.249031,0.167375},
  {"space-location","sye-beetlejuice","beetlejuice",33.105891,0.319491},
  {"space-location","sye-nyxaris","nyxaris",33.015148,0.847595},
  {"space-location","sye-vespera","vespera",33.600595,0.148531},
  {"space-location","sye-umbra","umbra",30.870698,0.31918},
  {"planet","vulcanus","solaris",44.471904,0.590054},
  {"planet","castra","solaris",41.0112,0.454013},
  {"planet","arig","solaris",40.113792,0.307767},
  {"planet","hyarion","solaris",23.749056,0.288319},
  {"planet","tellus","solaris",35.714112,0.148624},
  {"planet","corrundum","solaris",26.202912,0.975921},
  {"planet","gleba","nyxaris",40.113792,0.939123},
  {"planet","moshine","nyxaris",37.27968,0.093418},
  {"space-location","apia-carnova-orbit","nyxaris",34.413024,0.183703},
  {"planet","panglia","nyxaris",38.412,0.751539},
  {"planet","fulgora","vibrant",39.779232,0.072262},
  {"planet","ribbonia","vibrant",34.18464,0.911417},
  {"planet","paracelsin","vibrant",28.103616,0.789224},
  {"planet","shchierbin","vibrant",27.906144,0.630785},
  {"planet","muria","vespera",26.897184,0.292815},
  {"planet","aquilo","vespera",31.694496,0.396092},
  {"space-location","razi-vespera-belt-inner","vespera",30.674976,0.492562},
  {"space-location","razi-vespera-belt-outer","vespera",30.734976,0.553469},
  {"planet","rubia","vespera",30.629856,0.637929},
  {"planet","maraxsis","vespera",28.879872,0.755657},
  {"planet","cubium","beetlejuice",26.897184,0.175207},
  {"planet","linox-planet_linox","beetlejuice",34.18464,0.063533},
  {"space-location","secretas","beetlejuice",30.357888,0.868317},
  {"planet","tenebris","umbra",26.897184,0.463464},
  {"space-location","crucible-orbit","umbra",34.94448,0.572437},
  {"space-location","razi-umbra-belt-inner","umbra",32.654112,0.651633},
  {"space-location","razi-umbra-belt-outer","umbra",31.694496,0.714324},
  {"planet","vesta","umbra",31.490304,0.823503},
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
  local signature={vulcanus=true,gleba=true,fulgora=true,
    muria=true,cubium=true,tenebris=true}
  for _, kind in ipairs({"planet","space-location"}) do
    for _, location in pairs(data.raw[kind] or {}) do
      local orbit = location.orbit
      local parent = orbit and orbit.parent
      if parent and parent.type=="space-location" and stars[parent.name] then
        location.draw_orbit=(signature[location.name]==true)
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
