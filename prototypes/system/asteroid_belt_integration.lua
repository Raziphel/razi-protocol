---@diagnostic disable: inject-field
-- Map coordinates of Vibrant's belt rims: both stay on the western edge of the system.
local M={}
local HOST="vibrant"
local coords={
  {"asteroid-belt-inner-edge",31,0.77},
  {"asteroid-belt-outer-edge",39,0.775}
}
M.coords=coords
function M.data_final_fixes()
  local layout=require("prototypes.system.galaxy_layout")
  local cx,cy=layout.anchor_position(HOST)
  if not cx or not cy then return end
  for _,entry in ipairs(coords) do
    local location=(data.raw["space-location"] or {})[entry[1]]
    if location then
      local radians=entry[3]*2*math.pi
      local x=cx+entry[2]*math.sin(radians)
      local y=cy-entry[2]*math.cos(radians)
      if x>=cx or x<0 or math.abs(y-cy)>10 then
        error("Razi: Vibrant belt entries are no longer on the western rim")
      end
      local distance=math.sqrt(x*x+y*y)
      local turn=0.25-math.atan(-y/x)/(2*math.pi)
      location.orbit={parent={type="space-location",name="star"},
        distance=distance,orientation=turn}
      location.origin={x=0,y=0}
      location.distance=distance
      location.orientation=turn
      location.draw_orbit=false
    end
  end
end
return M
