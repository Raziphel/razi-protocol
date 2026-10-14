package.path="./?.lua;./?/init.lua;"..package.path
local function check(x,msg) if not x then error(msg,2) end end
local r=require("prototypes.technology.tech_tree_visibility")
local techs={
 ["solaris-discovery"]={order="original"},
 ["razi-outer-frontier-mastery"]={order="original"},
 ["native-planet-tech"]={order="native"},
 ["native-cerys-discovery"]={order="native-cerys",effects={{
    type="unlock-space-location",space_location="cerys"}}},
 ["unrelated-source-discovery"]={order="unrelated",effects={{
    type="unlock-space-location",space_location="unlisted-mod-world"}}},
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
check(techs["native-cerys-discovery"].essential
 and techs["native-cerys-discovery"].order=="native-cerys",
 "Installed Cerys should be visible in the essential native research tree")
check(not techs["unrelated-source-discovery"].essential
 and techs["unrelated-source-discovery"].order=="unrelated",
 "Unlisted source tech must retain original prototype flags")
check(#r.chapters==17 and #r.chapter_groups==5,
 "Missing first/middle/outer/deep/convergence research chapters")
check(techs["solaris-discovery"].order=="f[razi-campaign]-a[first-frontier]-01",
 "First frontier should be a compact, identifiable research group")
check(techs["razi-outer-frontier-mastery"].order==
 "f[razi-campaign]-c[outer-frontier]-04",
 "Outer mastery should appear after its outer-system survey")
check(techs["native-planet-tech"].order=="native",
 "Native research ordering changed unexpectedly")
print("Native essential-research view includes Razi milestones")
