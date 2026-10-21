-- Native owner-API integration regression, no Factorio executable required.
-- Run: texlua tests/test_big_monsters_level_bridge.lua
package.path="./?.lua;./?/init.lua;"..package.path

-- Stub only the Razi preset reader, not the source's own Map setting.
local mode="normal"
package.loaded["scripts.razi_difficulty_presets"]={
 selected=function() return mode end,
 active=function() return mode end,
 effective=function(name,fallback) return fallback end,
}
local calls={}
remote={
 interfaces={bigmonster={set_difficulty_level=true}},
 call=function(owner,method,level)
  calls[#calls+1]={owner=owner,method=method,level=level}
 end
}
script={active_mods={["Big-Monsters"]="2.2.1"}}
local bridge=require("scripts.razi_big_monsters_bridge")
local function apply(selected)
 mode=selected
 calls={}
 bridge.sync()
 return calls
end

assert(bridge.target_level()==nil,"Normal cannot select source difficulty")
assert(#apply("normal")==0)
assert(#apply("easy")==0)
assert(#apply("custom")==0)
assert(bridge.target_level()==nil)
local hard=apply("hard")
assert(bridge.target_level()==5)
assert(#hard==1 and hard[1].owner=="bigmonster"
 and hard[1].method=="set_difficulty_level"
 and hard[1].level==5)
local nightmare=apply("nightmare")
assert(bridge.target_level()==7)
assert(#nightmare==1 and nightmare[1].level==7)

-- A source version without a difficulty setter must fail closed and NOT
-- spawn extra waves, edit foreign saved settings or crash at load time.
remote.interfaces.bigmonster={create_event=true,add_surface=true}
assert(#apply("hard")==0,"Missing owner API cannot fake native difficulty")
remote.interfaces.bigmonster=nil
assert(#apply("nightmare")==0)
remote.interfaces.bigmonster={set_difficulty_level=true}
script.active_mods={}
assert(#apply("hard")==0,"Missing Big Monsters does nothing")
print("Big Monsters native 5/7 bridge contract: PASS")
