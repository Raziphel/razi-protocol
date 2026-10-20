package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
local resolver=require("scripts.razi_difficulty_presets")
local function load(preset)
 rawset(_G,"settings",{startup={
  ["razi-difficulty-preset"]={value=preset},
  ["razi-asteroid-population"]={value="swarm"},
  ["razi-asteroid-difficulty-scale"]={value="relentless"},
  ["razi-belt-threats"]={value="severe"},
  ["razi-helios-route-distance"]={value="native"},
  ["razi-helios-convergence-proof"]={value=true},
  ["razi-performance-weapon-particles"]={value=false}
 }})
end
load("custom")
check(resolver.active()=="custom","Existing maps must default to Custom")
check(resolver.effective("razi-asteroid-population","standard")=="swarm",
 "Custom must honor a previously selected advanced value")
check(resolver.effective("razi-helios-route-distance","extended")=="native",
 "Custom must not silently change a solar route")
load("relaxed")
check(resolver.effective("razi-asteroid-population","standard")=="sparse",
 "Relaxed should reduce asteroid density")
check(resolver.effective("razi-helios-coronal-surges","occasional")=="off",
 "Relaxed mode must allow uninterrupted commissioning")
load("standard")
check(resolver.effective("razi-asteroid-population","sparse")=="standard",
 "Standard must use intended density")
check(resolver.effective("razi-helios-route-danger","native")=="extreme",
 "Standard should preserve existing deadly Calidus travel")
load("hard")
check(resolver.effective("razi-asteroid-difficulty-scale","balanced")=="challenging",
 "Hard must raise asteroid quality")
check(resolver.effective("razi-helios-commissioning","expedition")=="monumental",
 "Hard should require the substantial physical HELIOS expedition")
load("extreme")
check(resolver.effective("razi-asteroid-population","swarm")=="dense",
 "Extreme must avoid performance-heavy swarm asteroid population")
check(resolver.effective("razi-helios-progression","late")=="epic",
 "Extreme should gate stellar travel behind outer systems")
check(resolver.effective("razi-helios-convergence-proof",false)==true,
 "Unmanaged victory gates must remain user-controlled")
check(resolver.effective("razi-performance-weapon-particles",true)==false,
 "Unmanaged performance settings must remain untouched")
load("invalid-value")
check(resolver.active()=="custom","Unknown preset falls back safely")
load(nil)
settings.startup["razi-difficulty-preset"]=nil
check(resolver.active()=="custom","Old saves without master preset must be Custom")
local expected={}
for _,key in ipairs(resolver.managed) do
 check(not expected[key],"Duplicated managed setting: "..key)
 expected[key]=true
 for name,mapping in pairs(resolver.presets) do
  check(mapping[key]~=nil,"Preset "..name.." lacks "..key)
 end
end
print("Razi master difficulty: Custom isolation, 4 presets and 9 managed levers passed")
