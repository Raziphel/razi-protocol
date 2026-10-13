-- The colored lines sit over existing Space Age routes.
-- They don't add connections or change how travel unlocks.
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

-- Three carefully aligned strokes reuse the original route mask.
-- Broad, very faint bloom -> inner halo -> crisp navigable line.
-- Outer lanes and dangerous belt crossings have more visual weight,
-- without changing engine-owned route shape, discoverability or hazards.
local guide_weights={
  first=.93,middle=1,outer=1.10,belt=1.25,["belt-approach"]=.82
}
function M.layers_for_guide(guide,color,mode)
  local clear=mode=="clear"
  local weight=guide_weights[guide.kind] or 1
  local function layer(scale,alpha)
    return {type="sprite",filename=guide.filename,size=guide.size,
      shift=guide.shift,scale=scale,priority="extra-high-no-scale",
      flags={"gui-icon"},blend_mode="normal",
      tint={r=color.r,g=color.g,b=color.b,a=alpha*weight}}
  end
  return {
    layer(4.084,clear and .04 or .018),
    layer(4.029,clear and .12 or .06),
    layer(4,clear and .45 or .27)
  }
end
-- Quiet pockets of debris at the halfway point of selected REAL routes.
-- Uses existing Razi texture art, never draws fictitious route lines.
local field_art={
  ["sye-solaris|sye-vibrant"]={image="debris-vibrant.png",tint={r=.69,g=.60,b=.98}},
  ["sye-nyxaris|sye-vespera"]={image="debris-vespera.png",tint={r=.46,g=.83,b=1}},
  ["sye-beetlejuice|sye-umbra"]={image="debris-umbra.png",tint={r=.92,g=.49,b=.65}},
  ["secretas|solar-system-edge"]={image="rift-deep-space.png",tint={r=.57,g=.65,b=1}}
}
function M.field_marker(guide,mode)
  local art=field_art[key(guide.from,guide.to)]
  if not art then return nil end
  return {
    type="sprite",
    filename="__razi-protocol__/graphics/starmap/razi/"..art.image,
    size={512,512},scale=1.7,
    shift={((guide.start[1]+guide.finish[1])/2)*32,
      ((guide.start[2]+guide.finish[2])/2)*32},
    priority="extra-high-no-scale",flags={"gui-icon"},blend_mode="normal",
    tint={r=art.tint.r,g=art.tint.g,b=art.tint.b,
      a=mode=="clear" and .12 or .06}
  }
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
  -- Data-final-fixes can be invoked twice by integration tools; preserve
  -- one set of route light sprites per original mask filename.
  local existing={}
  for _,layer in ipairs(art.layers) do
    if layer.filename then existing[layer.filename]=true end
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
    if aligned and appropriate and not existing[guide.filename] then
      -- Placed UNDER the corresponding route spine. The original mask
      -- remains accurate, and the dust cannot invent a traversable edge.
      local marker=M.field_marker(guide,mode)
      if marker then art.layers[#art.layers+1]=marker end
      local c=hazards.color(route)
      for _,layer in ipairs(M.layers_for_guide(guide,c,mode)) do
        art.layers[#art.layers+1]=layer
      end
      existing[guide.filename]=true
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
