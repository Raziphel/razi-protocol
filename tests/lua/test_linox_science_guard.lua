---@diagnostic disable: missing-fields
package.path="./?.lua;./?/init.lua;"..package.path
local function check(value, message)
  if not value then error(message, 2) end
end
local function science(name)
  return {{name,1},{"calidus-tech-card",1}}
end
local function setup(linox)
  local tech={
    ["solaris-discovery"]={prerequisites={},unit={ingredients=science(
      "linox-item_linox-science-pack")}},
    ["vibrant-discovery"]={prerequisites={"solaris-discovery"},unit={
      ingredients=science("linox-item_linox-science-pack")}},
    ["vespera-discovery"]={prerequisites={"solaris-discovery"},unit={
      ingredients=science("linox-item_linox-science-pack")}},
    ["beetlejuice-discovery"]={prerequisites={
      "vibrant-discovery","vespera-discovery"},unit={ingredients=science(
        "linox-item_linox-science-pack")}},
    ["umbra-discovery"]={prerequisites={
      "vibrant-discovery","vespera-discovery"},unit={ingredients=science(
        "linox-item_linox-science-pack")}},
    ["planet-discovery-cubium"]={prerequisites={"beetlejuice-discovery"}},
    ["linox-technology_planet-discovery-linox"]={prerequisites={
      "planet-discovery-cubium"},unit={
        ingredients=science("linox-item_linox-science-pack")}},
    ["linox-technology_expanding-factory-5"]={prerequisites={
      "linox-technology_planet-discovery-linox"},unit={
        ingredients=science("linox-item_linox-science-pack")}},
    ["planet-discovery-frozeta"]={prerequisites={
      "planet-discovery-cubium"},unit={
        ingredients=science("linox-item_linox-science-pack")}}
  }
  rawset(_G,"mods",linox and {
    linox="1.8.9",["Krastorio2-spaced-out"]="2.0.17"
  } or {["Krastorio2-spaced-out"]="2.0.17"})
  rawset(_G,"data",{raw={
    technology=tech,
    tool={["linox-item_linox-science-pack"]={}}
  }})
  package.loaded["prototypes.compat.linox_science_guard"]=nil
  return tech,require("prototypes.compat.linox_science_guard")
end
local function contains(t)
  for _, ingredient in ipairs(t.unit.ingredients or {}) do
    if (ingredient.name or ingredient[1])=="linox-item_linox-science-pack" then
      return true
    end
  end
  return false
end
local tech,compat=setup(true)
compat.data_final_fixes()
for _, name in ipairs({
  "solaris-discovery","vibrant-discovery","vespera-discovery",
  "beetlejuice-discovery","umbra-discovery",
  "linox-technology_planet-discovery-linox"
}) do
  check(not contains(tech[name]),"Before-Linox research requires Linox science: "..name)
  check(#tech[name].unit.ingredients==1,
    "Razi removed unrelated pre-Linox science: "..name)
end
check(contains(tech["linox-technology_expanding-factory-5"]),
  "Native post-arrival Linox science must survive")
check(contains(tech["planet-discovery-frozeta"]),
  "Independent outer-frontier side research must not be stripped")
compat.data_final_fixes()
check(#tech["solaris-discovery"].unit.ingredients==1,
  "Second pass corrupted research ingredients")

local without,guard=setup(false)
guard.data_final_fixes()
check(contains(without["solaris-discovery"]),
  "Guard ran without Linox installed")

local f=assert(io.open("data-final-fixes.lua","r"))
local source=f:read("*a")
f:close()
local a=assert(source:find(
  'require("prototypes.technology.seven_system_gates").data_final_fixes()',1,true))
local b=assert(source:find(
  'require("prototypes.compat.linox_science_guard").data_final_fixes()',1,true))
check(b>a,"Linox safeguard ran before the final campaign gates")
print("Linox pre-arrival hard mode science safeguard passed")
