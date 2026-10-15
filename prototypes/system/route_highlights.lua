-- Razi's restrained starmap navigation overlay (Factorio 2.1).
-- Read actual finalized space connections and asteroid spawn data. Never
-- replace native travel edges, make new routes, or invoke runtime drawing.
-- Space Route Overlay inspires the risk categories, not this implementation.
local M={}
local hazards=require("prototypes.system.route_hazards")
local layout=require("prototypes.system.galaxy_layout")
local reconcile=require("prototypes.system.route_reconcile")

local SHEET="__razi-protocol__/graphics/route-highlights/continuous-strokes.png"
local CELL=128            -- eight columns / eight rows, 64 bearings
local PIXELS=110          -- continuous anti-aliased line in each 128px cell
local SEGMENT=3.5        -- target distance between joined line segments
local MAX_SEGMENTS=88     -- very long / anomalous connections remain native
local MAX_SPAN=7.25       -- do not magnify sprites into thick dotted tails
local LAYER_BUDGET=720    -- static sprite budget, no runtime or tick cost
local PI=math.pi
local TAU=2*PI
local abs,sqrt,sin,cos=math.abs,math.sqrt,math.sin,math.cos

-- Risk classification inspired by Space Route Overlay's asteroid-based
-- colors. Our own geometry and atlas remain entirely Razi-owned.
local danger_colors=hazards.colors
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

function M.strokes_for_connection(route,mode,scope)
  if not route or not route.from or not route.to
    or route.hidden or mode=="off" then return {} end
  local a,b=position(route.from),position(route.to)
  if not a or not b or magnitude(a,b)<2 then return {} end
  local major=is_major(route,a,b)
  if scope=="major" and not major then return {} end
  local at,length=route_path(route,a,b)
  if not at or length<2 then return {} end
  -- Trim near each map icon but never discard the important belt corridor.
  local trim=math.min(1.65/length,.13)
  local usable=length*(1-2*trim)
  if usable<1.25 then return {} end
  local count=math.max(1,math.ceil(usable/SEGMENT))
  if count>MAX_SEGMENTS or usable/count>MAX_SPAN then return {} end

  local rank=M.threat_tier(route)
  local color=M.color_for_route(route,mode)
  -- The overlay is an annotation *beside* Factorio's native route,
  -- never a competing rainbow path. Keep ordinary corridors quiet.
  -- Only heavy hostile asteroids merit brighter emphasis.
  local opacity=({.105,.14,.19,.25,.30})[rank]
  if scope=="all" and not major then opacity=opacity*.66 end
  if mode=="chapter" and rank<4 then opacity=opacity*.80 end
  if hazards.is_belt_crossing(route) then opacity=math.max(opacity,.26) end

  local sprites={}
  for i=0,count-1 do
    local t0=trim+(1-2*trim)*i/count
    local t1=trim+(1-2*trim)*(i+1)/count
    local p,q=at(t0),at(t1)
    local span=magnitude(p,q)
    if span>.2 then
      local bearing=atan2(q.y-p.y,q.x-p.x)%PI
      local tile=math.floor(bearing/PI*64+.5)%64
      -- Overlap by ~.30 map units. The line texture has tapered ends,
      -- so this closes pixel seams without creating bright join dots.
      local rendered_span=span+.18
      sprites[#sprites+1]={
        type="sprite",filename=SHEET,
        x=(tile%8)*CELL,y=math.floor(tile/8)*CELL,
        size={CELL,CELL},scale=rendered_span*32/PIXELS,
        shift={(p.x+q.x)*16,(p.y+q.y)*16},
        priority="extra-high-no-scale",flags={"gui-icon"},
        blend_mode="normal",
        tint={r=color.r,g=color.g,b=color.b,a=opacity}
      }
    end
  end
  return sprites
end

function M.data_final_fixes()
  local startup=settings and settings.startup or {}
  local mode=startup["razi-route-overlay-mode"]
    and startup["razi-route-overlay-mode"].value or "danger"
  local scope=startup["razi-route-overlay-scope"]
    and startup["razi-route-overlay-scope"].value or "major"
  if mode=="off" then return 0 end
  -- Never draw two independent route systems over the same native line.
  if mods and mods["space-route-overlay"] then return 0 end
  local ui=(data.raw["utility-sprites"] or {}).default
  local atlas=ui and ui.starmap_star
  if not (atlas and type(atlas.layers)=="table") then return 0 end
  for _,layer in ipairs(atlas.layers) do
    if layer.filename==SHEET then return 0 end
  end

  local routes=data.raw["space-connection"] or {}
  local candidates={}
  for name,route in pairs(routes) do
    if M.is_navigation_highlight(route,scope) then
      local sprites=M.strokes_for_connection(route,mode,scope)
      if #sprites>0 then
        candidates[#candidates+1]={
          name=name,route=route,sprites=sprites,
          priority=(hazards.is_belt_crossing(route) and 100 or 0)
            +M.threat_tier(route)*10}
      end
    end
  end
  -- Risk-first when the map is crowded. Stable tie order makes results
  -- deterministic regardless of Lua table iteration order.
  table.sort(candidates,function(a,b)
    if a.priority==b.priority then return a.name<b.name end
    return a.priority>b.priority
  end)
  local painted,layers=0,0
  for _,entry in ipairs(candidates) do
    if layers+#entry.sprites<=LAYER_BUDGET then
      for _,sprite in ipairs(entry.sprites) do
        atlas.layers[#atlas.layers+1]=sprite
      end
      painted=painted+1
      layers=layers+#entry.sprites
    end
  end
  if type(log)=="function" then
    log(string.format(
      "[Razi Protocol/routes] %d native corridors, %d joined danger-aware sprites (%s/%s). Skipped ambiguous geometry and exceeded-budget paths without painting dotted trails",
      painted,layers,mode,scope))
  end
  return painted
end
return M
