-- Run from the Razi Protocol repository root:
--   texlua tests/razi_map_preset_selection.lua
-- Stubs are deliberately tiny; this checks default ownership and selection
-- without loading the enormous production mod pack.
local function profile(mode,profiles) return profiles[mode] or profiles.normal end
local fake_settings={startup={
  ["razi-difficulty-preset"]={value="normal"},
  ["razi-default-new-game-map"]={value=true}
}}
settings=fake_settings
local difficulty={
  selected=function() return settings.startup["razi-difficulty-preset"].value end
}
package.loaded["scripts.razi_difficulty_presets"]=difficulty
package.loaded["scripts.razi_difficulty_tuning"]={
  profile=function(mode,profiles) return profile(mode,profiles) end,
  pollution=function() end,unit_groups=function() end
}
package.loaded["scripts.razi_economy_difficulty"]={
  profile=function(_,spec) return spec end
}
local gen=require("prototypes.system.razi_map_preset")
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
     assert(p.basic_settings==nil and p.advanced_settings==nil,
       "default-selected preset has forbidden generation controls")
   end
 end
 assert(count==1,"expected exactly one default, found "..tostring(count))
 return key
end
for _,mode in ipairs({"easy","normal","hard","nightmare","custom"}) do
 for _,enabled in ipairs({true,false}) do
  settings.startup["razi-difficulty-preset"].value=mode
  settings.startup["razi-default-new-game-map"].value=enabled
  local group=fixture()
  data={raw={
    ["map-gen-presets"]={default=group},
    ["autoplace-control"]={},
    ["map-settings"]={},
    planet={}
  }}
  assert(gen.data_final_fixes())
  assert(gen.data_final_fixes(),"second pass should be idempotent")
  local expected=enabled and "razi-protocol-"..mode or "other_mod"
  -- With automatic Razi selection disabled, preserve the existing single
  -- valid third-party default and its separate editable profile.
  if enabled then
    assert(selected(group)==expected,mode.." not auto-selected")
  else
    assert(group.other_mod.default==true and group.default.default~=true,
      "disabled option must not change foreign default flags")
    assert(group["razi-protocol-"..mode]==nil or
      group["razi-protocol-"..mode].default~=true,
      "disabled option must not select Razi")
  end
  for _,named in ipairs({"easy","normal","hard","nightmare"}) do
   local id="razi-protocol-"..named
   assert(group[id],"missing manual preset "..named)
   if not enabled or named~=mode then
     assert(group[id].basic_settings and group[id].advanced_settings,
       "other manually selectable profile lost its worldgen settings")
   end
  end
  assert(group.other_mod_profile.basic_settings.starting_area==4,
    "must preserve another mod's profile settings")
 end
end
print("Razi New Game difficulty preset selection: OK")
