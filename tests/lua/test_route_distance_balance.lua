-- Regression: a short native moon route stays short, but a moved
-- far-away native destination does not silently remain 1,000 km.
package.path="./?.lua;./?/init.lua;"..package.path
local check=function(ok,msg) if not ok then error(msg,2) end end
local planet={}
local space={}
for _,name in ipairs({"skewer_shattered_planet","vesta","cubium","secretas"}) do
  planet[name]={name=name}
end
for _,name in ipairs({"shattered-planet","skewer_lost_beyond",
    "solar-system-edge","sye-calidus","sye-solaris",
    "asteroid-belt-inner-edge","asteroid-belt-outer-edge"}) do
  space[name]={name=name}
end
local routes={
  short={name="short",from="shattered-planet",
    to="skewer_shattered_planet",length=1000},
  long={name="long",from="skewer_shattered_planet",
    to="skewer_lost_beyond",length=1000},
  outer={name="outer",from="vesta",to="solar-system-edge",
    length=1000},
  local_={name="local_",from="cubium",to="secretas",
    length=1000},
  priced={name="priced",from="sye-calidus",to="sye-solaris",
    length=60000},
  belt={name="belt",from="asteroid-belt-inner-edge",
    to="asteroid-belt-outer-edge",length=5000},
  wormhole={name="some-wormhole",from="vesta",to="solar-system-edge",
    length=1000}
}
rawset(_G,"data",{raw={planet=planet,["space-location"]=space,
  ["space-connection"]=routes}})
local M=require("prototypes.system.route_distance_balance")
check(M.minimum_for_span(19)==0,"Genuine tiny routes must remain short")
check(M.minimum_for_span(145)>=100000,"Remote route minimum too small")
local changed=M.data_final_fixes()
check(changed==3,"Expected 3 enormous native misprices, got "..changed)
check(routes.short.length==1000,
  "The short Shattered Planet approach must remain 1,000 km")
check(routes.long.length>=100000,"Lost Beyond must feel remote")
check(routes.outer.length>=100000,"Outer Deep Space journey too short")
check(routes.local_.length>=24000,"Distant orbit shuttle too short")
check(routes.priced.length==60000,"Good cross-system pricing changed")
check(routes.belt.length==5000,"Physical belt crossing altered")
check(routes.wormhole.length==1000,"Native wormhole shortened/transformed")
check(M.data_final_fixes()==0,"Repricing is not idempotent")
print("Native starmap route distance calibration passed")
