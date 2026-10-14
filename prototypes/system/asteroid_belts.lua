-- Belt entrances and hazards for Vibrant, Vespera and Umbra.
-- Keep the old Vibrant IDs so existing saves still find their waypoints.
local hazards=require("prototypes.system.asteroid_profiles")
local icon="__space-age__/graphics/icons/solar-system-edge.png"
local belts={
  {system="vibrant",solar=35,intensity=1.18,legacy=true},
  {system="vespera",solar=23,intensity=1.40},
  {system="umbra",solar=17,intensity=1.85}
}
local locations={}
for _,belt in ipairs(belts) do
  for _,edge in ipairs({"inner","outer"}) do
    local legacy=belt.legacy
    local name=legacy and "asteroid-belt-"..edge.."-edge"
      or "razi-"..belt.system.."-belt-"..edge
    local radius,turn
    if legacy then
      radius=edge=="inner" and 31 or 39
      turn=edge=="inner" and 0.08 or 0.095
    else
      local distance=belt.system=="vespera" and 22.0 or 22.3
      local bearing=belt.system=="vespera" and 0.32 or 0.21
      local offset=edge=="inner" and -1 or 1
      radius=distance+offset*1.1
      turn=bearing+offset*0.015
    end
    locations[#locations+1]={
      type="space-location",name=name,
      localised_name={"space-location-name."..name},
      localised_description={"space-location-description."..name},
      icon=icon,icon_size=64,starmap_icon=icon,starmap_icon_size=64,
      draw_orbit=false,solar_power_in_space=belt.solar,
      asteroid_spawn_definitions=hazards.belt_edge_resources(belt.intensity,belt.system),
      orbit={parent={type="space-location",name=belt.system},
        distance=radius,orientation=turn}
    }
  end
end
PlanetsLib:extend(locations)
-- Legacy prototype name and endpoints remain stable across an upgrade.
data:extend({{
  type="space-connection",
  name="asteroid-belt-inner-edge-asteroid-belt-outer-edge",
  from="asteroid-belt-inner-edge",to="asteroid-belt-outer-edge",
  length=5000,shape="line",
  icon=icon,icon_size=64,
  asteroid_spawn_definitions=hazards.create("belt_vibrant_crossing")
}})
return true
