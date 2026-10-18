package.path = "./?.lua;./?/init.lua;" .. package.path
local fluid=require("temporary.factorio_2_1_22.fluid_boxes")
local function check(ok,msg) if not ok then error(msg,2) end end
local function fixture(minimum)
  local roots={fluid_box={filter="panglia_branbalite_slurry"},
    minimum_input_temperature=minimum, maximum_temperature=165,
    fluid_usage_per_tick=0.1, effectivity=40000}
  rawset(_G,"mods",{base="2.1.22",panglia_planet="0.7.2"})
  rawset(_G,"data",{raw={
    fluid={panglia_branbalite_slurry={default_temperature=165,
      max_temperature=250}},
    generator={panglia_energy_roots=roots}
  }})
  return roots
end
local roots=fixture(0)
check(fluid.data_final_fixes()==1,"Remove invalid Panglia 0 C machine minimum")
check(roots.minimum_input_temperature==nil,"Unrestricted minimum is nil")
check(roots.maximum_temperature==165 and roots.fluid_usage_per_tick==0.1
  and roots.effectivity==40000,"Preserve Panglia energy production")
check(fluid.data_final_fixes()==0,"Idempotent on repeat load")
local limited=fixture(190)
check(fluid.data_final_fixes()==0 and
  limited.minimum_input_temperature==190,"Keep meaningful restrictions")
local at_default=fixture(165)
check(fluid.data_final_fixes()==0 and
  at_default.minimum_input_temperature==165,"Keep valid default constraint")
local older=fixture(0)
rawset(_G,"mods",{base="2.1.21"})
check(fluid.data_final_fixes()==0 and
  older.minimum_input_temperature==0,"Do not alter pre-2.1.22 data")
print("Panglia temperature migration passed")
