-- Razi's restrained starmap navigation overlay (Factorio 2.1).
-- Read actual finalized space connections and asteroid spawn data. Never
-- replace native travel edges, make new routes, or invoke runtime drawing.
-- Space Route Overlay inspires the risk categories, not this implementation.
local M={}
local hazards=require("prototypes.system.route_hazards")
local layout=require("prototypes.system.galaxy_layout")
local reconcile=require("prototypes.system.route_reconcile")
local quality=require("scripts.razi_asteroid_difficulty")

-- Retire repeated direction sprites; Factorio owns the single native line.
local WARNING="__razi-protocol__/graphics/icons/routes/asteroid-route.png"
local WAYPOINT="__razi-protocol__/graphics/icons/routes/interstellar-route.png"
local OLD="__razi-protocol__/graphics/route-highlights/"
local MARKER_LIMIT=36
local PI=math.pi
local TAU=2*PI
local abs,sqrt,sin,cos=math.abs,math.sqrt,math.sin,math.cos

-- Exactly ten grade colors come from the *same* quality hazard ladder
-- used for real asteroid spawning. No duplicate, competing 5-color scale.
local danger_colors=hazards.colors
local function quality_active()
  local option=settings and settings.startup
    and settings.startup["razi-quality-asteroids"]
  return not option or option.value~=false
end
function M.route_color_level(route)
  if not quality_active() then return nil end
  local setting=settings and settings.startup
    and settings.startup["razi-asteroid-difficulty-scale"]
  local _,peak=quality.route_range(route,setting and setting.value)
  return peak
end
-- Campaign mode remains supported, but cannot hide major hazards.
local chapter_colors={
  {r=.48,g=.59,b=.65}, {r=.45,g=.60,b=.62},
  {r=.59,g=.59,b=.49}, {r=.58,g=.55,b=.64},
  {r=.65,g=.59,b=.60}
}
local chapter_tiers={
  calidus=1,solaris=2,nyxaris=2,vibrant=3,vespera=3,
  beetlejuice=4,umbra=4,["solar-system-edge"]=5,["deep-space"]=5
}

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

local function chapter(name,pos)
  if name=="nauvis" or name=="muluna" or name=="sye-calidus" then return 1 end
  local system=name:match("^sye%-(.+)") or name
  if chapter_tiers[system] then return chapter_tiers[system] end
  local closest,best=2,math.huge
  for star,grade in pairs(chapter_tiers) do
    local x,y=0,0
    if star~="calidus" and star~="deep-space" then
      x,y=layout.anchor_position(star)
    end
    if x and y then
      local d=(pos.x-x)^2+(pos.y-y)^2
      if d<best then best,closest=d,grade end
    end
  end
  return closest
end

-- Use actual hostile asteroid sizes/probabilities from the native route.
-- Belt crossings always have a caution floor, even if a late source mod
-- removes the standard asteroid spawn declarations from that corridor.
function M.threat_tier(route)
  local report=hazards.inspect(route)
  local rank=report.tier
  if hazards.is_belt_crossing(route) then rank=math.max(4,rank) end
  return rank
end

function M.color_for_route(route,mode)
  local grade=M.route_color_level(route)
  if grade then return quality.route_color(grade) end
  -- Legacy display when quality-asteroid escalation is disabled.
  local rank=M.threat_tier(route)
  if mode=="chapter" and rank<4 and not hazards.is_belt_crossing(route) then
    local a,b=position(route.from),position(route.to)
    if a and b then
      return chapter_colors[math.max(chapter(route.from,a),
        chapter(route.to,b))] or chapter_colors[5]
    end
  end
  return danger_colors[rank]
end
function M.color_for_guide(_,route)
  return M.color_for_route(route)
end
M.danger_colors=danger_colors

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
  if unsafe_endpoint[route.from] or unsafe_endpoint[route.to] then
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
  if route.shape=="line" then
    return function(t)
      return {x=lerp(a.x,b.x,t),y=lerp(a.y,b.y,t)}
    end,magnitude(a,b)
  end
  local cx,cy=xy(route.origin)
  if not cx then
    cx,cy=0,0
    if sqrt(a.x*a.x+a.y*a.y)>55
      or sqrt(b.x*b.x+b.y*b.y)>55 then return nil end
  end
  local dx,dy=a.x-cx,a.y-cy
  local ex,ey=b.x-cx,b.y-cy
  local ra,rb=sqrt(dx*dx+dy*dy),sqrt(ex*ex+ey*ey)
  if ra<4 or rb<4 or abs(ra-rb)>math.min(ra,rb)*.28 then
    return nil
  end
  local first=atan2(dy,dx)
  local sweep=(atan2(ey,ex)-first+PI)%TAU-PI
  if abs(sweep)>.95 then return nil end
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

-- A single fixed-size warning beside genuinely hazardous roads. Never
-- stretch a sprite along a connection: that created the ugly green parallel
-- line, repeated square joints, and visual seams seen in 2.1.90.
function M.marker_for_connection(route,mode,scope)
  if not route or mode=="off"
    or not M.is_navigation_highlight(route,scope) then return nil end
  local a,b=position(route.from),position(route.to)
  if not a or not b then return nil end
  local span=magnitude(a,b)
  if span<7 or span>480 then return nil end
  local major=is_major(route,a,b)
  if scope=="major" and not major then return nil end
  local tier=M.threat_tier(route)
  local grade=M.route_color_level(route)
  -- Draw a single colored route indicator even for low difficulty ranks.
  -- No full-length parallel route stripe, repeated dots, or tinted native line.
  local hazardous=tier>=4 or (grade and grade>=8)
  if not grade and not hazardous
    and (mode~="chapter" or not major) then return nil end
  local at,length=route_path(route,a,b)
  if not at or length<7 then return nil end
  local middle,previous,later=at(.5),at(.48),at(.52)
  local dx,dy=later.x-previous.x,later.y-previous.y
  local mag=sqrt(dx*dx+dy*dy)
  if mag<.00001 then return nil end
  local offset=hazardous and .85 or .72
  local color=M.color_for_route(route,mode)
  return {
    type="sprite",filename=hazardous and WARNING or WAYPOINT,
    size={64,64},scale=hazardous and .28 or .19,
    shift={(middle.x-dy/mag*offset)*32,(middle.y+dx/mag*offset)*32},
    priority="extra-high-no-scale",flags={"gui-icon"},blend_mode="normal",
    tint={r=color.r,g=color.g,b=color.b,
      a=grade and math.min(.64,.24+.038*grade)
        or (hazardous and (tier>=5 and .62 or .46) or .22)}
  }
end

-- Compatibility name: now returns zero or one badge, never a run of sprites.
function M.strokes_for_connection(route,mode,scope)
  local badge=M.marker_for_connection(route,mode,scope)
  return badge and {badge} or {}
end

local function obsolete(layer)
  local f=layer and layer.filename
  return type(f)=="string" and f:sub(1,#OLD)==OLD and
    (f:find("continuous-strokes.png",1,true)
      or f:find("directional-strokes.png",1,true)
      or f:match("/guide%-%d+%.png$"))~=nil
end

function M.data_final_fixes()
  local startup=settings and settings.startup or {}
  local mode=startup["razi-route-overlay-mode"]
    and startup["razi-route-overlay-mode"].value or "danger"
  local scope=startup["razi-route-overlay-scope"]
    and startup["razi-route-overlay-scope"].value or "major"
  local ui=(data.raw["utility-sprites"] or {}).default
  local atlas=ui and ui.starmap_star
  if not (atlas and type(atlas.layers)=="table") then return 0 end
  for i=#atlas.layers,1,-1 do
    if obsolete(atlas.layers[i]) then table.remove(atlas.layers,i) end
  end
  if mode=="off" or (mods and mods["space-route-overlay"]) then return 0 end
  for _,sprite in ipairs(atlas.layers) do
    if sprite.filename==WARNING or sprite.filename==WAYPOINT then return 0 end
  end
  local candidates={}
  for name,connection in pairs(data.raw["space-connection"] or {}) do
    local sprite=M.marker_for_connection(connection,mode,scope)
    if sprite then
      candidates[#candidates+1]={
        name=name,sprite=sprite,
        priority=(hazards.is_belt_crossing(connection) and 1000 or 0)
          +(M.route_color_level(connection)
            or M.threat_tier(connection))*100
      }
    end
  end
  table.sort(candidates,function(a,b)
    if a.priority==b.priority then return a.name<b.name end
    return a.priority>b.priority
  end)
  local used,n={},0
  for _,row in ipairs(candidates) do
    if n>=MARKER_LIMIT then break end
    local x,y=row.sprite.shift[1]/32,row.sprite.shift[2]/32
    local clear=true
    for _,pos in ipairs(used) do
      if (pos[1]-x)^2+(pos[2]-y)^2<16 then clear=false break end
    end
    if clear then
      atlas.layers[#atlas.layers+1]=row.sprite
      used[#used+1]={x,y}
      n=n+1
    end
  end
  if type(log)=="function" then
    log("[Razi Protocol/routes] "..n..
      " individually graded color markers; one native line per connection")
  end
  return n
end
return M
