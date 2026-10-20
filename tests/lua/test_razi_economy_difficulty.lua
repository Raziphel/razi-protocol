-- Difficulty economy: full map controls, Custom overrides and rocket silos.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
local source=require("scripts.razi_economy_difficulty")
local rocket=require("prototypes.compat.razi_launch_economy")
local resolver=require("scripts.razi_difficulty_presets")
local function selected(mode,overrides)
 local startup={["razi-difficulty-preset"]={value=mode}}
 for name,value in pairs(resolver.baseline) do startup[name]={value=value} end
 for name,value in pairs(overrides or {}) do startup[name]={value=value} end
 rawset(_G,"settings",{startup=startup})
end
local function spec()
 return {resource={frequency=1.05,size=1.08,richness=1.2},
  oil=1.2,research=1,evolution={
    time_factor=.000004,destroy_factor=.002,pollution_factor=.0000009}}
end
for _,row in ipairs({{"easy",.70},{"normal",1},{"hard",1.30},
                       {"nightmare",1.65}}) do
 selected(row[1])
 check(math.abs(source.rocket_factor(resolver)-row[2])<.0001,
   "Rocket launches must follow "..row[1])
 local e=source.profile(row[1],spec(),resolver)
 check(e.resource.frequency==1.05 and e.research==1,
   "Named map profiles should not double-multiply base values")
end
selected("hard",{
 ["razi-resource-frequency"]="desolate",
 ["razi-resource-patch-size"]="tiny",
 ["razi-resource-richness"]="meager",
 ["razi-science-demand"]="grueling",
 ["razi-evolution-speed"]="runaway",
 ["razi-rocket-launch-cost"]="economical"})
check(resolver.active()=="custom","Manual economy edits must resolve Custom")
local adjusted=source.profile("normal",spec(),resolver)
check(math.abs(adjusted.resource.frequency-.525)<.00001,
 "Custom resource frequency did not take effect")
check(math.abs(adjusted.resource.size-.648)<.00001,
 "Custom patch size did not take effect")
check(math.abs(adjusted.resource.richness-.54)<.00001
 and math.abs(adjusted.oil-.54)<.00001,
 "Custom richness must also scale oil")
check(adjusted.research==2
 and math.abs(adjusted.evolution.destroy_factor-.0034)<.00000001,
 "Custom research/evolution must affect the engine profile")
local silos={
 base={rocket_parts_required=50,rocket_parts_storage_cap=50},
 custom={rocket_parts_required=80,rocket_parts_storage_cap=0},
 broken={rocket_parts_required=3,rocket_parts_storage_cap=1},
 unknown={}
}
selected("nightmare")
check(rocket.adjust(silos,resolver)==3,
 "Nightmare should modify only valid rocket silos")
check(silos.base.rocket_parts_required==83
 and silos.base.rocket_parts_storage_cap==83,
 "Storage must grow with the new rocket cost")
check(silos.custom.rocket_parts_required==132
 and silos.custom.rocket_parts_storage_cap==0,
 "Zero is a special silo storage value; preserve it")
check(silos.broken.rocket_parts_storage_cap>=
 silos.broken.rocket_parts_required,
 "Existing storage caps must never be too small")
check(rocket.adjust(silos,resolver)==0,
 "Repeated data stage invocation must not compound rocket crafts")
selected("normal")
rocket.adjust(silos,resolver)
check(silos.base.rocket_parts_required==83,
 "Normal must not overwrite source or already-configured silo prototypes")
print("RP3 resource, research, evolution and launch-cost presets passed")
