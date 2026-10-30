-- Numeric settings of other mods for the difficulty level: the data stage
-- view of the setting from Razi's data.lua on, the saved value back before
-- the corrections of data-final-fixes.lua. Normal and Custom write nothing;
-- yes/no settings are never touched.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
local logged={}
rawset(_G,"log",function(line) logged[#logged+1]=line end)
local bridge=require("prototypes.compat.foreign_difficulty_settings")
local stage=require("prototypes.compat.foreign_numeric_stage_effects")
local power=require("prototypes.compat.muluna_power_difficulty")
local bio=require("prototypes.compat.biological_machines_difficulty")

-- Limits the owning mods declare in their settings.lua (Muluna 2.7.44,
-- Rubia 0.69.161, Cerys 4.24.18, Balack 1.1.2).
local limits={
 ["space-science-pack-output"]={integer=true,min=1,max=10},
 ["muluna-interstellar-science-pack-packs-required"]={integer=true,min=1},
 ["muluna-interstellar-science-pack-dynamic-packs-required-percentage-required"]={min=1,max=100},
 ["rubia-tech-cost-multiplier"]={integer=true,min=1,max=69420},
 ["space-science-pack-energy"]={min=.01,max=60},
 ["muluna-balance-exploration-science-data-cost"]={min=1,max=100},
 ["cerys-undo-marathon-multiplier"]={min=.1,max=100000},
 ["platform-power-consumption"]={min=.3,max=1000},
 ["bm-cube-speed"]={min=.01,max=100},
 ["bm-cube-pollution"]={integer=true,min=100,max=1000000},
}
local function inside(name,value,where)
 local limit=limits[name]
 check(limit,where..": "..name.." has no limits in this test")
 check(type(value)=="number",where..": "..name.." is not a number")
 check(value>=limit.min,where..": "..name.." is below its minimum")
 check(not limit.max or value<=limit.max,where..": "..name.." is above its maximum")
 check(not limit.integer or value==math.floor(value),
  where..": "..name.." must be a whole number")
end
local levels={"easy","hard","nightmare"}
local seen={}
for _,module in ipairs({bridge,stage,bio}) do
 for _,level in ipairs(levels) do
  for name,value in pairs(module.profiles[level]) do
   inside(name,value,level)
   seen[name]=(seen[name] or 0)+1
  end
 end
end
for _,level in ipairs(levels) do inside("platform-power-consumption",power.values[level],level) end
for name,count in pairs(seen) do
 check(count==3,name.." must be in exactly one module, once per level")
end
-- Easy is easier than Normal, Normal than Hard, Hard than Nightmare in every
-- number. The defaults of the mods: Muluna 2/2/50/7/10/100, Rubia 1, Cerys
-- 1, Balack 1/10000 (a higher "multiplier" of Cerys is easier).
local easier_when_higher={["space-science-pack-output"]=true,["cerys-undo-marathon-multiplier"]=true,["bm-cube-speed"]=true}
for _,module in ipairs({bridge,stage,bio}) do
 for name in pairs(module.profiles.hard) do
  local e,h,n=module.profiles.easy[name],module.profiles.hard[name],module.profiles.nightmare[name]
  if easier_when_higher[name] then
   check(e>h and h>=n,name.." must fall from Easy to Nightmare")
  else
   check(e<=h and h<=n,name.." must rise from Easy to Nightmare")
  end
 end
end

-- The settings bridge works on the settings.startup view. Saved values that
-- no level uses.
local saved_value={
 ["space-science-pack-output"]=7,
 ["muluna-interstellar-science-pack-packs-required"]=6,
 ["muluna-interstellar-science-pack-dynamic-packs-required-percentage-required"]=55,
 ["rubia-tech-cost-multiplier"]=5,
}
local enabled={["planet-muluna"]="2.7.44",rubia="0.69.161",["Krastorio2-spaced-out"]="2.0.17"}
---@return table<string,any>
local function startup()
 ---@type table<string,any>
 local saved={
  ["razi-difficulty-preset"]={value="hard"},
  ["kr-revert-thruster-fuel-changes"]={value=true},
  ["muluna-easy-alternative-battery-recipe"]={value=true},
  ["muluna-change-quality-science-pack-drain"]={value=false},
  ["muluna-interstellar-science-pack-dynamic-packs-required"]={value=true},
 }
 for name,mod in pairs(bridge.owners) do
  check(mod=="planet-muluna" or mod=="rubia","owner "..mod.." is not a mod of this bridge")
  saved[name]={value=saved_value[name]}
 end
 return saved
end
check(next(bridge.owners)~=nil,"the bridge must name its settings")
local count=0
for _ in pairs(bridge.owners) do count=count+1 end
for _,level in ipairs(levels) do
 for name in pairs(bridge.profiles[level]) do
  check(bridge.owners[name],name.." has no owner")
 end
end
check(count==4,"four settings are in reach of Razi's data.lua")

for _,level in ipairs(levels) do
 local saved=startup()
 saved["razi-difficulty-preset"].value=level
 local before={}
 for name,record in pairs(saved) do before[name]=record.value end
 local changed=bridge.apply(saved,enabled)
 check(changed>0,level..": no setting changed")
 for name,value in pairs(bridge.profiles[level]) do
  check(saved[name].value==value,level..": "..name.." is not the value of the level")
 end
 for _,name in ipairs({"kr-revert-thruster-fuel-changes","muluna-easy-alternative-battery-recipe",
   "muluna-change-quality-science-pack-drain","muluna-interstellar-science-pack-dynamic-packs-required"}) do
  check(saved[name].value==before[name],level..": the yes/no setting "..name.." changed")
 end
 check(bridge.apply(saved,enabled)==0,level..": a second apply must write nothing")
 check(bridge.restore()==changed,level..": restore must put back what apply changed")
 for name,value in pairs(before) do
  check(saved[name].value==value,level..": "..name.." was not restored")
 end
 check(bridge.restore()==0,level..": a second restore must write nothing")
end

-- Normal and Custom never write, even with settings changed by hand.
for _,level in ipairs({"normal","custom","unknown"}) do
 local saved=startup()
 saved["razi-difficulty-preset"].value=level
 for name in pairs(bridge.owners) do saved[name].value=saved_value[name]+1 end
 check(bridge.apply(saved,enabled)==0,level.." must write nothing")
 check(bridge.restore()==0,level.." has nothing to restore")
 for name in pairs(bridge.owners) do
  check(saved[name].value==saved_value[name]+1,level.." changed "..name)
 end
end

-- A setting of a mod that is not installed, a wrong type, a missing setting
-- and a setting the engine will not let us write.
local saved=startup()
check(bridge.apply(saved,{})==0,"mods that are not installed are skipped")
check(bridge.apply(saved,{rubia="1"})==1,"only the installed owner is used")
check(saved["rubia-tech-cost-multiplier"].value==2,"Rubia: Hard is 2")
check(saved["space-science-pack-output"].value==saved_value["space-science-pack-output"],
 "Muluna is not installed: its setting stays")
bridge.restore()
local typed=startup()
typed["rubia-tech-cost-multiplier"].value="wrong type"
check(bridge.apply(typed,{rubia="1"})==0,"a wrong type is not coerced")
bridge.restore()
local missing=startup()
missing["rubia-tech-cost-multiplier"]=nil
check(bridge.apply(missing,{rubia="1"})==0,"a missing setting is not made up")
local locked=startup()
locked["rubia-tech-cost-multiplier"]=setmetatable({},{
 __index=function(_,key) if key=="value" then return 9 end end,
 __newindex=function() error("immutable setting") end
})
check(bridge.apply(locked,{rubia="1"})==0,"a setting that cannot be written is skipped")
check(bridge.restore()==0,"nothing to restore after a refused write")
-- Another mod changed the value meanwhile: restore keeps its change.
local shared=startup()
bridge.apply(shared,enabled)
shared["rubia-tech-cost-multiplier"].value=7
bridge.restore()
check(shared["rubia-tech-cost-multiplier"].value==7,"restore must keep a later change of another mod")

-- The whole stage order with Lua's globals, as the game runs it: data.lua,
-- the readers in data-updates.lua / data-final-fixes.lua, restore, then the
-- corrections that need the saved values.
---@return any,any
local function stage_run(level)
 local view=startup()
 view["razi-difficulty-preset"].value=level
 view["space-science-pack-energy"]={value=7}
 view["muluna-balance-exploration-science-data-cost"]={value=10}
 view["cerys-undo-marathon-multiplier"]={value=1}
 view["platform-power-consumption"]={value=100}
 view["bm-cube-speed"]={value=1}
 view["bm-cube-pollution"]={value=10000}
 rawset(_G,"settings",{startup=view})
 rawset(_G,"mods",{["planet-muluna"]="2.7.44",rubia="0.69.161",
  ["Cerys-Moon-of-Fulgora"]="4.24.18",["biological-machines-planet-balack"]="1.1.2"})
 rawset(_G,"data",{raw={
  recipe={["space-science-pack"]={energy_required=7},
   ["interstellar-science-pack"]={ingredients={{type="fluid",name="muluna-astronomical-data",amount=10}}}},
  technology={["cerys-electromagnetic-tooling"]={unit={count=20}}},
  accumulator={["muluna-satellite-radar"]={energy_usage="100MW",
   energy_source={buffer_capacity="300MJ",input_flow_limit="300MW"},custom_tooltip_fields={}}},
  ["mod-data"]={["muluna-satellite-radar"]={data={entities={
   ["muluna-satellite-radar"]={energy_per_scan=100,scan_area=100}}}}},
  ["assembling-machine"]={["bm-bio-cube"]={crafting_speed=1,crafting_categories={"bm-bio-cube"},
   energy_source={emissions_per_minute={pollution=10000}}}},
 }})
 -- data.lua
 bridge.apply()
 -- a reader in data-updates.lua sees the value of the level
 local read=settings.startup["space-science-pack-output"].value
 -- data-final-fixes.lua
 bridge.restore()
 check(settings.startup["space-science-pack-output"].value==saved_value["space-science-pack-output"],
  level..": the saved value must be back before the corrections")
 stage.data_final_fixes()
 power.data_final_fixes()
 bio.data_final_fixes()
 return read,data.raw
end
---@type any
local raw
---@type any
local output
output,raw=stage_run("hard")
check(output==1,"Hard: the reader must see output 1")
check(raw.recipe["space-science-pack"].energy_required==9,"Hard: space science energy 7 -> 9")
check(raw.technology["cerys-electromagnetic-tooling"].unit.count==25,"Hard: Cerys 20 -> 25")
check(raw.accumulator["muluna-satellite-radar"].energy_usage=="125MW","Hard: radar 125 MW")
check(raw["assembling-machine"]["bm-bio-cube"].crafting_speed==.85,"Hard: bio fabricator speed")

-- Normal and Custom: no prototype value, no setting changes at all.
for _,level in ipairs({"normal","custom"}) do
 output,raw=stage_run(level)
 check(output==saved_value["space-science-pack-output"],level..": the reader must see the saved value")
 check(raw.recipe["space-science-pack"].energy_required==7,level..": space science changed")
 check(raw.recipe["interstellar-science-pack"].ingredients[1].amount==10,level..": data cost changed")
 check(raw.technology["cerys-electromagnetic-tooling"].unit.count==20,level..": Cerys changed")
  check(raw.accumulator["muluna-satellite-radar"].energy_usage=="100MW",level..": radar changed")
 check(raw["assembling-machine"]["bm-bio-cube"].crafting_speed==1,level..": bio fabricator changed")
end
print("PASS test_foreign_difficulty_settings")
