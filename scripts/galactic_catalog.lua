-- Razi's authored seven-system classification. Other mods' planets are
-- never removed: an unknown destination appears under "Unassigned".
local M={}
M.groups={"calidus","solaris","nyxaris","vibrant","vespera","beetlejuice","umbra","deep-space","unassigned"}
local members={}
local groups={
  calidus={"nauvis","muluna","eneas","sye-calidus"},
  solaris={"sye-solaris","vulcanus","castra","arig","hyarion","tellus","corrundum",
           "igrys","igrys-orbit","athos","PlanetAthos","ferrum","planet-ferrum"},
  nyxaris={"sye-nyxaris","gleba","rabbasca","moshine","apia","carnova",
           "apia-carnova-orbit","panglia","pelagos","foliax","dea-dia-system-edge",
           "razi-dea-dia-slip-stream","lemures","prosephina"},
  vibrant={"sye-vibrant","fulgora","cerys","ribbonia","shchierbin",
           "paracelsin","asteroid-belt-inner-edge","asteroid-belt-outer-edge"},
  vespera={"sye-vespera","muria","aquilo","rubia","maraxsis",
           "razi-vespera-belt-inner","razi-vespera-belt-outer","carna"},
  beetlejuice={"sye-beetlejuice","cubium","linox-planet_linox","secretas",
               "frozeta","obsidiax"},
  umbra={"sye-umbra","tenebris","crucible","crucible-orbit","vesta",
         "razi-umbra-belt-inner","razi-umbra-belt-outer"},
  ["deep-space"]={"solar-system-edge","razi-deep-space-edge","shattered-planet",
                  "nexus","black-hole","oort-cloud"}
}
for group,names in pairs(groups) do
  for _,name in ipairs(names) do members[name]=group end
end
function M.system(name)
  if type(name)~="string" then return "unassigned" end
  return members[name] or "unassigned"
end
function M.position(group)
  for index,name in ipairs(M.groups) do if name==group then return index end end
  return #M.groups
end
return M
