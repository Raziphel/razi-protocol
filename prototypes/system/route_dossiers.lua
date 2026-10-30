-- RAZI narrative freight notes for verified named corridors only.
-- Entries carry no routing authority: source connections, research and
-- third-party custom tooltips remain untouched. Absent routes add nothing.
local notes = {
  {"nauvis","sye-calidus","home-departure"},
  {"muluna","sye-calidus","lunar-proving"},
  {"sye-calidus","sye-solaris","solaris-first"},
  {"sye-calidus","sye-nyxaris","nyxaris-first"},
  {"sye-solaris","sye-vibrant","vibrant-link"},
  {"sye-nyxaris","sye-vespera","vespera-link"},
  {"sye-vespera","sye-umbra","umbra-link"},
  {"sye-solaris","sye-nyxaris","frontier-bridge"},
  {"sye-solaris","calidus-bellicos-stargate-calidus","aegis-solaris"},
  {"sye-nyxaris","calidus-bellicos-stargate-calidus","aegis-nyxaris"},
  {"sye-beetlejuice","sye-umbra","outer-bridge"},
  {"sye-vibrant","asteroid-belt-outer-edge","vibrant-outer"},
  {"ribbonia","asteroid-belt-inner-edge","vibrant-inner"},
  {"asteroid-belt-inner-edge","asteroid-belt-outer-edge","vibrant-crossing"},
  {"asteroid-belt-outer-edge","sye-beetlejuice","beetlejuice-outbound"},
  {"asteroid-belt-outer-edge","paracelsin","paracelsin-reach"},
  {"sye-solaris","vulcanus","furnace-approach"},
  {"vulcanus","castra","foundry-defense"},
  {"vulcanus","arig","furnace-desert"},
  {"castra","arig","battle-desert"},
  {"arig","hyarion","glass-crystal"},
  {"hyarion","tellus","crystal-tellus"},
  {"tellus","corrundum","tellus-sulfur"},
  {"hyarion","corrundum","crystal-sulfur"},
  {"corrundum","igrys","solaris-loop"},
  {"gleba","moshine","bio-data"},
  {"moshine","apia-carnova-orbit","data-twins"},
  {"gleba","apia-carnova-orbit","bio-twins"},
  {"moshine","panglia","data-panglia"},
  {"apia-carnova-orbit","panglia","twins-panglia"},
  {"sye-nyxaris","gleba","gleba-approach"},
  {"sye-nyxaris","moshine","moshine-approach"},
  {"fulgora","ribbonia","ringworld-link"},
  {"sye-vespera","muria","muria-approach"},
  {"muria","rubia","muria-rubia"},
  {"rubia","maraxsis","rubia-ocean"},
  {"rubia","aquilo","rubia-aquilo"},
  {"sye-beetlejuice","cubium","cubium-approach"},
  {"cubium","linox-planet_linox","linox-furnace"},
  {"cubium","secretas","secretas-branch"},
  {"secretas","frozeta","frozeta-recovery"},
  {"linox-planet_linox","secretas","beetlejuice-shuttle"},
  {"sye-umbra","razi-umbra-belt-outer","umbra-staging"},
  {"razi-umbra-belt-inner","razi-umbra-belt-outer","umbra-crossing"},
  {"razi-umbra-belt-inner","tenebris","umbra-inner"},
  {"tenebris","crucible-orbit","umbra-pressure"},
  {"razi-umbra-belt-outer","vesta","vesta-exterior"},
  {"secretas","solar-system-edge","deep-from-secretas"},
  {"vesta","solar-system-edge","deep-from-vesta"},
  -- Verified Deep Space waypoints; notes attach only if a source route exists.
  {"solar-system-edge","nexus","deep-nexus-survey"},
  {"solar-system-edge","black-hole-approach","deep-black-hole-approach"},
  {"black-hole-approach","black-hole","deep-black-hole-final"},
  {"nexus","oort-cloud","deep-oort-transition"},
  {"oort-cloud","sol","deep-sol-approach"},
  {"solar-system-edge","shattered-planet","deep-shattered-approach"},
  {"shattered-planet","skewer_shattered_planet","deep-shattered-shuttle"},
  {"skewer_shattered_planet","skewer_lost_beyond","deep-lost-beyond"},
  {"athos","muria","athos-spur"},
  {"obsidiax","vesta","obsidiax-spur"},
  {"rabbasca","gleba","rabbasca-moon"},
  {"velora","gleba","velora-moon"},
  {"shchierbin","paracelsin","shchierbin-spur"},
  {"alchemy-planet","ribbonia","alchemy-spur"},
  {"arcanyx","tenebris","arcanyx-spur"},
  {"carna","crucible-orbit","carna-spur"},
  {"bm-balack","aquilo","balack-spur"},
  {"ferrum","sye-beetlejuice","ferrum-spur"},
  {"foliax","sye-nyxaris","foliax-spur"},
  {"panglia","pelagos","pelagos-spur"},
  {"moshine","pelagos","pelagos-data"},
  {"sye-nyxaris","dea-dia-system-edge","dea-dia-spur"},
}
local lookup={}
local function key(a,b)
  if type(a)~="string" or type(b)~="string" then return nil end
  if a>b then a,b=b,a end
  return a.."|"..b
end
for _,entry in ipairs(notes) do
  lookup[key(entry[1],entry[2])]=entry[3]
end
local M={}
function M.note_for(route)
  return route and lookup[key(route.from,route.to)] or nil
end
return M
