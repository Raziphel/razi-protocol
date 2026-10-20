-- The complete modpack exposes far more resources than seven vanilla ores.
-- Verify auto-selection, all planet controls, no alien ore leakage, science,
-- enemy evolution and expansion, pollution, asteroids, and repeat safety.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end
local function planet(fields)
 return {map_gen_settings={autoplace_controls=fields}}
end
local controls={
 ["iron-ore"]={category="resource",richness=true},
 ["ionite-ore"]={category="resource",richness=true},
 ["ferric-scrap"]={category="resource",richness=true},
 ["crude-oil"]={category="resource",richness=true},
 ["meteorite-chunk"]={category="resource",richness=true},
 ["underground-salt"]={category="resource",richness=true},
 ["biter-base"]={category="enemy",richness=false},
 ["enemy-base"]={category="enemy",richness=false},
 ["trees"]={category="terrain",richness=false},
 ["water"]={category="terrain",richness=false},
 ["cliff"]={category="cliff",richness=false},
 ["planet-temperature"]={category="terrain",richness=false}
}
local function make(mode,enabled)
 rawset(_G,"settings",{startup={
   ["razi-difficulty-preset"]={value=mode},
   ["razi-default-new-game-map"]={value=enabled}}})
 rawset(_G,"data",{raw={
  ["map-gen-presets"]={default={
    default={default=true,order="a"},
    ["death-world"]={order="d"}}},
  ["autoplace-control"]=controls,
  ["map-settings"]={["map-settings"]={
    enemy_evolution={enabled=true,time_factor=.000004,
      destroy_factor=.002,pollution_factor=.0000009},
    enemy_expansion={enabled=true,
      min_expansion_cooldown=14400,max_expansion_cooldown=216000},
    difficulty_settings={technology_price_multiplier=1},
    pollution={ageing=1,enemy_attack_pollution_consumption_modifier=1},
    asteroids={spawning_rate=1}}},
  planet={
    nauvis=planet({["iron-ore"]={frequency=1,size=1,richness=1},
      ["crude-oil"]={frequency=.75,size=1,richness=1},
      ["enemy-base"]={frequency=1,size=1,richness=1},
      ["trees"]={frequency=1,size=1},["water"]={frequency=1,size=1},
      ["planet-temperature"]={frequency=.4}}),
    ferrum=planet({["ferric-scrap"]={frequency=.72,size=.65,richness=1.4},
      ["ionite-ore"]={frequency=.6,size=.9,richness=1},
      ["biter-base"]={frequency=.5,size=.8,richness=1}}),
    maraxsis=planet({["underground-salt"]={frequency=.35,size=.5,richness=.7},
      ["iron-ore"]={frequency=0,size=1,richness=1},
      ["meteorite-chunk"]={frequency="normal",size=1,richness=1}})
  }
 }})
 package.loaded["prototypes.system.razi_map_preset"]=nil
 return require("prototypes.system.razi_map_preset")
end
local specs={
 {"easy",1.30,1.30,1.55,.48,.72,.0000014,1},
 {"normal",1.05,1.08,1.20,.85,1,.000004,1},
 {"hard",.82,.85,.75,1.35,1.18,.000009,1.25},
 {"nightmare",.68,.75,.60,1.70,1.28,.000015,1.75}
}
for _,spec in ipairs(specs) do
 local mode,frequency,size,richness,enemies,enemy_size,time,research=
   spec[1],spec[2],spec[3],spec[4],spec[5],spec[6],spec[7],spec[8]
 local mod=make(mode,true)
 check(mod.data_final_fixes(),mode.." map presets failed")
 local group=data.raw["map-gen-presets"].default
 local selected=group["razi-protocol-"..mode]
 check(selected and selected.default==true and selected.basic_settings==nil
    and selected.advanced_settings==nil,
   "Selected mode must be the legal default=true marker: "..mode)
 check(not group.default.default and group["death-world"],
   "Native presets must remain selectable")
 check(not group["razi-protocol"] and not group["razi-protocol-custom"],
   "Old Recommended/Custom presets must be retired")
 for _,other in ipairs({"easy","normal","hard","nightmare"}) do
   if other~=mode then
     local profile=group["razi-protocol-"..other]
     check(profile and profile.basic_settings and profile.advanced_settings
       and not profile.default,
       "Other difficulty lacks complete map settings: "..other)
     check(profile.basic_settings.autoplace_controls["ionite-ore"]
       and profile.basic_settings.autoplace_controls["ferric-scrap"]
       and profile.basic_settings.autoplace_controls["meteorite-chunk"]
       and profile.basic_settings.autoplace_controls["biter-base"],
       "Modded ores and specialist enemies must receive full sliders")
     check(profile.basic_settings.autoplace_controls["planet-temperature"]==nil,
       "Temperature/climate controls must keep source rules")
   end
 end
 local worlds=data.raw.planet
 local iron=worlds.nauvis.map_gen_settings.autoplace_controls["iron-ore"]
 local ferric=worlds.ferrum.map_gen_settings.autoplace_controls["ferric-scrap"]
 local salt=worlds.maraxsis.map_gen_settings.autoplace_controls["underground-salt"]
 local threat=worlds.ferrum.map_gen_settings.autoplace_controls["biter-base"]
 local absent=worlds.maraxsis.map_gen_settings.autoplace_controls["iron-ore"]
 check(math.abs(iron.frequency-frequency)<.0001
   and math.abs(iron.size-size)<.0001
   and math.abs(iron.richness-richness)<.0001,
   "Nauvis frequency, size and richness must scale")
 check(math.abs(ferric.frequency-.72*frequency)<.0001
   and math.abs(ferric.size-.65*size)<.0001
   and math.abs(ferric.richness-1.4*richness)<.0001,
   "Other planet's native ore baseline must be preserved and scaled")
 check(math.abs(salt.frequency-.35*frequency)<.0001
   and math.abs(salt.richness-.7*richness)<.0001,
   "Maraxsis modded underground resources must scale")
 check(math.abs(threat.frequency-.5*enemies)<.0001
   and math.abs(threat.size-.8*enemy_size)<.0001,
   "Alien ecology on another planet must scale")
 check(absent.frequency==0,"Explicitly absent alien ore was re-enabled")
 check(worlds.nauvis.map_gen_settings.autoplace_controls
   ["planet-temperature"].frequency==.4,
   "Biome-specific climate must not be overwritten")
 local global=data.raw["map-settings"]["map-settings"]
 check(global.enemy_evolution.time_factor==time,
   "Auto-selected evolution wasn't applied")
 check(global.difficulty_settings.technology_price_multiplier==research,
   "Science cost was not synced with map profile")
 local spoil={easy=1.4,normal=1,hard=.82,nightmare=.65}
 check(global.difficulty_settings.spoil_time_modifier==spoil[mode],
   "Biological spoilage time is not difficulty adjusted")
 check(global.pollution.ageing==mod.profiles[mode].pollution_ageing,
   "Pollution absorption did not scale")
 check(global.asteroids.spawning_rate==mod.profiles[mode].asteroids,
   "Asteroid rate wasn't updated")
 local baseline=worlds.ferrum.map_gen_settings
   .autoplace_controls["ionite-ore"].richness
 mod.data_final_fixes()
 check(worlds.ferrum.map_gen_settings
   .autoplace_controls["ionite-ore"].richness==baseline,
   "Applying map profiles twice compounded remote ore values")
end
local off=make("hard",false)
off.data_final_fixes()
check(data.raw["map-gen-presets"].default.default.default==true,
 "Opting out must retain original map selection")
check(data.raw.planet.ferrum.map_gen_settings
 .autoplace_controls["ionite-ore"].frequency==.6,
 "Disabled Razi map generator must leave other planet generation alone")
local other=make("nightmare",true)
local group=data.raw["map-gen-presets"].default
group.default.default=nil
group["other-mod-default"]={default=true,order="a"}
other.data_final_fixes()
check(group["other-mod-default"].default==true
 and not group["razi-protocol-nightmare"].default,
 "Competing mod defaults must take priority")
check(data.raw.planet.ferrum.map_gen_settings
 .autoplace_controls["ionite-ore"].frequency==.6,
 "Competing mod default must not secretly change other planets")
local custom=make("custom",true)
custom.data_final_fixes()
check(data.raw["map-gen-presets"].default["razi-protocol-normal"].default,
 "Manual difficulty mode must choose safe Normal map defaults")
print("RP3 auto difficulty, four worlds, modded resources, zero controls and API safety passed")
