---@diagnostic disable: need-check-nil, undefined-field
-- luacheck: ignore 122
-- Paracelsin's starmap marker: the early orbit set in vibrant.lua must equal
-- the final layout position, and its label must stay clear of Vibrant's outer
-- rim marker and of Shchierbin.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end

-- Early orbit: run vibrant.lua against a recording PlanetsLib.
local updates={}
rawset(_G,"PlanetsLib",{
  extend=function() end,
  update=function(_,list)
    for _,item in ipairs(list) do updates[#updates+1]=item end
  end
})
rawset(_G,"deleteRoute",function() end)
rawset(_G,"deleteRoutesBetween",function() end)
rawset(_G,"data",{raw={},extend=function() end})
package.loaded["__space-age__.prototypes.planet.asteroid-spawn-definitions"]={
  fulgora_aquilo={},spawn_definitions=function() return {} end
}
package.loaded["util"]=package.loaded["util"] or {}
dofile("prototypes/system/vibrant.lua")
local early
for _,item in ipairs(updates) do
  if item.name=="paracelsin" then early=item.orbit end
end
check(early and early.parent.name=="vibrant",
  "vibrant.lua no longer sets Paracelsin's early orbit around Vibrant")

-- Final position: the layout owns the absolute coordinates.
local layout=require("prototypes.system.galaxy_layout")
local vx,vy=layout.anchor_position("vibrant")
local px,py=layout.anchor_position("paracelsin")
local sx,sy=layout.anchor_position("shchierbin")
check(vx and px and sx,"Layout lost the Vibrant, Paracelsin or Shchierbin anchor")
local function polar(radius,turn)
  local theta=2*math.pi*turn
  return radius*math.sin(theta),-radius*math.cos(theta)
end
local ex,ey=polar(early.distance,early.orientation)
check(math.abs((vx+ex)-px)<1e-6 and math.abs((vy+ey)-py)<1e-6,
  "Paracelsin's early orbit and final layout position disagree")
check(math.abs(early.distance-51)<1e-9 and math.abs(early.orientation-0.65)<1e-9,
  "Paracelsin must sit at radius 51, turn 0.65 around Vibrant")

-- Outer Rim marker, taken from the belt integration's own coordinates.
local belt=require("prototypes.system.asteroid_belt_integration")
local rim
for _,entry in ipairs(belt.coords) do
  if entry[1]=="asteroid-belt-outer-edge" then rim=entry end
end
check(rim,"Outer Rim marker missing from the belt integration")
local rx,ry=polar(rim[2],rim[3])
local qx,qy=px-vx,py-vy
-- The old 0.70 bearing left a one-unit vertical gap and the captions overlapped.
check(qy-ry>12,"Paracelsin's caption shares a baseline with the Outer Rim")
check(early.distance-rim[2]>10,"Paracelsin is too close to the Outer Rim radius")
check(math.sqrt((qx-rx)^2+(qy-ry)^2)>14,
  "Paracelsin's marker crowds the Outer Rim marker")
check(math.sqrt((px-sx)^2+(py-sy)^2)>18,
  "Paracelsin's marker crowds Shchierbin")
print("Paracelsin starmap placement passed")
