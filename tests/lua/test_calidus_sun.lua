-- Preserve Factorio's stellar gameplay while replacing the static map art.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(value,msg) if not value then error(msg,2) end end
rawset(_G,"data",{raw={["space-location"]={star={
  name="star",starmap_icon="__core__/graphics/icons/starmap-star.png",
  starmap_icon_size=512,origin={x=0,y=0},distance=0,
  orientation=0,magnitude=8,solar_power_in_space=100
}}}})
local sun=require("prototypes.system.calidus_sun")
check(sun.data_updates(),"Calidus central star was not updated")
local star=data.raw["space-location"].star
check(star.starmap_icon=="__razi-protocol__/graphics/icons/CalidusStar.png"
  and star.starmap_icon_size==1024,"New golden star art is missing")
check(star.magnitude==8 and star.distance==0 and star.orientation==0
  and star.origin.x==0 and star.origin.y==0
  and star.solar_power_in_space==100,
  "Cosmetic sun upgrade modified gameplay or star coordinates")
check(sun.data_updates(),"Sun art update is not idempotent")
data.raw["space-location"].star=nil
check(not sun.data_updates(),"Missing third-party star should fail safely")
print("Static Calidus sun artwork and fallback passed")
