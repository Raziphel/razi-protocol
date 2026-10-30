-- Difficulty economy: Custom overrides of ore, research price and evolution,
-- and the rocket launch cost of each level.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
local source=require("scripts.razi_economy_difficulty")
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
for _,mode in ipairs({"easy","normal","hard","nightmare"}) do
 selected(mode)
 local e=source.profile(spec(),resolver)
 check(e.resource.frequency==1.05 and e.research==1,
   "Named map profiles should not double-multiply base values")
end
selected("hard",{
 ["razi-resource-frequency"]="desolate",
 ["razi-resource-patch-size"]="tiny",
 ["razi-resource-richness"]="meager",
 ["razi-science-demand"]="grueling",
 ["razi-evolution-speed"]="runaway"})
check(resolver.active()=="custom","Manual economy edits must resolve Custom")
local adjusted=source.profile(spec(),resolver)
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
-- A profile without evolution numbers does not fail.
local bare=spec(); bare.evolution=nil
check(source.profile(bare,resolver).evolution==nil,
 "A missing evolution profile must stay missing")
-- Only the lever that was changed counts.
selected("custom",{["razi-science-demand"]="light"})
local only=source.profile(spec(),resolver)
check(only.research==.8 and only.resource.frequency==1.05
 and only.evolution.time_factor==.000004,
 "A lever left at its default must not scale")
-- The rocket launch cost follows the level, with no Custom detour.
for _,row in ipairs({{"easy",.70},{"normal",1},{"hard",1.30},{"nightmare",1.65}}) do
 selected(row[1])
 check(math.abs(source.rocket_factor(resolver)-row[2])<.00001,
  "Rocket launch cost of "..row[1])
end
selected("normal",{["razi-rocket-launch-cost"]="costly"})
check(resolver.active()=="custom" and source.rocket_factor(resolver)==1.30,
 "A launch cost set by hand keeps its value")
selected("hard",{["razi-rocket-launch-cost"]="economical"})
check(source.rocket_factor(resolver)==.70,"A launch cost set by hand beats the level")
print("Resource, research, evolution and launch cost levers passed")
