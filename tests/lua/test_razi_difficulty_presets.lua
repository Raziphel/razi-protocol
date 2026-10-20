-- Difficulty preset and manual-override regression.
package.path="./?.lua;./?/init.lua;"..package.path
local difficulty=require("scripts.razi_difficulty_presets")
local defaults=difficulty.baseline
local function select(mode)
 local startup={["razi-difficulty-preset"]={value=mode}}
 for name,value in pairs(defaults) do
  startup[name]={value=value}
 end
 rawset(_G,"settings",{startup=startup})
end
local function check(test,message) if not test then error(message,2) end end
select("normal")
check(difficulty.active()=="normal","Normal must be the default")
-- The source dropdown keeps old user-selected Custom values until changed.
-- Never rewrite existing startup settings while presenting a new default.
check(not difficulty.effective("razi-big-monsters-events",true),
 "Normal should not enable Big-Monsters events")
select("easy")
check(difficulty.active()=="easy","Easy selected but not effective")
check(difficulty.effective("razi-enemy-pressure")=="light",
 "Easy should scale back hostile nests")
select("hard")
check(difficulty.active()=="hard","Hard selected but falsely custom")
check(difficulty.effective("razi-big-monsters-events")==true,
 "Hard must re-enable source monster events")
check(difficulty.effective("razi-planetary-interdependence")=="deep",
 "Hard must increase actual cross-world logistics")
select("nightmare")
check(difficulty.active()=="nightmare","Nightmare not selected")
check(difficulty.effective("razi-nexus-hostility")=="apocalypse",
 "Nightmare must make Nexus the apex ecosystem")
check(difficulty.effective("razi-asteroid-population")=="dense",
 "Nightmare must never force excessive Swarm UPS")
settings.startup["razi-enemy-pressure"].value="light"
check(difficulty.active()=="custom","Manual gameplay change must resolve Custom")
check(difficulty.effective("razi-enemy-pressure")=="light",
 "Manual value must override a previously selected preset")
check(#difficulty.manual_overrides()==1,"Manual change detection inflated")
select("hard")
settings.startup["razi-helios-convergence-proof"].value=true
check(difficulty.active()=="custom",
 "Manual structural finale option must resolve Custom without erasing it")
check(difficulty.effective("razi-helios-convergence-proof")==true,
 "Manual Convergence requirement must survive Custom")
select("normal")
settings.startup["razi-big-monsters-events"].value=true
check(difficulty.active()=="custom","Manual Big-Monsters choice must be Custom")
select("custom")
check(difficulty.active()=="custom","Explicit Custom must be retained")
select("normal")
check(difficulty.effective("razi-route-visibility","bright")=="bright",
 "Cosmetic settings must not be touched")
local count=0
for _,key in ipairs(difficulty.managed) do
 check(defaults[key]~=nil,"Missing baseline for managed control "..key)
 count=count+1
 for name,preset in pairs(difficulty.presets) do
  check(preset[key]~=nil,"Missing "..key.." in "..name)
 end
end
check(count==25,"All 25 managed gameplay levers must be mapped")
print("Five modes, source monster activation, manual overrides and safety passed")
