-- Razi's restrained starmap navigation overlay (Factorio 2.1).
-- Read actual finalized space connections and asteroid spawn data. Never
-- replace native travel edges, make new routes, or invoke runtime drawing.
-- Space Route Overlay inspires the risk categories, not this implementation.
local M={}
local hazards=require("prototypes.system.route_hazards")
local layout=require("prototypes.system.galaxy_layout")
local reconcile=require("prototypes.system.route_reconcile")
local quality=require("scripts.razi_asteroid_difficulty")

local PI=math.pi
local TAU=2*PI
local abs,sqrt,sin,cos=math.abs,math.sqrt,math.sin,math.cos

-- This is the only visible difficulty scale: Level 1-10.
function M.route_color_level(route)
  local setting=settings and settings.startup
    and settings.startup["razi-asteroid-difficulty-scale"]
  local _,peak=quality.route_range(route,setting and setting.value)
  return peak
end
function M.color_for_route(route)
  return quality.route_color(M.route_color_level(route))
end
function M.color_for_guide(_,route)
  return M.color_for_route(route)
end

local function finite(x)
  return type(x)=="number" and x==x and abs(x)<100000
end
local function xy(point)
  if type(point)~="table" then return end
  local x,y=point.x or point[1],point.y or point[2]
  if finite(x) and finite(y) then return x,y end
end
local function atan2(y,x)
  return math.atan2 and math.atan2(y,x) or math.atan(y,x)
end
local function magnitude(a,b)
  return sqrt((a.x-b.x)^2+(a.y-b.y)^2)
end
local function lerp(a,b,t) return a+(b-a)*t end

-- Final native starmap positions take priority; fallback only for Razi star
-- anchors and valid parent-orbit data (never invented remote locations).
local function position(name,seen)
  if name=="star" then return {x=0,y=0} end
  seen=seen or {}
  if seen[name] then return nil end
  seen[name]=true
  local planet=data.raw.planet or {}
  local location=data.raw["space-location"] or {}
  local loc=planet[name] or location[name]
  if not loc then
    local x,y=layout.anchor_position(name)
    if x and y then return {x=x,y=y} end
    return nil
  end
  if finite(loc.distance) and finite(loc.orientation) then
    local x,y=xy(loc.origin)
    return {x=(x or 0)+loc.distance*sin(TAU*loc.orientation),
      y=(y or 0)-loc.distance*cos(TAU*loc.orientation)}
  end
  local orbit=loc.orbit
  if orbit and finite(orbit.distance) and finite(orbit.orientation) then
    local parent=orbit.parent and position(orbit.parent.name,seen)
    if parent then return {
      x=parent.x+orbit.distance*sin(TAU*orbit.orientation),
      y=parent.y-orbit.distance*cos(TAU*orbit.orientation)}
    end
  end
  local x,y=layout.anchor_position(name)
  if x and y then return {x=x,y=y} end
end
M.position=position

-- The red dotted routes between Carna/Gleba/Velora must NOT return.
-- "major" paints only Razi's verified main corridors and physical belts.
-- "all" also paints other source-owned real routes, but only when their
-- final native coordinates can be rendered without guessing an arc.
local unsafe_endpoint={carna=true,gleba=true,velora=true}
local function major_waypoint(name)
  return type(name)=="string" and
    (name:match("^sye%-")~=nil
      or name=="asteroid-belt-outer-edge"
      or name=="solar-system-edge")
end
function M.is_navigation_highlight(route,scope)
  if type(route)~="table" or type(route.from)~="string"
    or type(route.to)~="string" or route.hidden
    or route.from==route.to then return false end
  -- Only explicitly known native connection geometry is rendered. The old
  -- Carna/Gleba dotted artifacts came from unrelated decorative sprites,
  -- not from these actual connection paths. All may use real geometry.
  if scope~="all" and
    (unsafe_endpoint[route.from] or unsafe_endpoint[route.to]) then
    return false
  end
  if hazards.is_belt_crossing(route) then return true end
  if scope=="all" then return true end
  return major_waypoint(route.from) and major_waypoint(route.to)
    and reconcile.allowed_pairs[
      reconcile.pair_key(route.from,route.to)]==true or false
end

-- Factorio shape='arc' travels around the explicitly supplied origin.
-- Do not guess distant arc centers or sweep across half a galaxy.
local function route_path(route,a,b)
  -- Factorio 2.1 defaults SpaceConnectionPrototype.shape to "arc".
  -- Treat only explicit line routes as straight or we'd cut across
  -- orbital belts and draw a false chord over the native curve.
  if route.shape=="line" then
    return function(t)
      return {x=lerp(a.x,b.x,t),y=lerp(a.y,b.y,t)}
    end,magnitude(a,b)
  end
  local cx,cy=xy(route.origin)
  -- Factorio 2.1 defaults native arc origin to (0,0). Read the
  -- prototype-defined origin if present, otherwise use the SAME default
  -- rather than assuming it is a line or inventing a nearby star.
  if not cx then cx,cy=0,0 end
  local dx,dy=a.x-cx,a.y-cy
  local ex,ey=b.x-cx,b.y-cy
  local ra,rb=sqrt(dx*dx+dy*dy),sqrt(ex*ex+ey*ey)
  if ra<1 or rb<1 then return nil end
  local first=atan2(dy,dx)
  local sweep=(atan2(ey,ex)-first+PI)%TAU-PI
  -- Native arcs can span a large part of an orbit. Follow the shorter
  -- signed arc consistently; segment budgeting will handle the length.
  local length=abs(sweep)*(ra+rb)/2+abs(ra-rb)
  if length<2 then return nil end
  return function(t)
    local radius=lerp(ra,rb,t)
    local angle=first+sweep*t
    return {x=cx+radius*cos(angle),y=cy+radius*sin(angle)}
  end,length
end

local function is_major(route,a,b)
  return hazards.is_belt_crossing(route) or magnitude(a,b)>=54
    or (route.shape=="line" and magnitude(a,b)>=38)
end

-- Keep geometry available for the isolated, antialiased ribbon renderer.
M.route_path=route_path
M.is_major=is_major

-- The ribbon renderer colors actual native route geometry; no duplicate
-- route badges or competing hazard scales are drawn.
function M.strokes_for_connection(route,mode,scope)
  return require("prototypes.system.route_ribbons").strokes_for_connection(
    M,route,mode,scope)
end
function M.data_final_fixes()
  return require("prototypes.system.route_ribbons").data_final_fixes(M)
end
return M
