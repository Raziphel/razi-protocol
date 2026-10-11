-- Razi-owned expedition guides. Tint comes from final actual route asteroids.
-- Static transparent PNG masks avoid runtime render objects, tick work and
-- rewriting any real space-connection prototypes.
local M = {}
local manifest = require("prototypes.system.route_highlight_manifest")
local colors = {
  {r=0.27,g=0.83,b=0.65}, -- relatively calm
  {r=0.90,g=0.73,b=0.34}, -- growing danger
  {r=1.00,g=0.45,b=0.28}, -- advanced asteroid hazard
  {r=0.77,g=0.49,b=0.97}  -- final/belt crossing
}
local tier_floor = {first=1,middle=2,outer=3,belt=4,["belt-approach"]=2}

local function key(a,b)
  if a>b then a,b=b,a end
  return a.."|"..b
end
local function current_position(name)
  local location=(data.raw.planet or {})[name]
    or (data.raw["space-location"] or {})[name]
  if not location then return end
  local origin=location.origin or {}
  local r=location.distance
  if r==nil and location.orbit then r=location.orbit.distance end
  local orientation=location.orientation
  if orientation==nil and location.orbit then
    orientation=location.orbit.orientation
  end
  if type(r)~="number" or type(orientation)~="number" then return end
  local radians=2*math.pi*orientation
  return {(origin.x or origin[1] or 0)+r*math.sin(radians),
          (origin.y or origin[2] or 0)-r*math.cos(radians)}
end

-- The difficulty grade is a floor from the planned expedition chapter,
-- raised when other mods introduce big or huge asteroids. We do not adjust
-- the actual spawn values, and unknown modded asteroids stay source-owned.
local function danger_grade(route,kind)
  local result=tier_floor[kind] or 1
  local huge,big,medium=0,0,0
  for _,def in ipairs(route.asteroid_spawn_definitions or {}) do
    local name=def.asteroid
    if type(name)=="string" then
      local maximum=0
      for _,point in ipairs(def.spawn_points or {}) do
        if type(point.probability)=="number" then
          maximum=math.max(maximum,point.probability)
        end
      end
      if name:find("^huge%-") then huge=huge+maximum
      elseif name:find("^big%-") then big=big+maximum
      elseif name:find("^medium%-") then medium=medium+maximum end
    end
  end
  if huge>0.001 then result=math.max(result,4)
  elseif big>0.025 or medium>0.16 then result=math.max(result,3)
  elseif big>0 or medium>0.04 then result=math.max(result,2) end
  return result
end

function M.data_final_fixes()
  local option=settings and settings.startup
    and settings.startup["razi-route-highlight-style"]
  local mode=option and option.value or "subtle"
  if mode=="off" then return end
  if mods and mods["space-route-overlay"] then return end
  local utilities=(data.raw["utility-sprites"] or {}).default
  local art=utilities and utilities.starmap_star
  if not (art and art.layers) then return end

  local connections={}
  for _,route in pairs(data.raw["space-connection"] or {}) do
    if route.from and route.to then
      connections[key(route.from,route.to)]=route
    end
  end
  local count,skipped=0,0
  for _,item in ipairs(manifest) do
    local connection=connections[key(item.from,item.to)]
    local p,q=current_position(item.from),current_position(item.to)
    local aligned=p and q
      and math.abs(p[1]-item.start[1])<1.5
      and math.abs(p[2]-item.start[2])<1.5
      and math.abs(q[1]-item.finish[1])<1.5
      and math.abs(q[2]-item.finish[2])<1.5
    -- Ordinary Factorio arcs cannot be reproduced perfectly as bitmaps.
    -- For the subtle mode skip the long curving approach altogether.
    local appropriate=connection and (connection.shape=="line"
       or item.kind=="belt" or (item.kind=="belt-approach" and mode=="clear"))
    if aligned and appropriate then
      local c=colors[danger_grade(connection,item.kind)]
      art.layers[#art.layers+1]={
        type="sprite",filename=item.filename,size=item.size,
        shift=item.shift,scale=4,priority="extra-high-no-scale",
        flags={"gui-icon"},blend_mode="normal",
        tint={r=c.r,g=c.g,b=c.b,a=mode=="clear" and 0.63 or 0.34}
      }
      count=count+1
    else skipped=skipped+1 end
  end
  if type(log)=="function" then
    log("[Razi Protocol/route-highlights] guides "..count..
      " rendered; "..skipped.." skipped (arc, missing or relocated)")
  end
end

M.danger_grade=danger_grade
return M
