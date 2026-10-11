-- MrLumme's Asteroid Belt is a REQUIRED progression feature. Keep its
-- native collision/ore encounter and science unlock, but attach its two
-- gateway locations to Razi's campaign instead of its original solar ring.
local M = {}

local function get_location(name)
  if (data.raw["space-location"] or {})[name] then
    return "space-location", data.raw["space-location"][name]
  end
  if (data.raw.planet or {})[name] then
    return "planet", data.raw.planet[name]
  end
  return nil
end

function M.data_final_fixes()
  -- This should always be installed via info.json; defensive guards prevent
  -- optional upstream prototype changes from causing a PlanetsLib nil crash.
  if not mods["AsteroidBelt"] then return end
  if not (data.raw["space-location"] or {}).star then return end
  local updates = {}
  local coords = {
    {"asteroid-belt-inner-edge",128.887548,0.633736},
    {"asteroid-belt-outer-edge",135.69451,0.667812}
  }
  for _, item in ipairs(coords) do
    local kind = get_location(item[1])
    if kind then
      updates[#updates+1] = {
        type=kind, name=item[1], draw_orbit=false,
        orbit={
          parent={type="space-location",name="star"},
          distance=item[2],orientation=item[3]
        }
      }
    end
  end
  if #updates>0 then PlanetsLib:update(updates) end
  for _, item in ipairs(coords) do
    local _, location = get_location(item[1])
    if location then location.draw_orbit=false end
  end

  -- Restore the actual upstream asteroid sprite, scaled to a subtle halo.
  local util=(data.raw["utility-sprites"] or {}).default
  local sprite=util and util.starmap_star
  for _,layer in ipairs((sprite and sprite.layers) or {}) do
    if type(layer)=="table" and
      layer.filename=="__AsteroidBelt__/graphics/sprite/asteroid-belt.png" then
      layer.scale=0.28
    end
  end
end

return M
