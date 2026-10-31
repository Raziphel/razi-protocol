-- Preserve the original Razi Protocol contract: native planetary science
-- within the current chapter, one compressed card per completed system.
-- Pure data-stage fixture; never needs Factorio to execute.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end
local function contains(list,name)
  for _,part in ipairs(list or {}) do
    if (part.name or part[1])==name then return true end
  end
  return false
end
local function nitems(list)
  local n=0
  for _ in ipairs(list or {}) do n=n+1 end
  return n
end
local card_names={
  "calidus-tech-card","solaris-tech-card","nyxaris-tech-card",
  "vibrant-tech-card","vespera-tech-card","beetlejuice-tech-card",
  "umbra-tech-card"
}
local tools={}
for _,card in ipairs(card_names) do tools[card]={} end
for _,native in ipairs({
  "automation-science-pack","logistic-science-pack","military-science-pack",
  "chemical-science-pack","production-science-pack","utility-science-pack",
  "space-science-pack","metallurgic-science-pack","electromagnetic-science-pack",
  "agricultural-science-pack","tungsten-science-pack",
  "muriatic-science-pack","hydraulic-science-pack","golden-science-pack"
}) do tools[native]={} end
local technologies={}
for _,name in ipairs({
  "planet-discovery-muluna","planet-discovery-castra",
  "linox-technology_planet-discovery-linox",
  "muriatic-science-pack","promethium-science-pack",
  "promethium-882-research","black-hole-discovery",
  "planet-discovery-nexus","antimatter-science-pack"
}) do technologies[name]={unit={ingredients={}}} end
data={raw={tool=tools,technology=technologies,lab={}}}
mods={}
function science_pack_exists(name) return tools[name]~=nil end
function add_unique_science_pack_if_exists(ingredients,name)
  if science_pack_exists(name) and not contains(ingredients,name) then
    ingredients[#ingredients+1]={name,1}
  end
end
function add_existing_science_packs(ingredients,names)
  for _,name in ipairs(names) do
    add_unique_science_pack_if_exists(ingredients,name)
  end
end
function set_technology_unit_ingredients_if_exists(name,ingredients)
  if technologies[name] then technologies[name].unit.ingredients=ingredients end
end
function set_prerequisites_if_exists(name,prerequisites)
  if technologies[name] then technologies[name].prerequisites=prerequisites end
end
function technology_exists(name) return technologies[name]~=nil end
function add_existing_prerequisites() end
function add_first_existing_prerequisite() end
function set_first_existing_prerequisite() end
function remove_prerequisites_if_exists() end
function science_pack_is_lab_protected() return false end
dofile("prototypes/technology/progression.lua")
local function research(name)
  return assert(technologies[name],"Missing fixture technology: "..name).unit.ingredients
end
-- A new Calidus run must be able to research its first moon before
-- reaching any other Razi star system. Source science from the first
-- frontier may never be needed for this bootstrap discovery.
local muluna=research("planet-discovery-muluna")
check(nitems(muluna)==7,"Muluna must use the seven pre-frontier sciences")
for _,pack in ipairs({
  "automation-science-pack","logistic-science-pack","military-science-pack",
  "chemical-science-pack","production-science-pack",
  "utility-science-pack","space-science-pack"
}) do
  check(contains(muluna,pack),"Muluna missing native bootstrap "..pack)
end
for _,pack in ipairs({
  "metallurgic-science-pack","electromagnetic-science-pack",
  "agricultural-science-pack","tungsten-science-pack",
  "calidus-tech-card"
}) do
  check(not contains(muluna,pack),
    "Calidus bootstrap depends on unavailable science: "..pack)
end
-- Original intent: exploring Solaris consumes Calidus, not other future cards.
check(nitems(research("planet-discovery-castra"))==1
  and contains(research("planet-discovery-castra"),"calidus-tech-card"),
  "First-frontier planet requires later-system research")
-- Reaching Linox is late outer progression, requiring both completed
-- middle systems, but neither outer card that it helps manufacture.
local linox=research("linox-technology_planet-discovery-linox")
check(nitems(linox)==5,"Linox should depend on exactly five earlier cards")
for _,name in ipairs(card_names) do
  if name~="beetlejuice-tech-card" and name~="umbra-tech-card" then
    check(contains(linox,name),"Linox missing prior chapter "..name)
  else
    check(not contains(linox,name),"Linox has its own future system card")
  end
end
-- Muria's science must not require a Vibrant or Vespera card, otherwise
-- the two independent middle-system entrances are indirectly coupled.
local muriatic=research("muriatic-science-pack")
check(nitems(muriatic)==3 and
  contains(muriatic,"calidus-tech-card") and
  contains(muriatic,"solaris-tech-card") and
  contains(muriatic,"nyxaris-tech-card"),
  "Vespera's first native science depends on its own/parallel system")
-- Late research must use ONE card for each completed region, not a wall
-- of earlier planet science packs, regardless of the auto-card option.
for _,technology in ipairs({
  "promethium-science-pack","promethium-882-research",
  "planet-discovery-nexus","black-hole-discovery"
}) do
  local packs=research(technology)
  check(nitems(packs)==7,technology.." must require seven regional cards")
  for _,name in ipairs(card_names) do
    check(contains(packs,name),technology.." omitted "..name)
  end
  for _,part in ipairs(packs) do
    check((part[1] or part.name):find("%-tech%-card$"),
      technology.." leaks a native science pack past its chapter")
  end
end
print("Original Razi science philosophy: seven regional cards, independent chapters, native arrival research passed")
