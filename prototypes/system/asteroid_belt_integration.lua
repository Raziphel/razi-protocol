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
    {"asteroid-belt-inner-edge",177},
    {"asteroid-belt-outer-edge",191}
  }
  for _, item in ipairs(coords) do
    local kind = get_location(item[1])
    if kind then
      updates[#updates+1] = {
        type=kind, name=item[1], draw_orbit=false,
        orbit={
          parent={type="space-location",name="star"},
          distance=item[2],orientation=0.5
        }
      }
    end
  end
  if #updates>0 then PlanetsLib:update(updates) end
  for _, item in ipairs(coords) do
    local _, location = get_location(item[1])
    if location then location.draw_orbit=false end
  end

  -- The source draws a giant 2436px ring over the original solar system.
  -- Our native belt crossing is now BETWEEN the middle and outer systems,
  -- so an origin-centred background ring would be misleading and cluttered.
  -- Remove *only* its ring layer, not its item icons, starmap icons, or
  -- unrelated star/background layers from other mods.
  local utility = (data.raw["utility-sprites"] or {}).default
  local sprite = utility and utility.starmap_star
  local layers = sprite and sprite.layers
  if type(layers)=="table" then
    for i=#layers,1,-1 do
      local layer=layers[i]
      if type(layer)=="table" and
        layer.filename=="__AsteroidBelt__/graphics/sprite/asteroid-belt.png" then
        table.remove(layers,i)
      end
    end
  end
end

return M
