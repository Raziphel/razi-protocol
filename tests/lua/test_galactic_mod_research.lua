-- Pure Lua verification for native source technology gate integration.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(x,msg) if not x then error(msg,2) end end
local techs={
 ["space-science-pack"]={prerequisites={}},
 ["planet-discovery-vulcanus"]={prerequisites={}},
 ["planet-discovery-fulgora"]={prerequisites={}},
 ["planet-discovery-aquilo"]={prerequisites={}},
 ["interplanetary-trade-logistics"]={prerequisites={"space-platform"}},
 ["space-platform"]={prerequisites={}},
 ["rocket-turret-mk1-research"]={prerequisites={},effects={
    {type="unlock-recipe",recipe="rocket-turret-mk1"}}},
 ["rocket-turret-mk2-research"]={prerequisites={},effects={
    {type="unlock-recipe",recipe="rocket-turret-mk2"}}},
 ["rocket-turret-mk3-research"]={prerequisites={},effects={
    {type="unlock-recipe",recipe="rocket-turret-mk3"}}},
 ["rocket-turret-mk4-research"]={prerequisites={},effects={
    {type="unlock-recipe",recipe="rocket-turret-mk4"}}}
}
rawset(_G,"data",{raw={technology=techs}})
rawset(_G,"mods",{["planet-express"]=true,["upgraded-rocket-turrets"]=true})
local mod=require("prototypes.technology.galactic_mod_research")
local function has(name,id)
 for _,p in ipairs(techs[name].prerequisites or {}) do
  if p==id then return true end
 end
 return false
end
mod.data_final_fixes()
check(has("interplanetary-trade-logistics","space-science-pack"),"Trade anchor")
check(has("rocket-turret-mk1-research","planet-discovery-vulcanus"),"MK1")
check(has("rocket-turret-mk2-research","planet-discovery-fulgora"),"MK2")
check(has("rocket-turret-mk3-research","planet-discovery-aquilo"),"MK3")
check(has("rocket-turret-mk4-research","planet-discovery-aquilo"),"MK4")
mod.data_final_fixes()
check(#techs["rocket-turret-mk4-research"].prerequisites==1,"Duplicate gate")
techs["another-rocket-turret-mk2"]={prerequisites={
 "interplanetary-trade-logistics"},effects={
  {type="unlock-recipe",recipe="another-rocket-turret-mk2"}}}
techs["planet-discovery-fulgora"].prerequisites={
 "another-rocket-turret-mk2"}
mod.data_final_fixes()
check(not has("another-rocket-turret-mk2","planet-discovery-fulgora"),
 "Cycle from source tech")
print("Two new non-planet mods safely anchored to real planetary research")
