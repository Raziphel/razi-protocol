---@diagnostic disable: need-check-nil, undefined-field, missing-fields
-- New Game list: Factorio's default=true entries cannot include settings.
-- Only baseline Normal/Custom get default markers. Non-baseline modes keep
-- complete, selectable profiles, and repeated passes must be idempotent.
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
  package.loaded["lib.difficulty.presets"]=nil
  package.loaded["prototypes.difficulty.razi_map_preset"]=nil
  local gen=require("prototypes.difficulty.razi_map_preset")
  local group=fixture()
  rawset(_G,"data",{raw={
    ["map-gen-presets"]={default=group},
    ["autoplace-control"]={},
    ["map-settings"]={},
    planet={}
  }})
  check(gen.data_final_fixes(),"first pass failed")
  check(gen.data_final_fixes(),"second pass should be idempotent")
  if enabled and (mode=="normal" or mode=="custom") then
    check(selected(group)=="razi-protocol-"..mode,
      mode.." should use a legal baseline default marker")
    check(group.other_mod.default==nil and group.other_mod_profile
      .basic_settings.starting_area==4,
      "another mod's preset must stay listed")
  else
    -- The real Easy/Hard/Nightmare profiles must NOT lose their map values
    -- to a default marker. A user explicitly picks one in New Game.
    check(selected(group)=="other_mod",
      mode.." must leave the actual default selectable")
    check(group["razi-protocol-"..mode] and
      group["razi-protocol-"..mode].default~=true,
      mode.." cannot be a blank default marker")
  end
  for _,named in ipairs(gen.modes) do
   local id="razi-protocol-"..named
   check(group[id],"missing manual preset "..named)
   if not enabled or named~=mode or (mode~="normal" and mode~="custom") then
     check(group[id].basic_settings and group[id].advanced_settings,
       "manually selectable profile lost its worldgen settings")
   end
   if named=="hard" or named=="nightmare" then
     local preset=group[id]
     check(preset.basic_settings and preset.advanced_settings,
       "Hard and Nightmare must never lose their map settings")
      -- The preset must carry actual map settings, not merely its name.
     check(preset.basic_settings.starting_area
       ==(named=="nightmare" and .90 or 1.15),
       named.." starting area disappeared")
     check(preset.advanced_settings.difficulty_settings
       .technology_price_multiplier==(named=="nightmare" and 1.75 or 1.25),
       named.." research price disappeared")
   end
  end
 end
end
print("New Game map preset selection: OK")
