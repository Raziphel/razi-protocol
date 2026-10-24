---@diagnostic disable: need-check-nil, undefined-field, missing-fields
-- New Game list: exactly one default, the active level is the marker, the
-- other profiles stay editable, other mods' presets are kept, and a second
-- pass changes nothing.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
local function fixture()
 return {
   ["type"]="map-gen-presets",name="default",
   default={order="a"},
   other_mod={default=true,order="b"},
   other_mod_profile={order="c",basic_settings={starting_area=4}},
   ["razi-protocol-hard"]={order="z"}
 }
end
local function selected(group)
 local key,count
 for id,p in pairs(group) do
   if type(p)=="table" and p.default==true then
     key=id
     count=(count or 0)+1
     check(p.basic_settings==nil and p.advanced_settings==nil,
       "default-selected preset has forbidden generation controls")
   end
 end
 check(count==1,"expected exactly one default, found "..tostring(count))
 return key
end
for _,mode in ipairs({"easy","normal","hard","nightmare","custom"}) do
 for _,enabled in ipairs({true,false}) do
  rawset(_G,"settings",{startup={
   ["razi-difficulty-preset"]={value=mode},
   ["razi-default-new-game-map"]={value=enabled}}})
  package.loaded["scripts.razi_difficulty_presets"]=nil
  package.loaded["prototypes.system.razi_map_preset"]=nil
  local gen=require("prototypes.system.razi_map_preset")
  local group=fixture()
  rawset(_G,"data",{raw={
    ["map-gen-presets"]={default=group},
    ["autoplace-control"]={},
    ["map-settings"]={},
    planet={}
  }})
  check(gen.data_final_fixes(),"first pass failed")
  check(gen.data_final_fixes(),"second pass should be idempotent")
  if enabled then
    check(selected(group)=="razi-protocol-"..mode,mode.." not auto-selected")
    check(group.other_mod.default==nil and group.other_mod_profile
      .basic_settings.starting_area==4,
      "another mod's preset must stay listed")
  else
    -- Nothing is claimed: the single valid third-party default stays.
    check(selected(group)=="other_mod","disabled option must not change foreign default flags")
    check(group["razi-protocol-"..mode]==nil or
      group["razi-protocol-"..mode].default~=true,
      "disabled option must not select Razi")
  end
  for _,named in ipairs(gen.modes) do
   local id="razi-protocol-"..named
   check(group[id],"missing manual preset "..named)
   if not enabled or named~=mode then
     check(group[id].basic_settings and group[id].advanced_settings,
       "other manually selectable profile lost its worldgen settings")
   end
  end
 end
end
print("New Game map preset selection: OK")
