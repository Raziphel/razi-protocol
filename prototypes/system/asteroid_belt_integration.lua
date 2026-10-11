-- Required MrLumme Asteroid Belt. Its native 5,000 km crossing,
-- difficulty, mining, and science are source-owned; only the visual home of
-- the crossing and its two gateway markers are repositioned here.
--
-- Instead of encircling starting Nauvis, the ring now surrounds Shchierbin,
-- the existing Vibrant midgame planet feeding the mandatory frontier.
local M = {}

local HOST = "shchierbin"
local SOURCE_SPRITE = "__AsteroidBelt__/graphics/sprite/asteroid-belt.png"
local RING_SCALE = 0.55
local STARMAP_PIXELS_PER_UNIT = 32

local coords = {
  -- Radial crossing through the northern asteroid band around Shchierbin.
  -- Inner edge is just inside the debris; outer edge is just outside.
  -- Both use the native Factorio orientation zero (north).
  {"asteroid-belt-inner-edge",14,0},
  {"asteroid-belt-outer-edge",20,0}
}

local function get_location(name)
  if (data.raw["space-location"] or {})[name] then
    return "space-location",data.raw["space-location"][name]
  end
  if (data.raw.planet or {})[name] then
    return "planet",data.raw.planet[name]
  end
  return nil
end

function M.data_final_fixes()
  if not mods["AsteroidBelt"] then return end
  local host_type = get_location(HOST)
  if host_type~="planet" then
    error("Razi Protocol: required Shchierbin planet is missing; cannot attach the mandatory Asteroid Belt")
  end

  local updates={}
  for _,item in ipairs(coords) do
    local kind=get_location(item[1])
    if kind then
      updates[#updates+1]={
        type=kind,name=item[1],draw_orbit=false,
        orbit={
          parent={type="planet",name=HOST},
          distance=item[2],orientation=item[3]
        }
      }
    end
  end
  if #updates>0 then PlanetsLib:update(updates) end
  for _,item in ipairs(coords) do
    local _,location=get_location(item[1])
    if location then location.draw_orbit=false end
  end

  -- AsteroidBelt inserts its sprite in utility-sprites.starmap_star at
  -- source data-final-fixes. Reposition exactly that layer, leaving its
  -- contents and every unrelated star/background layer unchanged.
  -- IMPORTANT: use Razi's *final intended* Shchierbin position, not its
  -- source position before the galaxy layout final-fixes stage.
  local layout=require("prototypes.system.galaxy_layout")
  local cx,cy=layout.anchor_position(HOST)
  if not cx then
    error("Razi Protocol: Shchierbin has no starmap layout position")
  end
  local shift_x=cx*STARMAP_PIXELS_PER_UNIT
  local shift_y=cy*STARMAP_PIXELS_PER_UNIT
  local utility=(data.raw["utility-sprites"] or {}).default
  local sprite=utility and utility.starmap_star
  for _,layer in ipairs((sprite and sprite.layers) or {}) do
    if type(layer)=="table" and layer.filename==SOURCE_SPRITE then
      layer.scale=RING_SCALE
      layer.shift={shift_x,shift_y}
    end
  end
  if type(log)=="function" then
    log(string.format(
      "[Razi Protocol/asteroid-belt] Ring around Shchierbin at (%.2f,%.2f), scale %.2f",
      cx,cy,RING_SCALE))
  end
end

return M
