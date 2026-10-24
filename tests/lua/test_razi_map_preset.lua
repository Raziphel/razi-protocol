---@diagnostic disable: need-check-nil, undefined-field, missing-fields
-- World profiles: Normal writes nothing, Easy/Hard/Nightmare scale every
-- planet and the global map settings, Curated is only a listed preset, and
-- the cap on control values never cuts down a source value.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end
local function near(a,b) return type(a)=="number" and math.abs(a-b)<1e-9 end
local function planet(fields)
 return {map_gen_settings={autoplace_controls=fields}}
end
local controls={
 ["iron-ore"]={category="resource",richness=true},
 ["ionite-ore"]={category="resource",richness=true},
 ["ferric-scrap"]={category="resource",richness=true},
 ["crude-oil"]={category="resource",richness=true},
 ["steam_geyser"]={category="resource",richness=true},
 ["rich-soil"]={category="resource",richness=true},
 ["meteorite-chunk"]={category="resource",richness=true},
 ["underground-salt"]={category="resource",richness=true},
 ["biter-base"]={category="enemy",richness=false},
 ["enemy-base"]={category="enemy",richness=false},
 ["trees"]={category="terrain",richness=false},
 ["water"]={category="terrain",richness=false},
 ["cliff"]={category="cliff",richness=false},
 ["planet-temperature"]={category="terrain",richness=false}
}
local function deepcopy(v)
 if type(v)~="table" then return v end
 local r={}
 for k,c in pairs(v) do r[k]=deepcopy(c) end
 return r
end
local function equal(a,b)
 if type(a)~=type(b) then return false end
 if type(a)~="table" then return a==b end
 for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
 for k in pairs(b) do if a[k]==nil then return false end end
 return true
end
local function fixture()
 return {
  ["map-gen-presets"]={default={
    default={default=true,order="a"},
    ["death-world"]={order="d"}}},
  ["autoplace-control"]=controls,
  ["map-settings"]={["map-settings"]={
    enemy_evolution={enabled=true,time_factor=.000004,
      destroy_factor=.002,pollution_factor=.0000009},
    enemy_expansion={enabled=true,min_expansion_distance=3,
      max_expansion_distance=5,settler_group_min_size=5,
      settler_group_max_size=10,min_expansion_cooldown=36000,
      max_expansion_cooldown=216000},
    difficulty_settings={technology_price_multiplier=1},
    pollution={enabled=true,ageing=1,diffusion_ratio=.02,min_to_diffuse=15,
      enemy_attack_pollution_consumption_modifier=1},
    unit_group={max_unit_group_size=200,max_gathering_unit_groups=10,
      min_group_gathering_time=3600,max_group_gathering_time=36000},
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
      ["meteorite-chunk"]={frequency="normal",size=1,richness=1}}),
    moshine=planet({["steam_geyser"]={frequency=1,size=1,richness=150}}),
    prosephina=planet({["rich-soil"]={frequency=20,size=2,richness=1},
      ["water"]={frequency=7,size=1}})
  }
 }
end
-- settings: level, the choice for the map option and manual lever values.
local function make(mode,enabled,manual)
 local startup={
   ["razi-difficulty-preset"]={value=mode},
   ["razi-default-new-game-map"]={value=enabled}}
 for name,value in pairs(manual or {}) do startup[name]={value=value} end
 rawset(_G,"settings",{startup=startup})
 rawset(_G,"data",{raw=fixture()})
 package.loaded["prototypes.system.razi_map_preset"]=nil
 package.loaded["scripts.razi_difficulty_presets"]=nil
 return require("prototypes.system.razi_map_preset")
end

-- The cap: only a value that would newly cross it is held at 6.
local probe=make("normal",true)
check(near(probe.scaled(5,1.55),6),"A value that would cross the cap is held at it")
check(near(probe.scaled(1,1.3),1.3),"Values below the cap scale")
check(probe.scaled(150,1)==150,"A source value above the cap survives x1")
check(near(probe.scaled(150,.75),112.5),"A source value above the cap scales down")
check(near(probe.scaled(7,1.3),9.1),"A source value above the cap scales up")
check(probe.scaled(0,3)==0,"Zero stays zero")
check(near(probe.scaled("normal",.5),.5),"Named sizes are numbers")

-- Normal: nothing is written to planets or map settings.
for _,enabled in ipairs({true,false}) do
 local mod=make("normal",enabled)
 local before=deepcopy(data.raw)
 check(mod.data_final_fixes(),"Normal map presets failed")
 check(equal(before.planet,data.raw.planet),
   "Normal changed a planet (enabled="..tostring(enabled)..")")
 check(equal(before["map-settings"],data.raw["map-settings"]),
   "Normal changed the map settings (enabled="..tostring(enabled)..")")
 check(equal(before["autoplace-control"],data.raw["autoplace-control"]),
   "Normal changed a control")
 check(data.raw.planet.moshine.map_gen_settings
   .autoplace_controls.steam_geyser.richness==150,
   "Normal cut the steam geyser richness")
 check(data.raw.planet.prosephina.map_gen_settings
   .autoplace_controls["rich-soil"].frequency==20,
   "Normal cut a frequency above the cap")
 -- Only the preset list differs.
 before["map-gen-presets"]=nil
 local after=deepcopy(data.raw); after["map-gen-presets"]=nil
 check(equal(before,after),"Normal changed more than the preset list")
end

local specs={
 {"easy",1.30,1.30,1.55,1.62,.48,.72,.0000014,1,1.2,.72,1.4},
 {"hard",.82,.85,.75,.82,1.35,1.18,.000009,1.25,.9,1.18,.82},
 {"nightmare",.68,.75,.60,.65,1.70,1.28,.000015,1.75,.82,1.32,.65}
}
for _,spec in ipairs(specs) do
 local mode,frequency,size,richness,oil,enemies,enemy_size,time,research,
   ageing,diffusion,spoil=table.unpack(spec)
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
 for _,other in ipairs(mod.modes) do
   if other~=mode then
     local profile=group["razi-protocol-"..other]
     check(profile and profile.basic_settings and profile.advanced_settings
       and not profile.default,
       "Other profile lacks complete map settings: "..other)
     check(profile.basic_settings.autoplace_controls["planet-temperature"]==nil,
       "Temperature/climate controls must keep source rules")
     if other~="normal" then
       local c=profile.basic_settings.autoplace_controls
       check(c["ionite-ore"] and c["ferric-scrap"] and c["meteorite-chunk"]
         and c["biter-base"],
         "Modded ores and specialist enemies must receive full sliders")
     end
   end
 end
 local worlds=data.raw.planet
 local iron=worlds.nauvis.map_gen_settings.autoplace_controls["iron-ore"]
 local oil_control=worlds.nauvis.map_gen_settings.autoplace_controls["crude-oil"]
 local ferric=worlds.ferrum.map_gen_settings.autoplace_controls["ferric-scrap"]
 local salt=worlds.maraxsis.map_gen_settings.autoplace_controls["underground-salt"]
 local threat=worlds.ferrum.map_gen_settings.autoplace_controls["biter-base"]
 local absent=worlds.maraxsis.map_gen_settings.autoplace_controls["iron-ore"]
 local geyser=worlds.moshine.map_gen_settings.autoplace_controls.steam_geyser
 check(near(iron.frequency,frequency) and near(iron.size,size)
   and near(iron.richness,richness),
   "Nauvis frequency, size and richness must scale")
 check(near(oil_control.richness,oil),"Oil richness must use the oil factor")
 check(near(ferric.frequency,.72*frequency) and near(ferric.size,.65*size)
   and near(ferric.richness,1.4*richness),
   "Other planet's native ore baseline must be preserved and scaled")
 check(near(salt.frequency,.35*frequency) and near(salt.richness,.7*richness),
   "Maraxsis modded underground resources must scale")
 check(near(threat.frequency,.5*enemies) and near(threat.size,.8*enemy_size),
   "Alien ecology on another planet must scale")
 check(absent.frequency==0,"Explicitly absent alien ore was re-enabled")
 check(near(geyser.richness,150*oil) or near(geyser.richness,150*richness),
   "A steam geyser richness above the cap must scale, not drop to 6")
 check(geyser.richness>6,"A steam geyser richness above the cap was cut down")
 check(worlds.prosephina.map_gen_settings.autoplace_controls["rich-soil"]
   .frequency>6,"A frequency above the cap was cut down")
 check(near(worlds.prosephina.map_gen_settings.autoplace_controls
   ["rich-soil"].richness,richness),"rich-soil must not take the oil factor")
 check(worlds.nauvis.map_gen_settings.autoplace_controls
   ["planet-temperature"].frequency==.4,
   "Biome-specific climate must not be overwritten")
 local global=data.raw["map-settings"]["map-settings"]
 check(global.enemy_evolution.time_factor==time,
   "Auto-selected evolution wasn't applied")
 check(global.difficulty_settings.technology_price_multiplier==research,
   "Science cost was not synced with map profile")
 check(near(global.difficulty_settings.spoil_time_modifier,spoil),
   "Biological spoilage time is not difficulty adjusted")
 check(near(global.pollution.ageing,ageing),"Pollution absorption did not scale")
 check(near(global.pollution.diffusion_ratio,.02*diffusion),
   "Pollution diffusion did not scale")
 check(global.asteroids.spawning_rate==mod.profiles[mode].asteroids,
   "Asteroid rate wasn't updated")
 check(global.enemy_expansion.max_expansion_distance
   ==mod.profiles[mode].expansion.max_expansion_distance,
   "Enemy expansion was not applied")
 -- Curated is never applied by itself.
 check(group["razi-protocol-curated"].default==nil,
   "Curated must stay a listed preset")
 -- Another profile in the list shows its own level, not the active one.
 local listed=group["razi-protocol-easy"]
 if mode~="easy" then
   check(near(listed.advanced_settings.pollution.diffusion_ratio,.02*.72),
     "The Easy preset took the pollution of the active level")
 end
 local complete=group[mode=="easy" and "razi-protocol-hard" or "razi-protocol-easy"]
 check(not (complete.advanced_settings.pollution
   and complete.advanced_settings.pollution.min_to_diffuse),
   "Unsupported pollution threshold field inside map preset")
 local baseline=worlds.ferrum.map_gen_settings
   .autoplace_controls["ionite-ore"].richness
 mod.data_final_fixes()
 check(worlds.ferrum.map_gen_settings
   .autoplace_controls["ionite-ore"].richness==baseline,
   "Applying map profiles twice compounded remote ore values")
 check(near(data.raw["map-settings"]["map-settings"].pollution.diffusion_ratio,
   .02*diffusion),"Applying map profiles twice compounded pollution")
end

-- The listed profiles whatever the active level is.
do
 local mod=make("normal",true)
 mod.data_final_fixes()
 local group=data.raw["map-gen-presets"].default
 local normal_marker=group["razi-protocol-normal"]
 check(normal_marker.default==true and normal_marker.basic_settings==nil,
   "Normal is the default marker on Normal")
 local curated=group["razi-protocol-curated"]
 local c=curated.basic_settings.autoplace_controls["iron-ore"]
 check(near(c.frequency,1.05) and near(c.size,1.08) and near(c.richness,1.2),
   "Curated carries its ore factors")
 check(near(curated.basic_settings.starting_area,1.65),"Curated start area")
 local e=curated.advanced_settings.enemy_expansion
 check(e.min_expansion_distance==2 and e.max_expansion_distance==7
   and e.settler_group_max_size==12 and e.min_expansion_cooldown==14400,
   "Curated carries its enemy expansion")
 local hard=make("hard",true)
 hard.data_final_fixes()
 local listed=data.raw["map-gen-presets"].default["razi-protocol-normal"]
 check(listed.basic_settings.starting_area==1
   and next(listed.basic_settings.autoplace_controls or {})==nil,
   "Normal in the list changes no control")
 local ex=listed.advanced_settings.enemy_expansion
 check(ex.max_expansion_distance==5 and ex.settler_group_max_size==10
   and ex.min_expansion_cooldown==36000,
   "Normal in the list keeps the game's enemy expansion")
 check(near(listed.advanced_settings.enemy_evolution.time_factor,.000004),
   "Normal in the list keeps the game's evolution")
 check(listed.advanced_settings.difficulty_settings
   .technology_price_multiplier==1,"Normal in the list keeps the research price")
end

-- The option off: nothing is claimed or scaled.
local off=make("hard",false)
off.data_final_fixes()
check(data.raw["map-gen-presets"].default.default.default==true,
 "Opting out must retain original map selection")
check(data.raw.planet.ferrum.map_gen_settings
 .autoplace_controls["ionite-ore"].frequency==.6,
 "Disabled Razi map generator must leave other planet generation alone")
check(data.raw["map-settings"]["map-settings"].enemy_evolution.time_factor
 ==.000004,"Disabled Razi map generator must leave the map settings alone")

-- The option on takes the default from another mod; its preset stays listed.
local other=make("nightmare",true)
local group=data.raw["map-gen-presets"].default
group.default.default=nil
group["other-mod-default"]={default=true,order="a",
 basic_settings={starting_area=3}}
other.data_final_fixes()
check(group["other-mod-default"].default==nil
 and group["other-mod-default"].basic_settings.starting_area==3
 and group["razi-protocol-nightmare"].default==true,
 "Razi must take the default and keep the other preset")

-- Custom: the Normal map with the lever values saved by hand.
local custom=make("custom",true,{
 ["razi-colony-expansion"]="rapid",
 ["razi-raid-coordination"]="siege",
 ["razi-science-demand"]="intensive",
 ["razi-evolution-speed"]="runaway",
 ["razi-resource-frequency"]="scarce",
 ["razi-spoilage-pressure"]="brutal"})
custom.data_final_fixes()
local cgroup=data.raw["map-gen-presets"].default
check(cgroup["razi-protocol-custom"].default==true,
 "Custom must choose its own marker")
local cglobal=data.raw["map-settings"]["map-settings"]
check(cglobal.enemy_expansion.min_expansion_cooldown==29880
 and cglobal.enemy_expansion.settler_group_max_size==12
 and cglobal.enemy_expansion.max_expansion_distance==5,
 "Custom colonies scale the game's own expansion")
check(cglobal.unit_group.max_unit_group_size==200
 and cglobal.unit_group.max_gathering_unit_groups==12
 and cglobal.unit_group.min_group_gathering_time==2952,
 "Custom raids scale the game's own unit groups")
check(cglobal.difficulty_settings.technology_price_multiplier==1.5,
 "Custom research price")
check(near(cglobal.enemy_evolution.time_factor,.000004*1.7),
 "Custom evolution scales the game's own factor")
check(near(cglobal.difficulty_settings.spoil_time_modifier,.65),
 "Custom spoilage")
check(near(data.raw.planet.nauvis.map_gen_settings
 .autoplace_controls["iron-ore"].frequency,.75),
 "Custom ore frequency")
check(data.raw.planet.moshine.map_gen_settings
 .autoplace_controls.steam_geyser.richness==150,
 "Custom keeps the source steam geyser richness")

-- Locale: every listed profile has a name and a description in both languages.
local function text(path)
 local f=assert(io.open(path,"r")); local s=f:read("*a"); f:close(); return s
end
local mod=make("normal",true)
for _,lang in ipairs({"en","ru"}) do
 local cfg=text("locale/"..lang.."/map_preset.cfg")
 local names=cfg:match("%[map%-gen%-preset%-name%](.-)%[map%-gen%-preset%-description%]")
 local descriptions=cfg:match("%[map%-gen%-preset%-description%](.*)")
 check(names and descriptions,lang.." map_preset.cfg lacks a section")
 local ids={"custom"}
 for _,m in ipairs(mod.modes) do ids[#ids+1]=m end
 for _,id in ipairs(ids) do
  check(names:find("\nrazi-protocol-"..id.."=",1,true),
   lang.." misses the name of "..id)
  check(descriptions:find("\nrazi-protocol-"..id.."=",1,true),
   lang.." misses the description of "..id)
 end
 for line in cfg:gmatch("[^\n]+") do
  check(#line<700,lang.." map preset text too long: "..line:sub(1,40))
 end
end
print("World profiles: Normal unchanged, scaled levels, cap, Curated and Custom passed")
