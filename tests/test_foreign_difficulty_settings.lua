-- Run: texlua tests/test_foreign_difficulty_settings.lua
-- Pure-Lua mock of the prototype-stage settings view.
package.path="./?.lua;./?/init.lua;"..package.path
local M=require("prototypes.compat.foreign_difficulty_settings")
local enabled={["planet-muluna"]="1",rubia="1",["Krastorio2-spaced-out"]="1"}
local profile=M.profiles
local n=0
for name,mod in pairs(M.owners) do
 n=n+1
 assert(mod=="planet-muluna" or mod=="rubia","non-numeric source owner")
 assert(type(profile.normal[name])=="number","must be a numerical scaling setting: "..name)
 for _,mode in ipairs({"easy","normal","hard","nightmare"}) do
  assert(type(profile[mode][name])=="number",mode.." numeric mapping missing: "..name)
 end
end
assert(n==3,"Only three verified numeric source settings should be managed")
local saved={
 ["razi-difficulty-preset"]={value="hard"},
 ["kr-revert-thruster-fuel-changes"]={value=true},
 ["muluna-easy-alternative-battery-recipe"]={value=true},
 ["muluna-change-quality-science-pack-drain"]={value=false},
 ["muluna-interstellar-science-pack-dynamic-packs-required"]={value=true},
}
for name,mod in pairs(M.owners) do
 if enabled[mod] then saved[name]={value=profile.normal[name]} end
end
local function test_mode(mode)
 saved["razi-difficulty-preset"].value=mode
 local baseline={}
 for name,record in pairs(saved) do baseline[name]=record.value end
 local changed=M.apply(saved,enabled)
 assert(changed>0,"Named mode should apply numeric changes: "..mode)
 for name,value in pairs(profile[mode]) do
  assert(saved[name].value==value,mode..": "..name)
 end
 -- Non-scaling source settings must survive each preset, including K2SO.
 assert(saved["kr-revert-thruster-fuel-changes"].value==baseline["kr-revert-thruster-fuel-changes"])
 assert(saved["muluna-easy-alternative-battery-recipe"].value==baseline["muluna-easy-alternative-battery-recipe"])
 assert(saved["muluna-change-quality-science-pack-drain"].value==baseline["muluna-change-quality-science-pack-drain"])
 assert(saved["muluna-interstellar-science-pack-dynamic-packs-required"].value==baseline["muluna-interstellar-science-pack-dynamic-packs-required"])
 assert(M.apply(saved,enabled)==0,"Idempotent second apply")
 assert(M.restore()>0,"Restore player setting view")
 for name,value in pairs(baseline) do
  assert(saved[name].value==value,"Didn't restore "..name.." in "..mode)
 end
end
for _,mode in ipairs({"easy","hard","nightmare"}) do test_mode(mode) end
-- Normal is authoritative even if a player manually increased Rubia costs.
saved["rubia-tech-cost-multiplier"].value=9
test_mode("normal")
assert(saved["rubia-tech-cost-multiplier"].value==9)
saved["razi-difficulty-preset"].value="custom"
assert(M.apply(saved,enabled)==0,"Custom must not modify player settings")
assert(M.restore()==0)
saved["razi-difficulty-preset"].value="hard"
assert(M.apply(saved,{})==0,"Disabled source mods never modified")
assert(M.restore()==0)
saved["rubia-tech-cost-multiplier"].value="wrong type"
assert(M.apply(saved,{rubia="1"})==0,"Wrong type is not coerced")
assert(M.restore()==0)
-- Fail closed on immutable or unusual Factorio setting view objects.
saved["rubia-tech-cost-multiplier"]=setmetatable({},{
 __index=function(_,key) if key=="value" then return 9 end end,
 __newindex=function() error("immutable engine setting") end
})
assert(M.apply(saved,{rubia="1"})==0,"Immutable view should be skipped")
assert(M.restore()==0)
print("Three numeric foreign difficulty options; no recipe or unlock toggles: PASS")
