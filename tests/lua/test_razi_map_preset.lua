-- RP3 map-generation profile selection and default-flag legality.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(value,msg) if not value then error(msg,2) end end
local function mock(choice,select)
 rawset(_G,"settings",{startup={
  ["razi-difficulty-preset"]={value=choice},
  ["razi-default-new-game-map"]={value=select}
 }})
 rawset(_G,"data",{raw={
  ["map-gen-presets"]={default={
    default={default=true,order="a"},
    ["death-world"]={order="d"}
  }},
  ["map-settings"]={["map-settings"]={
    enemy_evolution={time_factor=.000004,destroy_factor=.002,
      pollution_factor=.0000009},
    enemy_expansion={enabled=true,min_expansion_cooldown=14400,
      max_expansion_cooldown=216000}
  }},
  planet={nauvis={map_gen_settings={autoplace_controls={
    ["enemy-base"]={frequency=1,size=1,richness=1},
    ["iron-ore"]={frequency=1,size=1,richness=1}
  }}}},
  ["autoplace-control"]={
   ["enemy-base"]={},["iron-ore"]={}
  }
 }})
 package.loaded["prototypes.system.razi_map_preset"]=nil
 return require("prototypes.system.razi_map_preset")
end
for _,entry in ipairs({
 {"easy",.48,.0000014,1.45},
 {"normal",.85,.000004,1.20},
 {"hard",1.35,.000009,.90},
 {"nightmare",1.75,.000015,.80}
}) do
 local mode,enemy,time,ore=entry[1],entry[2],entry[3],entry[4]
 local mod=mock(mode,true)
 check(mod.data_final_fixes(),mode.." profiles failed")
 local group=data.raw["map-gen-presets"].default
 check(group["razi-protocol"].default==true
   and group["razi-protocol"].order,
   "Razi marker must auto-select the new-game default")
 check(group["razi-protocol"].basic_settings==nil
   and group["razi-protocol"].advanced_settings==nil,
   "A 2.1 default=true preset cannot contain gameplay settings")
 check(not group.default.default and group["death-world"],
   "Other vanilla map profiles must stay available")
 local selected=group["razi-protocol-"..mode]
 check(selected.basic_settings.autoplace_controls["enemy-base"].frequency==enemy,
   "Explicit "..mode.." enemy pressure is wrong")
 check(data.raw.planet.nauvis.map_gen_settings
     .autoplace_controls["enemy-base"].frequency==enemy,
   "Automatically selected "..mode.." defaults didn't follow startup")
 check(data.raw["map-settings"]["map-settings"]
     .enemy_evolution.time_factor==time,
   "Auto-selected "..mode.." evolution defaults are wrong")
 check(group["razi-protocol-easy"]
   and group["razi-protocol-normal"]
   and group["razi-protocol-hard"]
   and group["razi-protocol-nightmare"]
   and group["razi-protocol-custom"],
   "Missing a requested five-way Razi map selection")
 check(group["razi-protocol-normal"].basic_settings
     .autoplace_controls["iron-ore"].richness==1.20,
   "Curated ore baseline changed unexpectedly")
 check(group["razi-protocol-"..mode].basic_settings
     .autoplace_controls["iron-ore"].richness==ore,
   "Difficulty resources do not match selected profile")
end
local mod=mock("hard",false)
mod.data_final_fixes()
check(data.raw["map-gen-presets"].default.default.default,
  "Disabling Razi default selection must retain native default")
check(data.raw.planet.nauvis.map_gen_settings.autoplace_controls
  ["enemy-base"].frequency==1,
  "Disabled Razi default must not rewrite Nauvis's base mapgen")
local custom=mock("custom",true)
custom.data_final_fixes()
check(data.raw.planet.nauvis.map_gen_settings
 .autoplace_controls["enemy-base"].frequency==.85,
 "Custom without a Razi profile uses safe Normal worldgen defaults")
print("RP3 default marker, all four difficulty profiles, Custom, safety checks passed")
