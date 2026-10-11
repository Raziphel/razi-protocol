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
    {"asteroid-belt-inner-edge",26,0},
    {"asteroid-belt-outer-edge",34,0}
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

  -- Full-size source sprite: the visual halo has a radius of roughly 30
  -- starmap units in-game. Place one native crossing node just inside and
  -- one just outside that ring, instead of 48/62 units far above its edge.
  -- The original AsteroidBelt artwork, hazards and 5000-km trip are unchanged.
  local util=(data.raw["utility-sprites"] or {}).default
  local sprite=util and util.starmap_star
  for _,layer in ipairs((sprite and sprite.layers) or {}) do
    if type(layer)=="table" and
      layer.filename=="__AsteroidBelt__/graphics/sprite/asteroid-belt.png" then
      layer.scale=1.0
    end
  end
end

return M
