---@diagnostic disable: missing-fields
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(value, message)
  if not value then error(message, 2) end
end
local function has(list, name)
  for _, value in ipairs(list or {}) do
    if value == name then return true end
  end
  return false
end
local function fluid_boxes(inputs, outputs)
  local result = {}
  for _ = 1, inputs do result[#result + 1] = {production_type="input"} end
  for _ = 1, outputs do result[#result + 1] = {production_type="output"} end
  return result
end
local function create(k2)
  local base = {
    ["assembling-machine-3"]={
      crafting_categories={"crafting","advanced-crafting","crafting-with-fluid"},
      fluid_boxes=fluid_boxes(1,0)},
    ["chemical-plant"]={
      crafting_categories={"chemistry","chemistry-or-cryogenics"},
      fluid_boxes=fluid_boxes(2,2)},
    foundry={crafting_categories={"metallurgy","casting"},
      fluid_boxes=fluid_boxes(2,1)}
  }
  local upgrades = {
    ["kr-advanced-assembling-machine"]={
      crafting_categories={"crafting"},fluid_boxes=fluid_boxes(2,1)},
    ["kr-advanced-chemical-plant"]={
      crafting_categories={"chemistry","kr-advanced-chemistry"},
      fluid_boxes=fluid_boxes(3,3)},
    ["kr-advanced-furnace"]={
      crafting_categories={"metallurgy"},fluid_boxes=fluid_boxes(2,2)}
  }
  for name, prototype in pairs(upgrades) do base[name]=prototype end

  local technologies = {
    ["kr-advanced-furnace"]={prerequisites={"kr-advanced-tech-card"}},
    ["kr-geothermal"]={prerequisites={"kr-energy-control-unit"}},
    ["kr-advanced-chemical-plant"]={prerequisites={"kr-advanced-tech-card"}},
    ["kr-energy-storage"]={prerequisites={"kr-energy-control-unit"}},
    ["kr-quantum-computer"]={prerequisites={"kr-ai-core"}},
    ["kr-matter-tech-card"]={prerequisites={"cryogenic-plant"},
      research_trigger={type="craft-item",item="cryogenic-plant"}},
    ["kr-advanced-tech-card"]={prerequisites={}},
    ["kr-energy-control-unit"]={prerequisites={}},
    ["kr-ai-core"]={prerequisites={}},
    ["cryogenic-plant"]={prerequisites={}},
    ["planet-discovery-vulcanus"]={prerequisites={}},
    ["planet-discovery-gleba"]={prerequisites={}},
    ["planet-discovery-fulgora"]={prerequisites={}},
    ["planet-discovery-aquilo"]={prerequisites={}}
  }
  rawset(_G,"mods",k2 and {["Krastorio2-spaced-out"]="2.0.17"} or {})
  rawset(_G,"data",{raw={["assembling-machine"]=base,technology=technologies}})
  package.loaded["prototypes.compat.k2so_planet_machines"]=nil
  return base,technologies,require("prototypes.compat.k2so_planet_machines")
end

local all,technologies,mod=create(true)
mod.data_final_fixes()
check(has(all["kr-advanced-assembling-machine"].crafting_categories,"advanced-crafting"),
  "K2SO advanced assembler lost normal advanced crafting")
check(has(all["kr-advanced-assembling-machine"].crafting_categories,"crafting-with-fluid"),
  "K2SO advanced assembler lost normal fluid crafting")
check(has(all["kr-advanced-chemical-plant"].crafting_categories,"chemistry-or-cryogenics"),
  "K2SO advanced chemical plant cannot produce shared cryogenic chemistry")
check(not has(all["kr-advanced-chemical-plant"].crafting_categories,"casting"),
  "K2SO advanced chemical plant gained an unrelated specialist category")
check(not has(all["kr-advanced-furnace"].crafting_categories,"casting"),
  "K2SO advanced furnace bypassed a planet-specific recipe category")
check(has(technologies["kr-advanced-furnace"].prerequisites,"planet-discovery-vulcanus"),
  "K2SO advanced furnace was not tied to Vulcanus")
check(has(technologies["kr-geothermal"].prerequisites,"planet-discovery-vulcanus"),
  "K2SO geothermal was not tied to Vulcanus")
check(has(technologies["kr-advanced-chemical-plant"].prerequisites,"planet-discovery-gleba"),
  "K2SO advanced chemistry was not tied to Gleba")
check(has(technologies["kr-energy-storage"].prerequisites,"planet-discovery-fulgora"),
  "K2SO energy storage was not tied to Fulgora")
check(has(technologies["kr-quantum-computer"].prerequisites,"planet-discovery-aquilo"),
  "K2SO quantum computer was not tied to Aquilo")
check(has(technologies["kr-matter-tech-card"].prerequisites,"planet-discovery-aquilo"),
  "K2SO matter research was not tied to Aquilo")
check(has(technologies["kr-advanced-furnace"].prerequisites,"kr-advanced-tech-card"),
  "Native K2SO prerequisite was removed")
check(technologies["kr-matter-tech-card"].research_trigger.item=="cryogenic-plant",
  "Original K2SO matter research trigger was replaced")

local original=#all["kr-advanced-chemical-plant"].crafting_categories
local prereqs=#technologies["kr-advanced-chemical-plant"].prerequisites
mod.data_final_fixes()
check(#all["kr-advanced-chemical-plant"].crafting_categories==original
  and #technologies["kr-advanced-chemical-plant"].prerequisites==prereqs,
  "K2SO planetary upgrades duplicated links on a second pass")

-- Source planet mod did not expose the category. Do not invent it.
local unsupported,_,safety=create(true)
table.remove(unsupported["chemical-plant"].crafting_categories, 2)
safety.data_final_fixes()
check(not has(unsupported["kr-advanced-chemical-plant"].crafting_categories,
  "chemistry-or-cryogenics"),"Category added without the baseline machine")

-- Too few pipes for the native chemical plant: avoid offering incompatible
-- recipes just because K2SO calls the building an advanced machine.
local dry,_,dry_test=create(true)
dry["kr-advanced-chemical-plant"].fluid_boxes=fluid_boxes(1,1)
dry_test.data_final_fixes()
check(not has(dry["kr-advanced-chemical-plant"].crafting_categories,
  "chemistry-or-cryogenics"),"Category added without enough fluid interfaces")

-- Removing the anchor must not turn unrelated machinery into an all-purpose
-- upgrade, even if another mod copied the same prototype name.
local no_anchor,_,guard=create(true)
no_anchor["kr-advanced-chemical-plant"].crafting_categories={"kr-special"}
guard.data_final_fixes()
check(not has(no_anchor["kr-advanced-chemical-plant"].crafting_categories,
  "chemistry-or-cryogenics"),"Missing K2SO machine role was assumed")

-- Optional K2SO dependency absent: do nothing.
local absent,absent_tech,off=create(false)
off.data_final_fixes()
check(not has(absent["kr-advanced-chemical-plant"].crafting_categories,
  "chemistry-or-cryogenics"),"Non-K2SO modpack machine was modified")
check(not has(absent_tech["kr-advanced-furnace"].prerequisites,
  "planet-discovery-vulcanus"),"Non-K2SO research was modified")

-- A source-mod technology depending on its K2SO counterpart must not form
-- a cycle through our new discovery gate.
local _,cycles,cycle_mod=create(true)
cycles["planet-discovery-aquilo"].prerequisites={"kr-quantum-computer"}
cycle_mod.data_final_fixes()
check(not has(cycles["kr-quantum-computer"].prerequisites,
  "planet-discovery-aquilo"),"New K2SO prerequisite would form a research cycle")

local f=assert(io.open("data-final-fixes.lua","r"))
local source=f:read("*a")
f:close()
local last=assert(source:find(
  'require("prototypes.compat.k2so_planet_integration").data_final_fixes()',1,true))
local current=assert(source:find(
  'require("prototypes.compat.k2so_planet_machines").data_final_fixes()',1,true))
check(current>last,"K2SO machine parity must run after the planet material pass")
print("K2SO machine categories, planet tech origins, safeguards and cycles passed")
