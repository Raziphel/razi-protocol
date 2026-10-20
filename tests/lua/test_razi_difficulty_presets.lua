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
check(difficulty.selected()=="nightmare",
 "Underlying selected Nightmare must survive effective Custom")
check(difficulty.effective("razi-nexus-hostility")=="apocalypse",
 "Manual density adjustment must not reset Nightmare Nexus")
check(difficulty.effective("razi-rocket-launch-cost")=="punishing",
 "Manual enemy change must not reset Nightmare rockets")
check(difficulty.effective("razi-habitat-cold-biters")=="all",
 "Manual enemy change must not reset other Nightmare habitat tiers")
check(difficulty.effective("razi-science-demand")=="grueling",
 "Manual enemy change must not reset Nightmare science")
select("hard")
settings.startup["razi-helios-convergence-proof"].value=true
check(difficulty.effective("razi-factory-throughput")=="constrained",
 "Hard factories must stay Hard when a structural switch is changed")
check(difficulty.active()=="custom",
 "Manual structural finale option must resolve Custom without erasing it")
check(difficulty.effective("razi-helios-convergence-proof")==true,
 "Manual Convergence requirement must survive Custom")
select("normal")
settings.startup["razi-big-monsters-events"].value=true
check(difficulty.active()=="custom","Manual Big-Monsters choice must be Custom")
select("custom")
check(difficulty.selected()=="custom",
 "The actual Custom dropdown must not silently resolve to Normal")
check(difficulty.active()=="custom","Explicit Custom must be retained")
check(difficulty.effective("razi-enemy-pressure")=="normal",
 "Explicit Custom uses player-owned baseline settings")
check(difficulty.effective("razi-habitat-toxic-biters")=="auto",
 "Explicit Custom preserves the saved Follow difficulty setting")
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
check(count==31,"All 31 managed gameplay levers must be mapped")
print("Five modes, source monster activation, manual overrides and safety passed")
