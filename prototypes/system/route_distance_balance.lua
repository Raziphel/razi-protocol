-- Factorio route.length is travel km, not literal interstellar
-- astronomy. Visual chart coordinates are a stylized projection.
-- Reprice only grossly underpriced RETAINED routes with known endpoints.
local M={}
local layout=require("prototypes.system.galaxy_layout")
local function pos(name,seen)
  if name=="star" then return 0,0 end
  local x,y=layout.anchor_position(name)
  if x then return x,y end
  local raw=data and data.raw or {}
  local body=(raw.planet or {})[name] or (raw["space-location"] or {})[name]
  if not body then return nil end
  seen=seen or {}
  if seen[name] then return nil end
  seen[name]=true
  local orbit=body.orbit
  local origin=body.origin
  local ox,oy
  if type(origin)=="table" then
    ox,oy=origin.x or origin[1],origin.y or origin[2]
  end
  if type(ox)~="number" or type(oy)~="number" then ox,oy=nil,nil end
  if not ox and orbit and orbit.parent and orbit.parent.name then
    ox,oy=pos(orbit.parent.name,seen)
  end
  local distance,turn=body.distance,body.orientation
  if (type(distance)~="number" or type(turn)~="number") and orbit then
    distance,turn=orbit.distance,orbit.orientation
  end
  seen[name]=nil
  if not ox or type(distance)~="number"
    or type(turn)~="number" then return nil end
  return ox+distance*math.sin(2*math.pi*turn),
    oy-distance*math.cos(2*math.pi*turn)
end
M.position=pos

-- Deliberately conservative step minima. Local 1,000 km moon transfers
-- must NOT become giant voyages just because the galaxy is zoomed out.
function M.minimum_for_span(span)
  if type(span)~="number" or span~=span then return 0 end
  local minimum
  if span>=125 then minimum=math.max(90000,span*700)
  elseif span>=80 then minimum=math.max(60000,span*650)
  elseif span>=55 then minimum=math.max(35000,span*600)
  elseif span>=40 then minimum=span*450
  else return 0 end
  return math.floor(minimum/500+.5)*500
end
local function exceptional(route)
  local a,b=route.from or "",route.to or ""
  if a==b or (a=="nauvis" and b=="muluna")
    or (b=="nauvis" and a=="muluna") then return true end
  if a:find("belt",1,true) and b:find("belt",1,true) then
    return true
  end
  for _,part in ipairs({a,b,route.name or ""}) do
    local lower=part:lower()
    for _,word in ipairs({"stargate","wormhole","teleport","portal",
      "dyson"}) do
      if lower:find(word,1,true) then return true end
    end
  end
  return false
end
M.exceptional=exceptional
function M.correct(route)
  if type(route)~="table" or type(route.length)~="number"
    or route.length<=0 or type(route.from)~="string"
    or type(route.to)~="string" or exceptional(route) then return false end
  local raw=data and data.raw or {}
  local function exists(n)
    return (raw.planet or {})[n] or (raw["space-location"] or {})[n]
  end
  if not exists(route.from) or not exists(route.to) then return false end
  local ax,ay=pos(route.from)
  local bx,by=pos(route.to)
  if not (ax and bx) then return false end
  local span=math.sqrt((ax-bx)^2+(ay-by)^2)
  local minimum=M.minimum_for_span(span)
  if minimum==0 or route.length>=minimum then return false end
  local before=route.length
  route.length=minimum
  return true,before,minimum,span
end
function M.data_final_fixes()
  local raw=data and data.raw or {}
  local routes=raw["space-connection"] or {}
  local names={}
  for name in pairs(routes) do names[#names+1]=name end
  table.sort(names)
  local changed=0
  for _,name in ipairs(names) do
    local ok,prior,after,span=M.correct(routes[name])
    if ok then
      changed=changed+1
      if type(log)=="function" then
        log(string.format("[Razi Protocol/distances] %s: %g to %g km across %.1f map units",
          name,prior,after,span))
      end
    end
  end
  if type(log)=="function" then
    log("[Razi Protocol/distances] Repriced "..changed..
      " gross mismatches. Original close moons, belts and portals retained.")
  end
  return changed
end
return M
