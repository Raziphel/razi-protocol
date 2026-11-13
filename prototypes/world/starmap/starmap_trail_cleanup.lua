-- Remove stale Carna/Velora PlanetsLib orbit decorations and sprites from
-- Orbital Catapult's independent starmap compositor. Do not remove real
-- space connections, catapult travel definitions, prototypes or surfaces.
local M={}

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

function M.remove_layers(layers)
	if type(layers)~="table" then return 0,{catapult=0,orbit=0} end
	local count,detail=0,{catapult=0,orbit=0}
  for i=#layers,1,-1 do
    local layer=layers[i]
    local reason
    if type(layer)=="table" then
      if is_catapult_sprite(asset_path(layer)) then
        reason="catapult"
      elseif is_old_orbit_art(layer) then
        reason="orbit"
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
	local removed,detail=M.remove_layers(layers)
  if type(log)=="function" then
    log(string.format(
      "[Razi Protocol/starmap] Final catapult and old-orbit cleanup: removed %d sprite layers (catapult=%d, old orbit=%d); transit data unchanged",
      removed,detail.catapult,detail.orbit))
  end
  return removed
end
return M
