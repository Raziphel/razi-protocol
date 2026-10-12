package.path="./?.lua;./?/init.lua;"..package.path
local function check(x,msg) if not x then error(msg,2) end end
local r=require("prototypes.technology.tech_tree_visibility")
local techs={
 ["solaris-discovery"]={order="original"},
 ["razi-outer-frontier-mastery"]={order="original"},
 ["native-planet-tech"]={order="native"},
 ["razi-umbra-belt-survey"]={enabled=false,order="original"}
}
rawset(_G,"data",{raw={technology=techs}})
r.data_final_fixes()
check(techs["solaris-discovery"].essential,"Star discovery not essential")
check(techs["razi-outer-frontier-mastery"].essential,"Finale entry not essential")
check(techs["native-planet-tech"].order=="native" and
 not techs["native-planet-tech"].essential,"Source research was rewritten")
check(techs["razi-umbra-belt-survey"].order=="original" and
 not techs["razi-umbra-belt-survey"].essential,"Disabled tech changed")
check(#r.chapters==13,"Missing a major campaign research node")
print("Native essential-research view includes Razi milestones")
