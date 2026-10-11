-- Final Razi starmap layout, after source and optional planet overrides.
-- Orientations are Factorio turns: north 0, east .25, south .5.
local M = {}
local anchors = {
  -- The campaign spine is a succession of three balanced two-star columns.
  -- Keep y around +/-65 to separate the planet rings, but retain the physical
  -- km-to-map-unit ratio checked by scripts/audit_route_distances.py.
  {"space-location","solaris","star",140,.173},
  {"space-location","nyxaris","star",140,.327},
  {"space-location","vibrant","star",251,.208},
  {"space-location","vespera","star",251,.292},
  {"space-location","beetlejuice","star",369,.222},
  {"space-location","umbra","star",369,.278},
  {"space-location","solar-system-edge","star",485,.25},
  {"space-location","sye-calidus","star",32,.25},
  -- West-facing transit portals prevent long passages through star sprites.
  {"space-location","sye-solaris","solaris",39,.75},
  {"space-location","sye-nyxaris","nyxaris",39,.75},
  {"space-location","sye-vibrant","vibrant",38,.75},
  {"space-location","sye-vespera","vespera",38,.75},
  {"space-location","sye-beetlejuice","beetlejuice",38,.75},
  {"space-location","sye-umbra","umbra",38,.75},
  -- Solaris: a southwest factory path and a short northern Vulcanus spur.
  {"planet","vulcanus","solaris",24,.84},
  {"planet","castra","solaris",24,.64},
  {"planet","arig","solaris",27,.56},
  {"planet","hyarion","solaris",32,.45},
  {"planet","tellus","solaris",27,.35},
  {"planet","corrundum","solaris",34,.25},
  -- Nyxaris: all four direct slipstream journeys skirt the western limb.
  {"planet","gleba","nyxaris",21,.84},
  {"planet","moshine","nyxaris",17,.64},
  {"space-location","apia-carnova-orbit","nyxaris",32,.91},
  {"planet","panglia","nyxaris",31,.58},
  -- Vibrant: travel along the bottom edge rather than through the star.
  {"planet","fulgora","vibrant",20,.87},
  {"planet","ribbonia","vibrant",28,.61},
  {"planet","paracelsin","vibrant",24,.40},
  {"planet","shchierbin","vibrant",32,.25},
  -- Vespera: Muria -> Aquilo -> belt -> Rubia -> Maraxsis follows an arc.
  {"planet","muria","vespera",24,.85},
  {"planet","aquilo","vespera",29,.03},
  {"space-location","razi-vespera-belt-inner","vespera",35,.15},
  {"space-location","razi-vespera-belt-outer","vespera",39,.18},
  {"planet","rubia","vespera",40,.25},
  {"planet","maraxsis","vespera",30,.37},
  -- Beetlejuice: keep all industrial transfers outside the stellar core.
  {"planet","cubium","beetlejuice",20,.68},
  {"planet","linox-planet_linox","beetlejuice",32,.59},
  {"space-location","secretas","beetlejuice",34,.50},
  -- Umbra: the Crucible/belt/Vesta traverse winds around the southern rim.
  {"planet","tenebris","umbra",24,.66},
  {"space-location","crucible-orbit","umbra",30,.55},
  {"space-location","razi-umbra-belt-inner","umbra",30,.49},
  {"space-location","razi-umbra-belt-outer","umbra",32,.43},
  {"planet","vesta","umbra",37,.37}
}
local function exists(kind, name)
  local bucket = data.raw[kind]
  return bucket and bucket[name]
end
function M.data_final_fixes()
  local updates = {}
  for _, item in ipairs(anchors) do
    local kind, name, parent, distance, angle =
      item[1], item[2], item[3], item[4], item[5]
    if exists(kind, name) and exists("space-location", parent) then
      updates[#updates+1] = {
        type=kind, name=name,
        orbit={parent={type="space-location",name=parent},
               distance=distance,orientation=angle}
      }
    end
  end
  if #updates>0 then PlanetsLib:update(updates) end
  -- Retain planet rings, hide giant star-centered and slipstream rings.
  for _, name in ipairs({
    "solaris","nyxaris","vibrant","vespera","beetlejuice","umbra",
    "solar-system-edge","sye-calidus","sye-solaris","sye-nyxaris",
    "sye-vibrant","sye-vespera","sye-beetlejuice","sye-umbra"
  }) do
    local location = exists("space-location",name)
    if location then location.draw_orbit=false end
  end
end
return M
