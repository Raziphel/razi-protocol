-- Razi's built-in route renderer. Factorio 2.1 does not expose a color
-- property on space-connection prototypes, so draw restrained static
-- starmap sprites from the final native route and location coordinates.
-- This is intentionally independent of the other route-overlay mod.
local M={}
local hazards=require("prototypes.system.route_hazards")
local layout=require("prototypes.system.galaxy_layout")
local reconcile=require("prototypes.system.route_reconcile")

local SHEET="__razi-protocol__/graphics/route-highlights/directional-strokes.png"
local CELL=256
local PIXELS=220 -- stroke length in the shared 64-bearing source texture
local SEGMENT=6  -- keep zoom-scaled strokes a consistent narrow width
local MAX_SEGMENTS=18
local LAYER_BUDGET=650
local PI=math.pi
local TAU=2*PI
local abs, sqrt, sin, cos=math.abs,math.sqrt,math.sin,math.cos

local chapters={
  {r=.39,g=.77,b=.95}, -- home
  {r=.42,g=.82,b=.75}, -- first frontier
  {r=.94,g=.75,b=.42}, -- middle systems
  {r=.77,g=.60,b=.95}, -- outer systems
  {r=.94,g=.52,b=.69}  -- deep space
}
local tiers={
  calidus=1,solaris=2,nyxaris=2,vibrant=3,vespera=3,
  beetlejuice=4,umbra=4,["solar-system-edge"]=5,
  ["deep-space"]=5
}

local function finite(n)
  return type(n)=="number" and n==n and abs(n)<100000
end
local function xy(v)
  if type(v)~="table" then return nil end
  local x,y=v.x or v[1],v.y or v[2]
  if finite(x) and finite(y) then return x,y end
end
local function angle(y,x)
  return (math.atan2 and math.atan2(y,x) or math.atan(y,x))
end
local function mag(a,b)
  return sqrt((a.x-b.x)^2+(a.y-b.y)^2)
end
local function lerp(a,b,t)
  return a+(b-a)*t
end

-- Positions from the *finished* Factorio 2.1 prototypes take priority.
-- Fall back to source orbit metadata only for worlds without native coords,
-- and use Razi's virtual star anchors after PlanetsLib removes star prototypes.
local function position(name,seen)
  if name=="star" then return {x=0,y=0} end
  seen=seen or {}
  if seen[name] then return nil end
  seen[name]=true
  local planet=data.raw.planet or {}
  local space=data.raw["space-location"] or {}
  local loc=planet[name] or space[name]
  if not loc then
    local x,y=layout.anchor_position(name)
    if x and y then return {x=x,y=y} end
    return nil
  end
  local d,t=loc.distance,loc.orientation
  if finite(d) and finite(t) then
    local x,y=xy(loc.origin)
    return {x=(x or 0)+d*sin(TAU*t),y=(y or 0)-d*cos(TAU*t)}
  end
  local orbit=loc.orbit
  if orbit and finite(orbit.distance) and finite(orbit.orientation) then
    local parent=orbit.parent and position(orbit.parent.name,seen)
    if parent then
      return {x=parent.x+orbit.distance*sin(TAU*orbit.orientation),
        y=parent.y-orbit.distance*cos(TAU*orbit.orientation)}
    end
  end
  local x,y=layout.anchor_position(name)
  if x and y then return {x=x,y=y} end
end
M.position=position

local function tier(name,pos)
  if name=="nauvis" or name=="muluna" or name=="sye-calidus" then
    return 1
  end
  local system=name:match("^sye%-(.+)") or name
  if tiers[system] then return tiers[system] end
  local nearest,best=2,math.huge
  for star,grade in pairs(tiers) do
    local x,y=0,0
    if star~="calidus" and star~="deep-space" then
      x,y=layout.anchor_position(star)
    end
    if x and y then
      local length=(pos.x-x)^2+(pos.y-y)^2
      if length<best then best,nearest=length,grade end
    end
  end
  return nearest
end
-- Navigation colors echo the actual physical belt artworks. The inner
-- and outer locations are still native, clickable Factorio route endpoints.
local belt_strokes={
  vibrant={r=.76,g=.59,b=.95}, -- metallic / violet
  umbra={r=.97,g=.54,b=.41}    -- shattered / copper-ember
}
function M.color_for_route(route,mode)
  if hazards.is_belt_crossing(route) then
    local a,b=route.from or "",route.to or ""
    if a:find("razi%-umbra%-belt") or b:find("razi%-umbra%-belt") then
      return belt_strokes.umbra
    end
    return belt_strokes.vibrant
  end
  if mode~="chapter" then return hazards.color(route) end
  local a,b=M.position(route.from),M.position(route.to)
  if not a or not b then return hazards.color(route) end
  local grade=math.max(tier(route.from,a),tier(route.to,b))
  return chapters[grade] or chapters[5]
end
function M.color_for_guide(_,route)
  return M.color_for_route(route)
end

-- Rendered atlas sprites have no native Factorio connection ownership.
-- Coloring every modded route can draw bright, floating, double-dotted
-- tails from small worlds (Carna, Velora) to distant/offscreen endpoints.
-- Restrict the ART to Razi's verified hub-to-hub corridors and the
-- intentionally traversable asteroid-belt crossings. Native Factorio
-- grey routes remain available and completely unchanged.
local function major_waypoint(name)
  return type(name)=="string" and (
    name:match("^sye%-") ~= nil
    or name=="asteroid-belt-outer-edge"
    or name=="solar-system-edge")
end
function M.is_navigation_highlight(route)
  if not route or not route.from or not route.to then return false end
  if hazards.is_belt_crossing(route) then return true end
  if not (major_waypoint(route.from) and major_waypoint(route.to)) then
    return false
  end
  return reconcile.allowed_pairs[
    reconcile.pair_key(route.from,route.to)]==true
end

-- Factorio 2.1 connection.shape="arc" uses connection.origin as the
-- polar center, defaulting to (0,0). Arc interpolation must not be guessed
-- across different stars or for enormous/ambiguous sweeps. Keep those native.
local function path(route,a,b)
  if route.shape=="line" then
    return function(t)
      return {x=lerp(a.x,b.x,t),y=lerp(a.y,b.y,t)}
    end,mag(a,b)
  end
  local cx,cy=xy(route.origin)
  if not cx then
    cx,cy=0,0
    -- No explicit origin: only home-system arcs are safe to infer.
    if sqrt(a.x*a.x+a.y*a.y)>55 or sqrt(b.x*b.x+b.y*b.y)>55 then
      return nil
    end
  end
  local ax,ay=a.x-cx,a.y-cy
  local bx,by=b.x-cx,b.y-cy
  local ra,rb=sqrt(ax*ax+ay*ay),sqrt(bx*bx+by*by)
  if ra<4 or rb<4 or abs(ra-rb)>math.min(ra,rb)*.28 then return nil end
  local start=angle(ay,ax)
  local sweep=(angle(by,bx)-start+PI)%TAU-PI
  if abs(sweep)>.95 then return nil end
  local length=abs(sweep)*(ra+rb)/2+abs(ra-rb)
  if length<2 then return nil end
  return function(t)
    local rad=lerp(ra,rb,t)
    local turn=start+sweep*t
    return {x=cx+rad*cos(turn),y=cy+rad*sin(turn)}
  end,length
end

local function is_major(route,a,b)
  return hazards.is_belt_crossing(route)
    or mag(a,b)>=54
    or (route.shape=="line" and mag(a,b)>=38)
end

-- The old renderer stretched each 220px stroke over ~20 map units.
-- That magnified its width, made angle quantization obvious and introduced
-- visible gaps. Fixed 6-unit segments keep width and opacity consistent.
function M.strokes_for_connection(route,mode,scope)
  if not route or not route.from or not route.to or route.hidden or
    mode=="off" then return {} end
  local a,b=M.position(route.from),M.position(route.to)
  if not a or not b then return {} end
  if a.x==b.x and a.y==b.y then return {} end
  local major=is_major(route,a,b)
  if scope=="major" and not major then return {} end
  local at,distance=path(route,a,b)
  if not at or distance<2 then return {} end
  -- Avoid painting over planet markers/hover targets.
  local trim=math.min(2.2/distance,.16)
  local usable=distance*(1-2*trim)
  if usable<1.4 then return {} end
  local count=math.min(MAX_SEGMENTS,math.max(1,math.ceil(usable/SEGMENT)))
  -- Long journeys cannot get thick by increasing sprite scale.
  if usable/count>8.5 then return {} end
  local color=M.color_for_route(route,mode)
  local alpha=(major and .34 or .17)
  if hazards.is_belt_crossing(route) then alpha=.37 end
  local out={}
  for i=0,count-1 do
    local t0=trim+(1-2*trim)*i/count
    local t1=trim+(1-2*trim)*(i+1)/count
    local p,q=at(t0),at(t1)
    local span=mag(p,q)
    if span>0.5 then
      local bearing=angle(q.y-p.y,q.x-p.x)%PI
      local tile=math.floor(bearing/PI*64+.5)%64
      out[#out+1]={
        type="sprite",filename=SHEET,
        x=(tile%8)*CELL,y=math.floor(tile/8)*CELL,
        size={CELL,CELL},scale=span*32/PIXELS,
        shift={(p.x+q.x)*16,(p.y+q.y)*16},
        priority="extra-high-no-scale",flags={"gui-icon"},
        blend_mode="normal",
        tint={r=color.r,g=color.g,b=color.b,a=alpha}
      }
    end
  end
  return out
end

function M.data_final_fixes()
  local startup=settings and settings.startup or {}
  local mode=startup["razi-route-overlay-mode"] and
    startup["razi-route-overlay-mode"].value or "danger"
  local scope=startup["razi-route-overlay-scope"] and
    startup["razi-route-overlay-scope"].value or "major"
  if mode=="off" then return 0 end
  -- If another overlay is present despite the incompatibility declaration,
  -- fail closed rather than layering two conflicting visual treatments.
  if mods and mods["space-route-overlay"] then return 0 end
  local ui=(data.raw["utility-sprites"] or {}).default
  local atlas=ui and ui.starmap_star
  if not (atlas and type(atlas.layers)=="table") then return 0 end
  for _,layer in ipairs(atlas.layers) do
    if layer.filename==SHEET then return 0 end
  end
  local names={}
  for name in pairs(data.raw["space-connection"] or {}) do
    names[#names+1]=name
  end
  table.sort(names)
  local painted,layers=0,0
  local routes=data.raw["space-connection"] or {}
  for _,name in ipairs(names) do
    local route=routes[name]
    -- Never paint partial red dash trails around optional planets.
    local sprites=M.is_navigation_highlight(route)
      and M.strokes_for_connection(route,mode,scope) or {}
    if #sprites>0 and layers+#sprites<=LAYER_BUDGET then
      for _,sprite in ipairs(sprites) do
        atlas.layers[#atlas.layers+1]=sprite
      end
      layers=layers+#sprites
      painted=painted+1
    end
  end
  if type(log)=="function" then
    log(string.format("[Razi Protocol/routes] Painted %d native paths with %d thin atlas strokes (%s/%s); ambiguous curves left native",
      painted,layers,mode,scope))
  end
  return painted
end
return M
