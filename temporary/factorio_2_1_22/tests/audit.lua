package.path = "./?.lua;./?/init.lua;" .. package.path
local audit=require("temporary.factorio_2_1_22.audit")
local function check(ok,msg) if not ok then error(msg,2) end end
rawset(_G,"data",{raw={
  ["tile-effect"]={unknown={water={textures={{filename="unknown.png"}}}},
    valid={water={image_textures={{filename="good.png"}}}}},
  generator={legacy={fluid_box={minimum_temperature=0}},
    modern={fluid_box={filter="steam"}}},
  ["assembling-machine"]={old={fluid_boxes={{maximum_temperature=500}}}},
  furnace={burner={energy_source={type="fluid",
    fluid_box={minimum_temperature=10}}}}
}})
check(audit.scan()==4,"Audit detects tile, direct and burner fluid box formats")
check(data.raw["tile-effect"].unknown.water.textures~=nil,
  "Audit must never mutate unrecognized prototypes")
check(data.raw.generator.legacy.fluid_box.minimum_temperature==0,
  "Audit should not change legacy inputs")
check(data.raw.furnace.burner.energy_source.fluid_box.minimum_temperature==10,
  "Audit should not mutate energy-source prototype fields")
print("Compatibility audit passed")
