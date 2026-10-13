-- All-route star-chart color. One shared 64-bearing sprite sheet replaces
-- individual pre-baked guide masks. No space-connection prototypes are changed.
local M={}
local hazards=require("prototypes.system.route_hazards")
local layout=require("prototypes.system.galaxy_layout")
local SHEET="__razi-protocol__/graphics/route-highlights/directional-strokes.png"
local CELL=256
local STEP=20
local LIMIT=1800
local PI=math.pi
local TAU=2*PI

local stage_colors={
  {r=.35,g=.81,b=.90}, -- local & opening routes
  {r=.45,g=.83,b=.74}, -- first star pair
  {r=.94,g=.76,b=.45}, -- second pair
  {r=.75,g=.60,b=.95}, -- outer frontier
  {r=.91,g=.49,b=.69}  -- Deep Space
}
local stage_by_star={
  calidus=1,solaris=2,nyxaris=2,
  vibrant=3,vespera=3,beetlejuice=4,umbra=4,
  ["solar-system-edge"]=5,["deep-space"]=5
}
local known_home={nauvis=true,muluna=true,["sye-calidus"]=true,
  ["razi-calidus-drift"]=true}
local alias={
  ["sye-solaris"]="solaris",["sye-nyxaris"]="nyxaris",
  ["sye-vibrant"]="vibrant",["sye-vespera"]="vespera",
  ["sye-beetlejuice"]="beetlejuice",["sye-umbra"]="umbra"
}

local function lerp(a,b,t) return a+(b-a)*t end
local function blend(a,b,t)
  return {r=lerp(a.r,b.r,t),g=lerp(a.g,b.g,t),b=lerp(a.b,b.b,t)}
end
local function location(name)
  return (data.raw.planet or {})[name]
    or (data.raw["space-location"] or {})[name]
end
function M.position(name)
  local loc=location(name)
  if not loc then return nil end
  -- Factorio 2.1.20+ positions are absolute polar coordinates around
  -- origin. The old orbit remains useful for source-only locations.
  local distance=loc.distance or (loc.orbit and loc.orbit.distance)
  local turn=loc.orientation or (loc.orbit and loc.orbit.orientation)
  if type(distance)~="number" or type(turn)~="number" then return nil end
  local origin=loc.origin or {}
  return {x=(origin.x or origin[1] or 0)+distance*math.sin(TAU*turn),
    y=(origin.y or origin[2] or 0)-distance*math.cos(TAU*turn)}
end
local function nearest_stage(point)
  local chosen=1
  local best=math.huge
  for star,tier in pairs(stage_by_star) do
    if star~="deep-space" then
      local x,y=0,0
      if star~="calidus" then x,y=layout.anchor_position(star) end
      if x and y then
        local dist=(point.x-x)^2+(point.y-y)^2
        if dist<best then best,chosen=dist,tier end
      end
    end
  end
  return chosen
end
function M.stage_for_location(name)
  if known_home[name] then return 1 end
  local named=alias[name] or name
  if stage_by_star[named] then return stage_by_star[named] end
  local proto=location(name)
  local parent=proto and proto.orbit and proto.orbit.parent
  if parent and stage_by_star[parent.name] then
    return stage_by_star[parent.name]
  end
  local pos=M.position(name)
  if pos then return nearest_stage(pos) end
  return nil
end
local function route_stage(route)
  local from=M.stage_for_location(route.from)
  local to=M.stage_for_location(route.to)
  if not from and not to then return 2 end
  return math.max(from or to,to or from)
end
function M.color_for_route(route)
  local stage=route_stage(route)
  local base=stage_colors[stage] or stage_colors[5]
  local danger=hazards.inspect(route).tier
  if hazards.is_belt_crossing(route) then
    base={r=.95,g=.53,b=.81}
  end
  if danger>=5 then return blend(base,{r=1,g=.33,b=.39},.66) end
  if danger==4 then return blend(base,{r=1,g=.52,b=.29},.44) end
  if danger==3 then return blend(base,{r=.99,g=.80,b=.41},.18) end
  return base
end
-- Retain the direct palette helper used by older GUI/tests.
function M.color_for_guide(guide,route)
  local c={first=stage_colors[2],middle=stage_colors[3],
    outer=stage_colors[4],belt={r=.95,g=.53,b=.81},
    ["belt-approach"]={r=.91,g=.67,b=.44}}
  local base=c[guide.kind] or stage_colors[2]
  local risk=hazards.inspect(route).tier
  if risk>=5 then return blend(base,{r=1,g=.33,b=.39},.66) end
  if risk==4 then return blend(base,{r=1,g=.52,b=.29},.44) end
  if risk==3 then return blend(base,{r=.99,g=.80,b=.41},.18) end
  return base
end
function M.layers_for_guide(guide,color,mode)
  if mode=="off" then return {} end
  local strength=guide.kind=="outer" and .93 or 1
  return {{type="sprite",filename=guide.filename,size=guide.size,
    shift=guide.shift,scale=4,priority="extra-high-no-scale",
    flags={"gui-icon"},blend_mode="normal",
    tint={r=color.r,g=color.g,b=color.b,
      a=(mode=="clear" and .78 or .55)*strength}}}
end
function M.field_marker() return nil end

-- Native arcs use the route's documented origin as the stellar centre.
-- We approximate their polar sweep with short, contiguous chords instead
-- of drawing one false straight shortcut across a system.
local function route_point(route,a,b,t)
  if route.shape=="line" then
    return {x=lerp(a.x,b.x,t),y=lerp(a.y,b.y,t)}
  end
  local o=route.origin or {}
  local cx,cy=o.x or o[1] or 0,o.y or o[2] or 0
  local ax,ay=a.x-cx,a.y-cy
  local bx,by=b.x-cx,b.y-cy
  local ar,br=math.sqrt(ax*ax+ay*ay),math.sqrt(bx*bx+by*by)
  if ar<.5 or br<.5 then
    return {x=lerp(a.x,b.x,t),y=lerp(a.y,b.y,t)}
  end
  local start=math.atan2 and math.atan2(ay,ax) or math.atan(ay,ax)
  local finish=math.atan2 and math.atan2(by,bx) or math.atan(by,bx)
  local turn=(finish-start+PI)%(TAU)-PI
  local angle=start+turn*t
  local radius=lerp(ar,br,t)
  return {x=cx+radius*math.cos(angle),y=cy+radius*math.sin(angle)}
end
function M.strokes_for_connection(route,mode)
  if mode=="off" or not route.from or not route.to or route.hidden then
    return {}
  end
  local a,b=M.position(route.from),M.position(route.to)
  if not a or not b then return {} end
  local sections=math.max(1,math.ceil(math.sqrt((a.x-b.x)^2+
    (a.y-b.y)^2)/STEP))
  if route.shape~="line" then sections=math.max(3,sections) end
  sections=math.min(12,sections)
  local tint=M.color_for_route(route)
  local stage=route_stage(route)
  local alpha=(mode=="clear" and .76 or .53)*
    (stage==1 and .78 or stage==2 and .90 or 1)
  local result={}
  for i=0,sections-1 do
    local p=route_point(route,a,b,i/sections)
    local q=route_point(route,a,b,(i+1)/sections)
    local dx,dy=q.x-p.x,q.y-p.y
    local distance=math.sqrt(dx*dx+dy*dy)
    if distance>.1 then
      local angle=(math.atan2 and math.atan2(dy,dx)
        or math.atan(dy,dx))%PI
      local tile=math.floor(angle/PI*64+.5)%64
      result[#result+1]={
        type="sprite",filename=SHEET,
        x=(tile%8)*CELL,y=math.floor(tile/8)*CELL,
        size={CELL,CELL},scale=distance*32/220,
        shift={(p.x+q.x)*16,(p.y+q.y)*16},
        priority="extra-high-no-scale",flags={"gui-icon"},
        blend_mode="normal",
        tint={r=tint.r,g=tint.g,b=tint.b,a=alpha}
      }
    end
  end
  return result
end
function M.data_final_fixes()
  local setting=settings and settings.startup
    and settings.startup["razi-route-highlight-style"]
  local mode=setting and setting.value or "subtle"
  if mode=="off" or (mods and mods["space-route-overlay"]) then return end
  local utility=(data.raw["utility-sprites"] or {}).default
  local star=utility and utility.starmap_star
  if not (star and type(star.layers)=="table") then return end
  for _,sprite in ipairs(star.layers) do
    if sprite.filename==SHEET then return end
  end
  local entries={}
  for key in pairs(data.raw["space-connection"] or {}) do
    entries[#entries+1]=key
  end
  table.sort(entries)
  local connected,unknown,layers=0,0,0
  for _,name in ipairs(entries) do
    local route=data.raw["space-connection"][name]
    local strokes=M.strokes_for_connection(route,mode)
    if #strokes>0 and layers+#strokes<=LIMIT then
      for _,sprite in ipairs(strokes) do
        star.layers[#star.layers+1]=sprite
      end
      connected=connected+1
      layers=layers+#strokes
    else
      unknown=unknown+1
    end
  end
  if type(log)=="function" then
    log(string.format(
      "[Razi Protocol/routes] %d/%d real space connections tinted (%d sprites); %d unmapped/hidden/capped",
      connected,#entries,layers,unknown))
  end
end
return M
