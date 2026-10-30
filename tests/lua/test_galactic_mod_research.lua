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

-- The real upgraded-rocket-turrets 2.1.1 identifiers: technologies
-- upgraded-rocket-<n> unlocking recipes upgraded-rocket-mk<n>, no "turret" in any of them.
local real={
 ["space-science-pack"]={prerequisites={}},
 ["planet-discovery-vulcanus"]={prerequisites={}},
 ["planet-discovery-fulgora"]={prerequisites={}},
 ["planet-discovery-aquilo"]={prerequisites={}},
 ["interplanetary-trade-logistics"]={prerequisites={"space-platform"}},
 ["space-platform"]={prerequisites={}},
 ["rocket-turret"]={prerequisites={}},
 ["upgraded-rocket-1"]={prerequisites={"rocket-turret"},effects={
    {type="unlock-recipe",recipe="upgraded-rocket-mk1"}}},
 ["upgraded-rocket-2"]={prerequisites={"upgraded-rocket-1"},effects={
    {type="unlock-recipe",recipe="upgraded-rocket-mk2"}}},
 ["upgraded-rocket-3"]={prerequisites={"upgraded-rocket-2"},effects={
    {type="unlock-recipe",recipe="upgraded-rocket-mk3"}}},
 ["upgraded-rocket-4"]={prerequisites={"upgraded-rocket-3"},effects={
    {type="unlock-recipe",recipe="upgraded-rocket-mk4"}}},
 -- not part of the source mod: must stay untouched
 ["upgraded-rocket-launcher-2"]={prerequisites={},effects={
    {type="unlock-recipe",recipe="upgraded-rocket-launcher-mk2"}}},
 ["upgraded-rocket-9"]={prerequisites={},effects={
    {type="unlock-recipe",recipe="upgraded-rocket-mk9"}}}
}
for name in pairs(techs) do techs[name]=nil end
for name,node in pairs(real) do techs[name]=node end
mod.data_final_fixes()
local function prereqs(name) return table.concat(real[name].prerequisites,",") end
local function has_real(name,id)
 for _,p in ipairs(real[name].prerequisites or {}) do
  if p==id then return true end
 end
 return false
end
check(has_real("upgraded-rocket-1","planet-discovery-vulcanus"),"Real MK1")
check(has_real("upgraded-rocket-2","planet-discovery-fulgora"),"Real MK2")
check(has_real("upgraded-rocket-3","planet-discovery-aquilo"),"Real MK3")
-- MK4 already descends from the Aquilo link of MK3: no second link
check(not has_real("upgraded-rocket-4","planet-discovery-aquilo"),"Real MK4 duplicate: "..prereqs("upgraded-rocket-4"))
check(#real["upgraded-rocket-launcher-2"].prerequisites==0,"Other upgraded-rocket tech")
check(#real["upgraded-rocket-9"].prerequisites==0,"Tier outside 1-4")
mod.data_final_fixes()
check(#real["upgraded-rocket-3"].prerequisites==2,"Real duplicate gate: "..prereqs("upgraded-rocket-3"))

print("Two new non-planet mods safely anchored to real planetary research")
