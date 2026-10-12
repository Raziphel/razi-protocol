-- Original five Stellar Works research illustrations, no external assets.
package.path="./?.lua;./?/init.lua;"..package.path
local function ok(value,msg) if not value then error(msg,2) end end
local sprites={}
rawset(_G,"data",{extend=function(_,group)
  for _,sprite in ipairs(group) do
    ok(not sprites[sprite.name],"Duplicate UI portrait")
    sprites[sprite.name]=sprite
  end
end})
require("prototypes.ui.dyson_stages")
local expected={"survey","plasma","construction","distribution","mastery"}
local count=0
for _,name in ipairs(expected) do
  local key="razi-dyson-works-"..name
  local sprite=sprites[key]
  ok(sprite and sprite.type=="sprite","Missing "..key)
  ok(sprite.scale==0.25 and sprite.size==512,"Portrait loads at full size")
  ok(sprite.filename:find("graphics/starmap/razi/",1,true),
    "Unexpected external art file")
  count=count+1
end
local total=0
for _ in pairs(sprites) do total=total+1 end
ok(total==count,"Unexpected new media prototypes")
print("Original art research portraits registered safely")
