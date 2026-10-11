-- Risk-colored expedition lines over matching native starmap connections.
-- This is sprite-only artwork; the travel graph, hover targets, and unlocks
-- remain entirely Factorio-owned. Unknown/moved routes are never overdrawn.
local M = {}
local manifest = require("prototypes.system.route_highlight_manifest")
local hazards = require("prototypes.system.route_hazards")

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
  if radius==nil and location.orbit then radius=location.orbit.distance end
  local angle=location.orientation
  if angle==nil and location.orbit then angle=location.orbit.orientation end
  if type(radius)~="number" or type(angle)~="number" then return end
  local radians=2*math.pi*angle
  return {(origin.x or origin[1] or 0)+radius*math.sin(radians),
          (origin.y or origin[2] or 0)-radius*math.cos(radians)}
end

function M.data_final_fixes()
  local option=settings and settings.startup
    and settings.startup["razi-route-highlight-style"]
  local mode=option and option.value or "subtle"
  if mode=="off" or (mods and mods["space-route-overlay"]) then return end
  local utilities=(data.raw["utility-sprites"] or {}).default
  local art=utilities and utilities.starmap_star
  if not (art and art.layers) then return end
  local routes={}
  for _,route in pairs(data.raw["space-connection"] or {}) do
    if route.from and route.to then routes[key(route.from,route.to)]=route end
  end
  local painted,skipped=0,0
  for _,guide in ipairs(manifest) do
    local route=routes[key(guide.from,guide.to)]
    local p,q=current_position(guide.from),current_position(guide.to)
    local aligned=p and q
      and math.abs(p[1]-guide.start[1])<1.5
      and math.abs(p[2]-guide.start[2])<1.5
      and math.abs(q[1]-guide.finish[1])<1.5
      and math.abs(q[2]-guide.finish[2])<1.5
    -- Do not paint a straight guide over a native arc. The hand-matched
    -- central belt mask is the sole exception, and an approach is clear-only.
    local appropriate=route and (route.shape=="line"
      or guide.kind=="belt"
      or (guide.kind=="belt-approach" and mode=="clear"))
    if aligned and appropriate then
      local c=hazards.color(route)
      art.layers[#art.layers+1]={
        type="sprite",filename=guide.filename,size=guide.size,
        shift=guide.shift,scale=4,priority="extra-high-no-scale",
        flags={"gui-icon"},blend_mode="normal",
        tint={r=c.r,g=c.g,b=c.b,a=mode=="clear" and 0.60 or 0.33}
      }
      painted=painted+1
    else
      skipped=skipped+1
    end
  end
  if type(log)=="function" then
    log("[Razi Protocol/route-highlights] guides "..painted..
      " rendered; "..skipped.." skipped (arc, missing or relocated)")
  end
end
return M
