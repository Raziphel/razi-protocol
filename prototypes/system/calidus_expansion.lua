-- A compact salvage stop for the Calidus/Nauvis home system.
-- Muluna remains the required landable moon; Eneas is still optional.
local M = {}
local hazards = require("prototypes.system.asteroid_profiles")
M.name = "razi-calidus-drift"

function M.data()
  if (data.raw["space-location"] or {})[M.name] then return end
  PlanetsLib:extend({
    {
      type = "space-location",
      name = M.name,
      localised_name = {"space-location-name." .. M.name},
      localised_description = {"space-location-description." .. M.name},
      icon = "__razi-protocol__/graphics/icons/routes/asteroid-route.png",
      icon_size = 64,
      starmap_icon = "__razi-protocol__/graphics/icons/routes/asteroid-route.png",
      starmap_icon_size = 64,
      solar_power_in_space = 25,
      draw_orbit = false,
      asteroid_spawn_definitions = hazards.belt_edge_resources(0.55),
      orbit = {
        parent = {type = "space-location", name = "star"},
        distance = 33,
        orientation = 0.865
      }
    }
  })
end

function M.data_final_fixes()
  if not ((data.raw["space-location"] or {})[M.name]) then return false end
  local techs=data.raw.technology or {}
  -- The first lunar space science opens a modest orbital supply choice.
  -- This never becomes a prerequisite for another destination.
  local tech=techs["space-science-pack"] or techs["planet-discovery-muluna"]
  if not tech then
    if type(log)=="function" then
      log("[Razi Protocol/Calidus] Missing source tech for drift unlock")
    end
    return false
  end
  tech.effects=tech.effects or {}
  for _,effect in ipairs(tech.effects) do
    if effect.type=="unlock-space-location" and
        effect.space_location==M.name then return true end
  end
  tech.effects[#tech.effects+1]={
    type="unlock-space-location",space_location=M.name,
    use_icon_overlay_constant=true
  }
  return true
end
return M
