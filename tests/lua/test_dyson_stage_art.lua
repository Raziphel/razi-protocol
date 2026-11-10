---@diagnostic disable: undefined-field
-- The Calidus build portrait atlas provides 7 indexed research phases
-- and five legacy sprite aliases for previously published GUI names.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(v,msg) if not v then error(msg,2) end end
local seen={}
rawset(_G,"data",{extend=function(_,all)
  for _,sprite in ipairs(all) do
    check(not seen[sprite.name],"Dyson sprite registered twice")
    seen[sprite.name]=sprite
  end
end})
require("prototypes.ui.dyson_stages")
for i=0,6 do
  local sprite=assert(seen["razi-dyson-works-stage-"..i],
    "Dyson stage crop missing: "..i)
  check(sprite and sprite.type=="sprite" and sprite.x==256*i,
    "Dyson stage crop missing: "..i)
  check(sprite.filename:find("calidus-dyson-stages.png",1,true)
    and sprite.size==256 and sprite.scale==.5,
    "Dyson portraits must reuse cropped 256px atlas")
end
for _,name in ipairs({"survey","plasma","construction",
  "distribution","mastery"}) do
  check(seen["razi-dyson-works-"..name]~=nil,
    "Legacy Dyson GUI sprite alias missing: "..name)
end
local n=0
for _ in pairs(seen) do n=n+1 end
check(n==12,"Unexpected Dyson stage sprite count")
print("Seven research stage Dyson portraits and legacy aliases passed")
