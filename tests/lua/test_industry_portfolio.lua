-- Balanced and Deep share curated freight instead of recycled
-- science card prerequisites or 58 overlapping optional recipes.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end
local p=require("prototypes.compat.industry_portfolio")
local count=0
for name,enabled in pairs(p.retained) do
  check(enabled==true,"Portfolio must use explicit enabled entries")
  check(name:sub(1,5)=="razi-","No source-mod recipe can be included")
  count=count+1
end
check(count==15,"Exactly 15 curated K2SO/modded recipes expected")
-- Five specialist FluxWorks exchanges bring the total to twenty.
for _,name in ipairs({
  "razi-ferrum-linox-optical-magnets",
  "razi-balack-rubia-chitosan-shielding",
  "razi-deep-ferrum-galvanic-magnets",
  "razi-network-galvanic-ferrum-magnets",
  "razi-cubium-precious-metal-alloying",
  "razi-network-precision-chitosan",
  "razi-network-golden-cubium-alloys",
  "razi-network-bond-linox-refining"
}) do
  check(not p.keep(name),"Redundant/late exchange must stay retired: "..name)
end
for _,name in ipairs({
  "razi-bio-rare-metal-casting",
  "razi-modded-paracelsin-optical-coils",
  "razi-network-matrix-cryo-controllers",
  "razi-network-bond-paracelsin-coils",
  "razi-network-lattice-vesta-magnets",
  "razi-network-frame-aquilo-controllers",
  "razi-frontier-castra-composite-rounds"
}) do
  check(p.keep(name),"Important independent freight route retired: "..name)
end
for _,old in ipairs({
  {"calidus-tech-card"},
  {"solaris-tech-card","nyxaris-tech-card"},
  {"vibrant-tech-card","vespera-tech-card"},
  {"beetlejuice-tech-card","umbra-tech-card"}
}) do
  local new=p.science({science=old})
  check(#new==2,"Only two ordinary research packs should be used")
  for _,pack in ipairs(new) do
    check(not pack:find("tech%-card"),"Previous-system cards cannot be a freight unlock cost")
    check(pack:find("%-science%-pack$")~=nil,"Use native research science")
  end
end
print("Curated industry: twenty optional recipes, native research and real freight")
