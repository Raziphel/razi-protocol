---@diagnostic disable: missing-fields
package.path = "./?.lua;./?/init.lua;" .. package.path
local function check(value, message)
  if not value then error(message, 2) end
end
local function science(s) return {{s,1},{"calidus-tech-card",1}} end
local function contains(t, pack)
  for _, ingredient in ipairs(t.unit and t.unit.ingredients or {}) do
    if (ingredient.name or ingredient[1])==pack then return true end
  end
  return false
end
local function setup(enabled)
  local tech={
    ["vibrant-discovery"]={unit={ingredients=science("calidus-tech-card")}},
    ["vespera-discovery"]={prerequisites={"vibrant-discovery"},unit={
      ingredients=science("planet-crucible-science-pack")}},
    ["planet-discovery-aquilo"]={prerequisites={"vespera-discovery"},unit={
      ingredients=science("planet-crucible-science-pack")}},
    ["umbra-discovery"]={prerequisites={"vespera-discovery"},unit={
      ingredients=science("calidus-tech-card")}},
    ["planet-discovery-tenebris"]={prerequisites={"umbra-discovery"},unit={
      ingredients=science("calidus-tech-card")}},
    ["planet-discovery-crucible"]={prerequisites={"planet-discovery-tenebris"},
      unit={ingredients={{"planet-crucible-science-pack",1}}}},
    ["razi-umbra-belt-survey"]={prerequisites={"planet-discovery-crucible"},
      unit={ingredients=science("calidus-tech-card")}},
    ["planet-discovery-vesta"]={prerequisites={"razi-umbra-belt-survey"},
      unit={ingredients=science("gas-manipulation-science-pack")}},
    ["vesta-industrial-mastery"]={prerequisites={"planet-discovery-vesta"},
      unit={ingredients=science("gas-manipulation-science-pack")}},
    ["crucible-metallurgy"]={prerequisites={"planet-discovery-crucible"},
      unit={ingredients=science("planet-crucible-science-pack")}}
  }
  rawset(_G,"mods",enabled and {
    ["planet-crucible"]="1.1.27",["skewer_planet_vesta"]="2.1.27",
    ["Krastorio2-spaced-out"]="2.0.17"
  } or {["Krastorio2-spaced-out"]="2.0.17"})
  rawset(_G,"data",{raw={technology=tech,tool={
    ["calidus-tech-card"]={},["space-science-pack"]={},
    ["planet-crucible-science-pack"]={},
    ["gas-manipulation-science-pack"]={}
  },lab={standard={inputs={"calidus-tech-card"}}}}})
  package.loaded["prototypes.compat.outer_science_arrival_guard"]=nil
  return tech,require("prototypes.compat.outer_science_arrival_guard")
end
local t,guard=setup(true)
guard.data_final_fixes()
check(not contains(t["planet-discovery-aquilo"],"planet-crucible-science-pack"),
  "Aquilo would require unreached Crucible science")
check(not contains(t["vespera-discovery"],"planet-crucible-science-pack"),
  "Vespera would require unreached Crucible science")
check(not contains(t["planet-discovery-crucible"],"planet-crucible-science-pack"),
  "Crucible discovery self-requires Crucible science")
check(#t["planet-discovery-crucible"].unit.ingredients==1
  and contains(t["planet-discovery-crucible"],"calidus-tech-card"),
  "Removing the sole exclusive pack created an empty unit")
check(not contains(t["planet-discovery-vesta"],"gas-manipulation-science-pack"),
  "Vesta discovery self-requires its gas science")
check(contains(t["vesta-industrial-mastery"],"gas-manipulation-science-pack"),
  "Vesta's post-arrival gas research was weakened")
check(contains(t["crucible-metallurgy"],"planet-crucible-science-pack"),
  "Crucible's post-arrival metallurgy was weakened")
local size=#t["planet-discovery-crucible"].unit.ingredients
guard.data_final_fixes()
check(#t["planet-discovery-crucible"].unit.ingredients==size,
  "Arrival guard is not idempotent")
t["planet-discovery-aquilo"].unit.ingredients[#t["planet-discovery-aquilo"].unit.ingredients+1]=
  {"planet-crucible-science-pack",1}
t["planet-discovery-vesta"].unit.ingredients[#t["planet-discovery-vesta"].unit.ingredients+1]=
  {"gas-manipulation-science-pack",1}
guard.data_final_fixes()
check(not contains(t["planet-discovery-aquilo"],"planet-crucible-science-pack")
  and not contains(t["planet-discovery-vesta"],"gas-manipulation-science-pack"),
  "Late compatibility research reintroduced pre-arrival science")
local absent,off=setup(false)
off.data_final_fixes()
check(contains(absent["planet-discovery-crucible"],"planet-crucible-science-pack"),
  "Missing optional world still changed another mod's science")
local f=assert(io.open("data-final-fixes.lua","r"))
local src=f:read("*a")
f:close()
local final=assert(src:find(
  'require("prototypes.compat.outer_science_arrival_guard").data_final_fixes()',1,true))
local gate=assert(src:find(
  'require("prototypes.technology.seven_system_gates").data_final_fixes()',1,true))
check(final>gate,"Outer science compatibility should run after final discovery gates")
print("Late Crucible and Vesta science cannot block their own arrival")
