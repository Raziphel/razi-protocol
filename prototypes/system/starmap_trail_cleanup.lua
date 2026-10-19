-- Final visual-only cleanup for the stray two-row red dotted ribbons near
-- Carna and Velora. The previous fixes removed native orbit.sprite and
-- Razi route overlays, but these trails can also be painted by the installed
-- Orbital Catapult's independent starmap compositor. Do not remove real
-- space connections, catapult travel definitions, prototypes or surfaces.
local M={}

local RAZI_STROKES="__razi-protocol__/graphics/route-highlights/directional-strokes.png"
local unwanted_orbits={carna=true,velora=true}
local function asset_path(layer)
  if type(layer)~="table" then return nil end
  if type(layer.filename)=="string" then return layer.filename end
  -- Some Factorio sprite definitions store files in stripes instead.
  for _,stripe in ipairs(layer.stripes or {}) do
    if type(stripe.filename)=="string" then return stripe.filename end
  end
  if type(layer.filenames)=="table" then
    for _,file in ipairs(layer.filenames) do
      if type(file)=="string" then return file end
    end
  end
end

local function is_catapult_sprite(path)
  if type(path)~="string" then return false end
  -- A dedicated module owns these sprite files. The filter is deliberately
  -- independent of drawing coordinates because relocated star/planet
  -- positions can leave the source decoration somewhere else on the map.
  return path:find("__orbital-cannon__/",1,true)~=nil
    or path:find("__orbital_cannon__/",1,true)~=nil
end
M.is_catapult_sprite=is_catapult_sprite

local function is_old_orbit_art(layer)
  return unwanted_orbits[layer.planetslib_orbit_name]==true
end

-- Some old route artworks were left as free-floating tinted sprites rather
-- than tagged PlanetsLib layers. Remove only vividly red Razi source strokes
-- in the immediate vicinity of those two worlds, not whole-system belts.
local function is_dangling_razi_stroke(layer,centers)
  if asset_path(layer)~=RAZI_STROKES then return false end
  local tint=layer.tint or {}
  if type(tint.r)~="number" or type(tint.g)~="number"
    or tint.r<.7 or tint.r<tint.g*1.45 then return false end
  local shift=layer.shift or {}
  local x,y=shift.x or shift[1],shift.y or shift[2]
  if type(x)~="number" or type(y)~="number" then return false end
  for _,center in ipairs(centers) do
    local dx,dy=x/32-center.x,y/32-center.y
    if dx*dx+dy*dy<=16*16 then return true end
  end
  return false
end

local function position(name)
  local planet=(data.raw.planet or {})[name]
    or (data.raw["space-location"] or {})[name]
  if not planet then return nil end
  local origin=planet.origin or {}
  local x,y=origin.x or origin[1] or 0,origin.y or origin[2] or 0
  if type(planet.distance)=="number"
    and type(planet.orientation)=="number" then
    return {x=x+planet.distance*math.sin(2*math.pi*planet.orientation),
      y=y-planet.distance*math.cos(2*math.pi*planet.orientation)}
  end
end

function M.remove_layers(layers,centers)
  if type(layers)~="table" then return 0,{catapult=0,orbit=0,strokes=0} end
  centers=centers or {}
  local count,detail=0,{catapult=0,orbit=0,strokes=0}
  for i=#layers,1,-1 do
    local layer=layers[i]
    local reason
    if type(layer)=="table" then
      if is_catapult_sprite(asset_path(layer)) then
        reason="catapult"
      elseif is_old_orbit_art(layer) then
        reason="orbit"
      elseif is_dangling_razi_stroke(layer,centers) then
        reason="strokes"
      end
    end
    if reason then
      table.remove(layers,i)
      detail[reason]=detail[reason]+1
      count=count+1
    end
  end
  return count,detail
end

function M.data_final_fixes()
  local ui=(data.raw["utility-sprites"] or {}).default
  local layers=ui and ui.starmap_star and ui.starmap_star.layers
  local centers={}
  for _,name in ipairs({"carna","velora"}) do
    local p=position(name)
    if p then centers[#centers+1]=p end
  end
  local removed,detail=M.remove_layers(layers,centers)
  if type(log)=="function" then
    log(string.format(
      "[Razi Protocol/starmap] Final red-trail cleanup: removed %d sprite layers (catapult=%d, old orbit=%d, local red strokes=%d); transit data unchanged",
      removed,detail.catapult,detail.orbit,detail.strokes))
  end
  return removed
end
return M
