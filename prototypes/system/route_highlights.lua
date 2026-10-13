-- Colour progression on the EXISTING hand-aligned real-route masks.
-- A single subdued line is always used: no triple glows or false branches.
-- Unmapped/curved connections continue to use exact native Factorio art.
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
-- A muted chapter palette: blue/teal = early, gold = middle, lilac =
-- outer/endgame and rose = exceptional belt crossings. Real asteroid
-- severity warms the hue so difficult links are distinguishable.
local tier_colors={
  first={r=.36,g=.82,b=.88},
  middle={r=.94,g=.75,b=.45},
  outer={r=.76,g=.61,b=.96},
  belt={r=.94,g=.52,b=.82},
  ["belt-approach"]={r=.90,g=.68,b=.43}
}
local function mix(a,b,amount)
  return {r=a.r*(1-amount)+b.r*amount,
    g=a.g*(1-amount)+b.g*amount,
    b=a.b*(1-amount)+b.b*amount}
end
function M.color_for_guide(guide,route)
  local base=tier_colors[guide.kind] or tier_colors.middle
  local severity=hazards.inspect(route).tier
  -- This is a colour annotation only: hazard data is never mutated.
  if guide.kind=="belt" then return mix(base,hazards.color(route),.35) end
  if severity>=5 then return mix(base,{r=1,g=.32,b=.38},.62) end
  if severity==4 then return mix(base,{r=1,g=.53,b=.30},.42) end
  if severity==3 then return mix(base,{r=.98,g=.78,b=.40},.20) end
  return base
end
function M.layers_for_guide(guide,color,mode)
  if mode=="off" then return {} end
  local weight=guide.kind=="belt" and 1
    or guide.kind=="outer" and .94 or .88
  local alpha=(mode=="clear" and .78 or .56)*weight
  return {{
    type="sprite",filename=guide.filename,size=guide.size,
    shift=guide.shift,scale=4,priority="extra-high-no-scale",
    flags={"gui-icon"},blend_mode="normal",
    tint={r=color.r,g=color.g,b=color.b,a=alpha}
  }}
end
-- Old midpoint debris motifs looked like additional portals and hazy
-- navigation nodes. Asteroids still spawn along their real native routes.
function M.field_marker() return nil end
function M.data_final_fixes()
  local option=settings and settings.startup
    and settings.startup["razi-route-highlight-style"]
  local mode=option and option.value or "subtle"
  if mode=="off" or (mods and mods["space-route-overlay"]) then return end
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
    local appropriate=route and (route.shape=="line"
      or guide.kind=="belt"
      or (guide.kind=="belt-approach" and mode=="clear"))
    if aligned and appropriate and not existing[guide.filename] then
      for _,layer in ipairs(M.layers_for_guide(
        guide,M.color_for_guide(guide,route),mode)) do
        art.layers[#art.layers+1]=layer
      end
      existing[guide.filename]=true
      painted=painted+1
    end
  end
  if type(log)=="function" then
    log("[Razi Protocol/route-highlights] "..painted..
      " stage-and-danger coloured route guides ("..mode..")")
  end
end
return M
