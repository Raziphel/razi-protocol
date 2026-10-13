-- Native route geometry is the default chart. Clear mode adds exactly
-- one restrained guide to verified straight routes or a real belt crossing.
local M={}
local manifest=require("prototypes.system.route_highlight_manifest")
local hazards=require("prototypes.system.route_hazards")
local function key(a,b)
  if a>b then a,b=b,a end
  return a.."|"..b
end
local function current_position(name)
  local location=(data.raw.planet or {})[name]
    or (data.raw["space-location"] or {})[name]
  if not location then return end
  local origin=location.origin or {}
  local radius=location.distance
  local angle=location.orientation
  if radius==nil and location.orbit then radius=location.orbit.distance end
  if angle==nil and location.orbit then angle=location.orbit.orientation end
  if type(radius)~="number" or type(angle)~="number" then return end
  local theta=2*math.pi*angle
  return {(origin.x or origin[1] or 0)+radius*math.sin(theta),
    (origin.y or origin[2] or 0)-radius*math.cos(theta)}
end
function M.layers_for_guide(guide,color,mode)
  if mode~="clear" then return {} end
  local weight=guide.kind=="belt" and 1
    or guide.kind=="outer" and .84 or .70
  local blend=.48
  local tint={
    r=.65*(1-blend)+color.r*blend,
    g=.72*(1-blend)+color.g*blend,
    b=.79*(1-blend)+color.b*blend,
    a=.46*weight
  }
  return {{
    type="sprite",filename=guide.filename,size=guide.size,
    shift=guide.shift,scale=4,priority="extra-high-no-scale",
    flags={"gui-icon"},blend_mode="normal",tint=tint
  }}
end
-- Old midpoint debris motifs looked like additional portals and hazy
-- navigation nodes. Asteroids still spawn along their real native routes.
function M.field_marker() return nil end
function M.data_final_fixes()
  local option=settings and settings.startup
    and settings.startup["razi-route-highlight-style"]
  local mode=option and option.value or "subtle"
  if mode~="clear" or (mods and mods["space-route-overlay"]) then return end
  local utility=(data.raw["utility-sprites"] or {}).default
  local art=utility and utility.starmap_star
  if not (art and type(art.layers)=="table") then return end
  local routes={}
  for _,route in pairs(data.raw["space-connection"] or {}) do
    if route.from and route.to then routes[key(route.from,route.to)]=route end
  end
  local existing={}
  for _,layer in ipairs(art.layers) do
    if layer.filename then existing[layer.filename]=true end
  end
  local painted=0
  for _,guide in ipairs(manifest) do
    local route=routes[key(guide.from,guide.to)]
    local p,q=current_position(guide.from),current_position(guide.to)
    local aligned=p and q
      and math.abs(p[1]-guide.start[1])<1.5
      and math.abs(p[2]-guide.start[2])<1.5
      and math.abs(q[1]-guide.finish[1])<1.5
      and math.abs(q[2]-guide.finish[2])<1.5
    -- Never draw our own straight line over native curved connections.
    local appropriate=route and
      (route.shape=="line" or guide.kind=="belt")
    if aligned and appropriate and not existing[guide.filename] then
      for _,layer in ipairs(M.layers_for_guide(
        guide,hazards.color(route),mode)) do
        art.layers[#art.layers+1]=layer
      end
      existing[guide.filename]=true
      painted=painted+1
    end
  end
  if type(log)=="function" then
    log("[Razi Protocol/route-highlights] "..painted.." narrow verified guides")
  end
end
return M
