-- Run: texlua tests/test_foreign_difficulty_settings.lua
-- Native-stage fixture; Factorio startup tests remain required.
package.path="./?.lua;./?/init.lua;"..package.path
local M=require("prototypes.compat.foreign_difficulty_settings")
local enabled={["planet-muluna"]="1",rubia="1",["Krastorio2-spaced-out"]="1"}
local saved={["razi-difficulty-preset"]={value="hard"}}
for name,mod in pairs(M.owners) do
 if enabled[mod] then saved[name]={value=M.profiles.normal[name]} end
end
local original={}
for name,v in pairs(saved) do original[name]=v.value end
assert(M.apply(saved,enabled)>0,"Hard should replace real source setting values")
for name,value in pairs(M.profiles.hard) do
 assert(saved[name].value==value,"Hard "..name)
end
assert(M.apply(saved,enabled)==0,"No duplicate write")
assert(M.restore()>0,"Restore originals after source data passes")
for name,value in pairs(original) do
 assert(saved[name].value==value,"Restore "..name)
end
saved["razi-difficulty-preset"].value="nightmare"
assert(M.apply(saved,enabled)>0)
assert(saved["rubia-tech-cost-multiplier"].value==3)
assert(M.restore()>0)
saved["razi-difficulty-preset"].value="custom"
assert(M.apply(saved,enabled)==0,"Custom must not touch source selections")
assert(M.restore()==0)
-- Explicit manual preferences DO NOT win against the named mode.
saved["razi-difficulty-preset"].value="easy"
saved["rubia-tech-cost-multiplier"].value=10
assert(M.apply(saved,enabled)>0)
assert(saved["rubia-tech-cost-multiplier"].value==1)
assert(M.restore()>0)
assert(saved["rubia-tech-cost-multiplier"].value==10)
-- Missing source mods never allow incidental collision with the setting ID.
saved["razi-difficulty-preset"].value="hard"
local count=M.apply(saved,{})
assert(count==0,"missing mods not changed")
assert(M.restore()==0)
-- No unsupported type coercion.
saved["rubia-tech-cost-multiplier"].value="not numeric"
assert(M.apply(saved,{rubia="1"})==0)
assert(M.restore()==0)
print("Foreign difficulty source setting stage shim: PASS")
