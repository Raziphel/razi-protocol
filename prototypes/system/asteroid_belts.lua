-- Two original Razi asteroid belts, inspired by the Asteroid Belt mod's
-- dangerous crossing and resource-rich edge design. No upstream sprites or
-- scripts are redistributed and the original one-star mod is not required.
local hazards = require("prototypes.system.asteroid_profiles")
local icon = "__space-age__/graphics/icons/solar-system-edge.png"
local belts = {
  {system="vespera", label="Vespera", orbit=22.0, bearing=0.32, solar=23, intensity=1.40},
  {system="umbra", label="Umbra", orbit=22.3, bearing=0.21, solar=17, intensity=1.85}
}
local locations = {}
for _, belt in ipairs(belts) do
  for _, edge in ipairs({"inner", "outer"}) do
    local offset = edge == "inner" and -1 or 1
    locations[#locations+1] = {
      type="space-location",
      name="razi-"..belt.system.."-belt-"..edge,
      localised_name={"space-location-name.razi-"..belt.system.."-belt-"..edge},
      icon=icon,
      starmap_icon=icon,
      starmap_icon_size=64,
      draw_orbit=false,
      solar_power_in_space=belt.solar,
      asteroid_spawn_definitions=hazards.belt_edge_resources(belt.intensity),
      orbit={
        parent={type="space-location", name=belt.system},
        distance=belt.orbit + offset*1.1,
        orientation=belt.bearing + offset*0.015
      }
    }
  end
end
PlanetsLib:extend(locations)
return true
