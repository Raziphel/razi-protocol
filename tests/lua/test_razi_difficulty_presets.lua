---@diagnostic disable: missing-fields, need-check-nil
-- Difficulty levels: Normal equals the plain defaults, Hard and Nightmare
-- move the managed levers, manual values and Custom are respected.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
---@type table<string,any>
local P=require("scripts.razi_difficulty_presets")

-- Collect the real declarations from settings.lua.
---@type table<string,any>
local declared={}
rawset(_G,"data",{extend=function(_,items)
  for _,item in ipairs(items) do declared[item.name]=item end
end})
dofile("settings.lua")
local LEVELS={"easy","normal","hard","nightmare"}

-- Every lever has a setting, its baseline is the setting's default, and every
-- level value is an allowed value of that setting.
local setting=declared["razi-difficulty-preset"]
check(setting and setting.setting_type=="startup","Missing difficulty setting")
check(setting.default_value=="normal","Normal must be the default level")
local allowed={}
for _,v in ipairs(setting.allowed_values) do allowed[v]=true end
for _,v in ipairs({"easy","normal","hard","nightmare","custom"}) do
  check(allowed[v],"Level not offered: "..v)
end
check(#setting.allowed_values==5,"Unexpected extra levels")
for _,name in ipairs(P.managed) do
  local item=declared[name]
  check(item,"Lever without a setting: "..name)
  check(item.setting_type=="startup","Levers must be startup settings: "..name)
  check(P.baseline[name]==item.default_value,
    "Baseline differs from the default of "..name)
  for _,level in ipairs(LEVELS) do
    ---@type any
    local value=P.presets[level][name]
    check(value~=nil,level.." misses "..name)
    check(type(value)==type(item.default_value),
      level.." has a wrong type for "..name)
    if item.allowed_values then
      local ok=false
      for _,v in ipairs(item.allowed_values) do ok=ok or v==value end
      check(ok,level.." uses a value that "..name.." does not offer")
    end
  end
end
for _,level in ipairs(LEVELS) do
  for name in pairs(P.presets[level]) do
    check(P.baseline[name]~=nil,level.." sets an unmanaged lever "..name)
  end
end
-- Normal is the baseline by construction.
for _,name in ipairs(P.managed) do
  check(P.presets.normal[name]==P.baseline[name],"Normal differs: "..name)
end

local function startup(level,manual)
  local t={["razi-difficulty-preset"]={value=level}}
  for name,default in pairs(P.baseline) do t[name]={value=default} end
  for name,value in pairs(manual or {}) do t[name]={value=value} end
  rawset(_G,"settings",{startup=t})
end

-- Normal with untouched settings: the plain defaults, not Custom.
startup("normal")
check(P.selected()=="normal" and P.active()=="normal","Normal must stay Normal")
check(#P.manual_overrides()==0,"Defaults must not count as manual changes")
for _,name in ipairs(P.managed) do
  check(P.effective(name,"fallback")==declared[name].default_value,
    "Normal changes "..name)
end

-- Table of levers by level.
local expected={
  easy={scale="balanced",population="sparse",belts="relaxed",ore="rich",
    interdependence="balanced",distributed=false},
  normal={scale="balanced",population="standard",belts="standard",
    ore="standard",interdependence="balanced",distributed=false},
  hard={scale="challenging",population="dense",belts="severe",
    ore="scarce",interdependence="deep",distributed=true},
  nightmare={scale="relentless",population="dense",belts="severe",
    ore="scarce",interdependence="deep",distributed=true},
}
local names={scale="razi-asteroid-difficulty-scale",
  population="razi-asteroid-population",belts="razi-belt-threats",
  ore="razi-belt-resource-richness",
  interdependence="razi-planetary-interdependence",
  distributed="razi-distributed-technology"}
for level,row in pairs(expected) do
  startup(level)
  check(P.active()==level,level.." must be active with default controls")
  for key,name in pairs(names) do
    check(P.effective(name)==row[key],
      level..": "..name.." is "..tostring(P.effective(name)))
  end
end

-- Map, combat and industry levers by level. The ore, research and evolution
-- levers are read only when changed by hand (the map profile of the level
-- holds them); launch cost, factory speed and wall strength follow the level.
local map_levers={
  ["razi-pollution-pressure"]={"gentle","normal","heavy","toxic"},
  ["razi-raid-coordination"]={"small","normal","organized","siege"},
  ["razi-colony-expansion"]={"slow","normal","rapid","invasive"},
  ["razi-spoilage-pressure"]={"forgiving","normal","fast","brutal"},
  ["razi-resource-frequency"]={"abundant","normal","scarce","desolate"},
  ["razi-resource-patch-size"]={"expansive","normal","small","tiny"},
  ["razi-resource-richness"]={"generous","normal","poor","meager"},
  ["razi-science-demand"]={"light","normal","intensive","grueling"},
  ["razi-evolution-speed"]={"slow","normal","accelerated","runaway"},
  ["razi-rocket-launch-cost"]={"economical","normal","costly","punishing"},
  ["razi-factory-throughput"]={"boosted","normal","constrained","strained"},
  ["razi-fortification-durability"]={"reinforced","normal","fragile","brittle"},
}
for name,row in pairs(map_levers) do
  for i,level in ipairs(LEVELS) do
    startup(level)
    check(P.active()==level and P.effective(name)==row[i],
      level..": "..name.." is "..tostring(P.effective(name)))
  end
  check(declared[name].default_value=="normal","Default of "..name)
  startup("hard",{[name]="normal"})
  check(P.active()=="hard" and P.effective(name)==row[3],
    "A lever left at its default follows the level: "..name)
end
startup("normal",{["razi-pollution-pressure"]="toxic"})
check(P.active()=="custom" and P.effective("razi-pollution-pressure")=="toxic",
  "A map lever changed by hand reports Custom and keeps its value")

-- Enemy homes: the level sets the step of the planets with themed enemies. The setting itself defaults to "auto",
-- which stands for the step of the level, so a step picked by hand is an override and keeps its value.
local habitats={"none","auto","wide","widest"}
check(declared["razi-enemy-habitats"].default_value=="auto","Default of razi-enemy-habitats")
for i,level in ipairs(LEVELS) do
  startup(level)
  check(P.active()==level and P.effective("razi-enemy-habitats")==habitats[i],
    level..": razi-enemy-habitats is "..tostring(P.effective("razi-enemy-habitats")))
end
startup("hard",{["razi-enemy-habitats"]="normal"})
check(P.active()=="custom" and P.effective("razi-enemy-habitats")=="normal"
  and P.effective("razi-asteroid-population")=="dense","A step picked on Hard keeps its value, the rest follows Hard")
startup("normal",{["razi-enemy-habitats"]="widest"})
check(P.active()=="custom" and P.effective("razi-enemy-habitats")=="widest","A step picked on Normal is used")
startup("custom")
check(P.effective("razi-enemy-habitats")=="auto","Custom keeps the saved value")

-- Spread technology unlocks: four levels, left alone or ticked by hand.
for _,level in ipairs(LEVELS) do
  local auto=(level=="hard" or level=="nightmare")
  startup(level)
  check(P.effective("razi-distributed-technology",true)==auto,
    level..": default spread technology")
  startup(level,{["razi-distributed-technology"]=true})
  check(P.effective("razi-distributed-technology",false)==true,
    level..": ticked by hand must stay on")
end
-- Turning it off on Hard needs Custom, like any managed lever.
startup("hard")
check(P.effective("razi-distributed-technology")==true,"Hard turns it on")
startup("custom")
check(P.effective("razi-distributed-technology")==false,"Custom keeps the saved value")
startup("custom",{["razi-distributed-technology"]=true})
check(P.effective("razi-distributed-technology")==true,"Custom keeps a ticked value")

-- Ticking it on Normal makes the session Custom but still honours the tick.
startup("normal",{["razi-distributed-technology"]=true})
check(P.active()=="custom","A manual change reports Custom")
check(P.is_overridden("razi-distributed-technology"),"Tick is an override")
check(P.effective("razi-distributed-technology")==true,"Tick on Normal is used")
check(P.effective("razi-asteroid-population")=="standard","Other levers stay Normal")

-- A manual lever keeps its value on a named level; the others follow it.
startup("hard",{["razi-asteroid-population"]="sparse"})
check(P.active()=="custom","Hard with a manual lever reports Custom")
check(P.effective("razi-asteroid-population")=="sparse","Manual lever lost")
check(P.effective("razi-belt-threats")=="severe","Hard must still set the rest")
check(#P.manual_overrides()==1,"Exactly one manual lever")

-- Custom ignores the level tables completely.
startup("custom",{["razi-belt-threats"]="relaxed"})
check(P.selected()=="custom" and P.active()=="custom","Custom is selectable")
check(P.effective("razi-belt-threats")=="relaxed","Custom uses saved values")
check(P.effective("razi-asteroid-population")=="standard","Custom is not Hard")

-- Values that are false must not fall back (saved bool settings).
startup("normal",{["razi-belt-edge-harvesting"]=false})
check(P.effective("razi-belt-edge-harvesting",true)==false,
  "A saved false must beat a true fallback")

-- Unknown level or missing settings fail safe.
startup("legendary")
check(P.selected()=="normal","Unknown level must fall back to Normal")
rawset(_G,"settings",nil)
check(P.active()=="normal" and P.effective("razi-belt-threats","standard")=="standard",
  "Missing settings keep the established behaviour")
rawset(_G,"settings",{startup={["razi-difficulty-preset"]={value="hard"}}})
check(P.effective("razi-belt-threats","standard")=="standard",
  "A lever whose setting is not declared is not managed")
rawset(_G,"settings",{startup={}})
check(P.effective("razi-belt-threats")==nil,"No fallback means nil")

-- Locale: every level and lever value has text in both languages.
local function text(path)
  local f=assert(io.open(path,"r")); local s=f:read("*a"); f:close(); return s
end
for _,lang in ipairs({"en","ru"}) do
  local cfg=text("locale/"..lang.."/settings.cfg")
  local keys={"razi-difficulty-preset","razi-asteroid-difficulty-scale",
    "razi-default-new-game-map"}
  for name,values in pairs(map_levers) do
    keys[#keys+1]=name
    for _,v in ipairs(values) do keys[#keys+1]=name.."-"..v end
  end
  for _,v in ipairs(setting.allowed_values) do
    keys[#keys+1]="razi-difficulty-preset-"..v
  end
  for _,v in ipairs(declared["razi-asteroid-difficulty-scale"].allowed_values) do
    keys[#keys+1]="razi-asteroid-difficulty-scale-"..v
  end
  for _,key in ipairs(keys) do
    check(cfg:find("\n"..key.."=",1,true),lang.." locale misses "..key)
  end
  local description=cfg:match("\n%[mod%-setting%-description%].*")
  check(cfg:find("\nrazi-enemy-habitats=",1,true),lang.." misses the name of the enemy homes")
  check(description:find("\nrazi-enemy-habitats=",1,true),lang.." misses the description of the enemy homes")
  for _,v in ipairs(declared["razi-enemy-habitats"].allowed_values) do
    check(cfg:find("\nrazi-enemy-habitats-"..v.."=",1,true),lang.." misses razi-enemy-habitats-"..v)
  end
  check(description:find("\nrazi-difficulty-preset=",1,true),
    lang.." misses the level description")
  for name in pairs(map_levers) do
    check(description:find("\n"..name.."=",1,true),
      lang.." misses the description of "..name)
  end
  check(description:find("\nrazi-default-new-game-map=",1,true),
    lang.." misses the description of the map option")
  for line in cfg:gmatch("[^\n]+") do
    check(#line<1500,lang.." locale line too long: "..line:sub(1,40))
  end
end
print("Difficulty levels passed")
