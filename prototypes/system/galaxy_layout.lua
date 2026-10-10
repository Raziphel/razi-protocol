-- Final Razi starmap layout, after source and optional planet overrides.
-- Orientations are Factorio turns: north 0, east .25, south .5.
local M = {}
local anchors = {
  {"space-location","solaris","star",124,.182},
  {"space-location","nyxaris","star",124,.318},
  {"space-location","vibrant","star",242,.216},
  {"space-location","vespera","star",242,.284},
  {"space-location","beetlejuice","star",363,.224},
  {"space-location","umbra","star",363,.276},
  {"space-location","solar-system-edge","star",485,.25},
  {"space-location","sye-calidus","star",32,.25},
  {"space-location","sye-solaris","solaris",39,.76},
  {"space-location","sye-nyxaris","nyxaris",39,.74},
  {"space-location","sye-vibrant","vibrant",38,.76},
  {"space-location","sye-vespera","vespera",38,.74},
  {"space-location","sye-beetlejuice","beetlejuice",38,.76},
  {"space-location","sye-umbra","umbra",38,.74},
  {"planet","vulcanus","solaris",20,.02},
  {"planet","castra","solaris",27,.16},
  {"planet","arig","solaris",19,.37},
  {"planet","hyarion","solaris",32,.43},
  {"planet","tellus","solaris",24,.59},
  {"planet","corrundum","solaris",32,.67},
  {"planet","gleba","nyxaris",18,.02},
  {"planet","moshine","nyxaris",15,.21},
  {"space-location","apia-carnova-orbit","nyxaris",26,.38},
  {"planet","panglia","nyxaris",31,.59},
  {"planet","fulgora","vibrant",18,.04},
  {"planet","ribbonia","vibrant",30,.29},
  {"planet","paracelsin","vibrant",21,.51},
  {"planet","shchierbin","vibrant",32,.67},
  {"planet","muria","vespera",17,.06},
  {"planet","aquilo","vespera",28,.22},
  {"planet","rubia","vespera",32,.49},
  {"planet","maraxsis","vespera",28,.65},
  {"planet","cubium","beetlejuice",22,.09},
  {"planet","linox-planet_linox","beetlejuice",33,.29},
  {"space-location","secretas","beetlejuice",26,.50},
  {"planet","tenebris","umbra",17,.09},
  {"space-location","crucible-orbit","umbra",24,.27},
  {"planet","vesta","umbra",32,.60}
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
