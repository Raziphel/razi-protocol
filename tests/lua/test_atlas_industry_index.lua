-- Read-only Atlas industry reverse index: one scan of immutable
-- prototypes, regardless of how many destinations the player inspects.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(value,msg) if not value then error(msg,2) end end
package.loaded["scripts.razi_nexus_trials"]={}
package.loaded["scripts.razi_weather_guide"]={}
package.loaded["scripts.razi_convergence"]={}
rawset(_G,"prototypes",{technology={
 ["razi-omega"]={name="razi-omega",hidden=false,
   prerequisites={["discovery-a"]={},["discovery-b"]={}}},
 ["razi-alpha"]={name="razi-alpha",hidden=false,
   prerequisites={["discovery-a"]={}}},
 ["razi-hidden"]={name="razi-hidden",hidden=true,
   prerequisites={["discovery-a"]={}}},
 ["native-technology"]={name="native-technology",hidden=false,
   prerequisites={["discovery-a"]={}}}
}})
local atlas=require("scripts.galactic_atlas")
local force={technologies={
 ["razi-alpha"]={name="razi-alpha",researched=false,
  prototype={hidden=false}},
 ["razi-omega"]={name="razi-omega",researched=true,
  prototype={hidden=false}}
}}
local research={{tech={name="discovery-a"}},
 {tech={name="discovery-b"}}}
local list=atlas.related_industries(force,research)
check(#list==2 and list[1].name=="razi-alpha"
 and list[2].name=="razi-omega",
 "Index must avoid duplicate links and preserve alphabetic listing")
prototypes.technology["razi-later"]={
 name="razi-later",hidden=false,prerequisites={["discovery-a"]={}}
}
local second=atlas.related_industries(force,research)
check(#second==2,
 "Repeated Atlas requests must use the cached index, not rescan techs")
force.technologies["razi-alpha"].prototype.hidden=true
local visible=atlas.related_industries(force,research)
check(#visible==1 and visible[1].name=="razi-omega",
 "Live force visibility must still override immutable prototype index")
check(#atlas.related_industries(force,{{tech={name="unknown"}}})==0,
 "Unknown planets should never receive fabricated exchange links")
print("Atlas: reverse industry index, deduplication, sorting and live visibility passed")
