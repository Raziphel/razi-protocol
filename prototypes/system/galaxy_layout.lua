-- The visual composition follows the original Calidus-centered Razi starmap.
local M = {}

-- Star pairs now form a compact, readable ring around Calidus.
-- Visual coordinates do not modify route lengths or research.
-- Compact six-sector Calidus gallery. Preserve original worlds and local routes.
-- Visual polar units are separate from gameplay travel lengths and science.
local anchors = {
  {"space-location","solaris","star",128.062485,0.142612},
  {"space-location","nyxaris","star",120.415946,0.865649},
  {"space-location","vibrant","star",127.757583,0.301996},
  {"space-location","vespera","star",124.651514,0.693946},
  {"space-location","beetlejuice","star",154.434452,0.419293},
  {"space-location","umbra","star",161.136588,0.580419},
  {"space-location","solar-system-edge","star",232,0.5},
  {"space-location","sye-calidus","star",25.495098,0.468584},
  {"space-location","sye-solaris","solaris",33.54102,0.676208},
  {"space-location","sye-vibrant","vibrant",26.925824,0.310559},
  {"space-location","sye-beetlejuice","beetlejuice",32.015621,0.892612},
  {"space-location","sye-nyxaris","nyxaris",36.055513,0.406416},
  {"space-location","sye-vespera","vespera",31.622777,0.698792},
  {"space-location","sye-umbra","umbra",36.055513,0.093584},
  {"planet","vulcanus","solaris",41.80359,0.616967},
  {"planet","castra","solaris",38.550528,0.480926},
  {"planet","arig","solaris",37.706964,0.33468},
  {"planet","hyarion","solaris",22.324113,0.315232},
  {"planet","tellus","solaris",33.571265,0.175537},
  {"planet","corrundum","solaris",24.630737,0.002834},
  {"planet","gleba","nyxaris",37.706964,0.497944},
  {"planet","moshine","nyxaris",35.042899,0.652239},
  {"space-location","apia-carnova-orbit","nyxaris",32.348243,0.742524},
  {"planet","panglia","nyxaris",36.10728,0.31036},
  {"planet","fulgora","vibrant",37.392478,0.215446},
  {"planet","ribbonia","vibrant",32.133562,0.054601},
  {"planet","paracelsin","vibrant",26.417399,0.932408},
  {"planet","shchierbin","vibrant",26.231775,0.773969},
  {"planet","muria","vespera",25.283353,0.843076},
  {"planet","aquilo","vespera",29.792826,0.946353},
  {"space-location","razi-vespera-belt-inner","vespera",28.834477,0.042823},
  {"space-location","razi-vespera-belt-outer","vespera",28.890877,0.10373},
  {"planet","rubia","vespera",28.792065,0.18819},
  {"planet","maraxsis","vespera",27.14708,0.305918},
  {"planet","cubium","beetlejuice",25.283353,0.748328},
  {"planet","linox-planet_linox","beetlejuice",32.133562,0.636654},
  {"space-location","secretas","beetlejuice",28.536415,0.441438},
  {"planet","tenebris","umbra",25.283353,0.237868},
  {"space-location","crucible-orbit","umbra",32.847811,0.346841},
  {"space-location","razi-umbra-belt-inner","umbra",30.694865,0.426037},
  {"space-location","razi-umbra-belt-outer","umbra",29.792826,0.488728},
  {"planet","vesta","umbra",29.600886,0.597907},
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
