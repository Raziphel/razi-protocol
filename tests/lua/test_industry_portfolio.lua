-- Balanced and Deep share curated freight instead of recycled
-- science card prerequisites or dozens of overlapping optional recipes.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end
local p=require("prototypes.compat.industry_portfolio")
local count=0
for name,enabled in pairs(p.retained) do
  check(enabled==true,"Portfolio must use explicit enabled entries")
  check(name:sub(1,5)=="razi-","No source-mod recipe can be included")
  check(p.profile(name),"Every retained recipe needs an industrial profile: "..name)
  count=count+1
end
check(count==11,"Exactly 11 curated K2SO/modded recipes expected")
-- Redundant, late or low-value exchanges stay retired.
for _,name in ipairs({
  "razi-ferrum-linox-optical-magnets",
  "razi-balack-rubia-chitosan-shielding",
  "razi-deep-ferrum-galvanic-magnets",
  "razi-network-galvanic-ferrum-magnets",
  "razi-cubium-precious-metal-alloying",
  "razi-network-precision-chitosan",
  "razi-network-golden-cubium-alloys",
  "razi-linox-rare-earth-exchange",
  "razi-cryo-energy-control",
  "razi-first-frontier-relay-components",
  "razi-modded-paracelsin-optical-coils",
  "razi-network-frame-aquilo-controllers"
}) do
  check(not p.keep(name),"Redundant/late exchange must stay retired: "..name)
end
for _,name in ipairs({
  "razi-bio-rare-metal-casting",
  "razi-electrobiological-components",
  "razi-gleba-tenebris-biopolymer",
  "razi-modded-moshine-zinc-silicon",
  "razi-modded-vesta-rare-earth-supermagnets",
  "razi-frontier-castra-composite-rounds",
  "razi-network-matrix-cryo-controllers",
  "razi-network-lattice-vesta-magnets",
  "razi-network-bond-paracelsin-coils",
  "razi-network-bond-linox-refining",
  "razi-network-frame-vesta-foundations"
}) do
  check(p.keep(name),"Important independent freight route retired: "..name)
end
check(p.profile("razi-modded-moshine-zinc-silicon").conserve=="kr-silicon",
  "Moshine's native silicon is kr-silicon in the K2SO pack")
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
print("Curated industry: eleven optional manufacturing alternatives, native research and real freight")
