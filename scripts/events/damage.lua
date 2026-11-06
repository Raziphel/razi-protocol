-- Damage events. Nothing is registered unless a mod below needs it: on_entity_damaged is one of the busiest events.
local vehicle_radiation = require("scripts.compatibility.Krastorio2.vehicle_radiation")

local damage = {}

function damage.register(events)
	-- Krastorio 2: the radiation that hurts the player is taken by the vehicle.
	if vehicle_radiation.is_needed() then
		events:on_event(defines.events.on_entity_damaged, vehicle_radiation.on_entity_damaged)
	end
end

-- Filters must be set after the registration they belong to. They apply to every handler on the event, so a feature
-- that needs other damage must widen this filter rather than add its own registration.
function damage.set_filters()
	if vehicle_radiation.is_needed() then
		script.set_event_filter(defines.events.on_entity_damaged, vehicle_radiation.filters())
	end
end

return damage
