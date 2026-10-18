package.path = "./?.lua;./?/init.lua;" .. package.path
local M = require("temporary.factorio_2_1_22.fluid_boxes")
local function check(ok, message)
  if not ok then error(message, 2) end
end
local function run(raw, base)
  rawset(_G, "mods", {base = base or "2.1.22"})
  rawset(_G, "data", {raw = raw})
  return M.data_final_fixes()
end

local red = {
  maximum_temperature = 700,
  fluid_box = {filter = "steam", minimum_temperature = 165,
               maximum_temperature = 1000}
}
local boiler = {fluid_box = {minimum_temperature = 120}}
local turbine = {fluid_box = {filter = "steam", minimum_temperature = 800}}
local already_new = {
  minimum_input_temperature = 350,
  fluid_box = {minimum_temperature = 200}
}
local thruster = {
  fuel_fluid_box = {minimum_temperature = 100},
  oxidizer_fluid_box = {maximum_temperature = 200}
}
local assembler = {
  fluid_boxes = {{minimum_temperature = 110}},
  energy_source = {type = "fluid", maximum_temperature = 0,
    fluid_box = {filter = "steam", minimum_temperature = 300}}
}
local standard_pipe = {fluid_box = {minimum_temperature = 70}}
local raw = {
  fluid = {steam = {max_temperature = 500}},
  generator = {["red-steam-engine"] = red, ["older-turbine"] = turbine,
    ["already-updated"] = already_new},
  boiler = {["red-boiler"] = boiler},
  thruster = {["test-thruster"] = thruster},
  ["assembling-machine"] = {["test-assembler"] = assembler},
  pipe = {["test-pipe"] = standard_pipe},
}
check(run(raw) == 9, "Repair every obsolete fluid box once")
check(red.minimum_input_temperature == 165 and
  red.maximum_input_temperature == 500,
  "Restore red steam engine temperature limits and clamp to fluid maximum")
check(red.maximum_temperature == 700,
  "Generator maximum efficiency temperature must not be changed")
check(red.fluid_box.minimum_temperature == nil and
  red.fluid_box.maximum_temperature == nil,
  "Strip removed properties from the offending fluid box")
check(turbine.minimum_input_temperature == 500,
  "Legacy minimum temperatures must be clamped to the fluid max")
check(boiler.minimum_input_temperature == 120,
  "Boiler input temperature constraint must migrate")
check(already_new.minimum_input_temperature == 350,
  "Do not overwrite existing new API constraints")
check(thruster.minimum_fuel_temperature == 100 and
  thruster.maximum_oxidizer_temperature == 200,
  "Migrate fuel and oxidizer constraints independently")
check(assembler.energy_source.minimum_input_temperature == 300 and
  assembler.energy_source.maximum_temperature == nil,
  "Fluid energy source constraints and zero unlimited must migrate")
check(assembler.fluid_boxes[1].minimum_temperature == nil and
  standard_pipe.fluid_box.minimum_temperature == nil,
  "Remove invalid fields where no machine input counterpart exists")
check(run(raw) == 0, "Bridge should be idempotent")

local old = {generator = {red = {
  fluid_box = {minimum_temperature = 200}
}}}
check(run(old, "2.1.21") == 0 and
  old.generator.red.fluid_box.minimum_temperature == 200,
  "Do not touch old FluidBox fields on Factorio 2.1.21")
print("Factorio 2.1.22 FluidBox compatibility bridge passed")
