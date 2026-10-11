-- Final Razi starmap layout, after source and optional planet overrides.
-- Orientations are Factorio turns: north 0, east .25, south .5.
local M = {}
local anchors = {
  -- Compact twin-lane constellation: star origins sit 80 map units apart,
  -- with two alternating rows rather than kilometre-proportional spacing.
  -- Gameplay travel distances stay in route_reconcile.lua, not orbit.distance.
  {"space-location","solaris","star",99,.1805},
  {"space-location","nyxaris","star",99,.3195},
  {"space-location","vibrant","star",175,.21145},
  {"space-location","vespera","star",175,.28855},
  {"space-location","beetlejuice","star",254,.2235},
  {"space-location","umbra","star",254,.2765},
  {"space-location","solar-system-edge","star",355,.25},
  {"space-location","sye-calidus","star",27,.25},
  -- Northwest departure portals form two nearly straight travel lanes.
  {"space-location","sye-solaris","solaris",33,.835},
  {"space-location","sye-nyxaris","nyxaris",33,.835},
  {"space-location","sye-vibrant","vibrant",33,.835},
  {"space-location","sye-vespera","vespera",33,.835},
  {"space-location","sye-beetlejuice","beetlejuice",33,.835},
  {"space-location","sye-umbra","umbra",33,.835},
  -- Local progression traces a short crescent around each star. Replacing
  -- star-crossing chords makes the individual systems feel like real clusters.
  {"planet","vulcanus","solaris",20,.84},
  {"planet","castra","solaris",26,.61},
  {"planet","arig","solaris",24,.455},
  {"planet","hyarion","solaris",34,.52},
  {"planet","tellus","solaris",31,.37},
  {"planet","corrundum","solaris",27,.23},
  {"planet","gleba","nyxaris",20,.84},
  {"planet","moshine","nyxaris",26,.98},
  {"space-location","apia-carnova-orbit","nyxaris",30,.08},
  {"planet","panglia","nyxaris",27,.68},
  {"planet","fulgora","vibrant",20,.84},
  {"planet","ribbonia","vibrant",25,.62},
  {"planet","paracelsin","vibrant",27,.44},
  {"planet","shchierbin","vibrant",28,.30},
  {"planet","muria","vespera",21,.84},
  {"planet","aquilo","vespera",26,.68},
  {"space-location","razi-vespera-belt-inner","vespera",31,.565},
  {"space-location","razi-vespera-belt-outer","vespera",32,.495},
  {"planet","rubia","vespera",32,.40},
  {"planet","maraxsis","vespera",32,.285},
  {"planet","cubium","beetlejuice",21,.84},
  {"planet","linox-planet_linox","beetlejuice",30,.69},
  {"space-location","secretas","beetlejuice",31,.56},
  {"planet","tenebris","umbra",22,.84},
  {"space-location","crucible-orbit","umbra",22,.61},
  {"space-location","razi-umbra-belt-inner","umbra",28,.48},
  {"space-location","razi-umbra-belt-outer","umbra",30,.42},
  {"planet","vesta","umbra",30,.31}
}
-- Only suppress orbital rings centered on Razi's adopted system stars.
-- Native planet-to-moon orbits and source-owned special subgraphs remain.
local system_stars = {
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
  -- Do not render many concentric planet rings in the full galaxy view.
  -- The route arcs provide the local structure without visual clutter.
  for _, bucket_name in ipairs({"planet", "space-location"}) do
    for _, location in pairs(data.raw[bucket_name] or {}) do
      local orbit = location.orbit
      local parent = orbit and orbit.parent
      if parent and parent.type == "space-location"
        and system_stars[parent.name] then
        location.draw_orbit = false
      end
    end
  end
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
