-- Planet groups used by the Atlas and other UI.
-- Unknown destinations go into Unassigned rather than disappearing.
local M={}
M.groups={"calidus","solaris","nyxaris","vibrant","vespera","beetlejuice","umbra","deep-space","unassigned"}
local members={}
local groups={
  calidus={"nauvis","muluna","sye-calidus",
           "razi-calidus-drift"},
  solaris={"sye-solaris","vulcanus","castra","arig","hyarion","tellus","corrundum",
           "igrys","igrys-orbit","halo-solar-orbit","halo-solar-station"},
  nyxaris={"sye-nyxaris","gleba","rabbasca","moshine","panglia","apia","carnova",
           "apia-carnova-orbit","pelagos","foliax","dea-dia-system-edge",
           "razi-dea-dia-slip-stream","lemures","prosephina","velora"},
  vibrant={"sye-vibrant","fulgora","cerys","ribbonia",
           "paracelsin","ferrum","planet-ferrum","khemia",
           "asteroid-belt-inner-edge","asteroid-belt-outer-edge"},
  vespera={"sye-vespera","muria","aquilo","rubia","maraxsis",
           "razi-vespera-belt-inner","razi-vespera-belt-outer","obsidiax",
           "bm-balack"},
  beetlejuice={"sye-beetlejuice","cubium","linox-planet_linox","secretas",
               "frozeta"},
  umbra={"sye-umbra","tenebris","crucible","crucible-orbit","vesta",
         "razi-umbra-belt-inner","razi-umbra-belt-outer",
         "carna","arcanyx"},
  ["deep-space"]={"solar-system-edge","razi-deep-space-edge","shattered-planet",
                  "nexus","black-hole","oort-cloud"}
}
for group,names in pairs(groups) do
  for _,name in ipairs(names) do members[name]=group end
end
-- Discover source-owned solar location identifiers from the live SLP
-- technologies rather than hardcoding names that can vary by port.
local dyson_worlds
local function source_dyson_locations()
 if dyson_worlds~=nil then return dyson_worlds end
 dyson_worlds={}
 local available=(prototypes and prototypes.technology)
   or (game and game.technology_prototypes)
 if available then
   for _,id in ipairs({"planet-discovery-sunorbit","slp-solar-system-sun2"}) do
     local tech=available[id]
     for _,effect in pairs(tech and tech.effects or {}) do
       if effect.type=="unlock-space-location" and effect.space_location then
         dyson_worlds[effect.space_location]=true
       end
     end
   end
 end
 return dyson_worlds
end

function M.system(name)
  if type(name)~="string" then return "unassigned" end
  if source_dyson_locations()[name] then return "calidus" end
  return members[name] or "unassigned"
end
function M.position(group)
  for index,name in ipairs(M.groups) do if name==group then return index end end
  return #M.groups
end
return M
