-- Krastorio 2 radiation that hurts the vehicle of a player instead of the player.
--
-- Krastorio2 2.1.4 (scripts/radioactivity.lua:120-123) damages a player who carries uranium or stands near
-- uranium ore with player.character.damage(7.25, "enemy", "kr-radioactive"). A character in a vehicle passes that
-- damage on to the vehicle, so a car, locomotive or spidertron with such a driver slowly dies while the driver stays
-- unharmed (reported upstream as issue 754, open). The vehicle gets the damage back.
--
-- Only damage that has no cause and no source is returned. Krastorio 2 deals the radiation without either; weapons
-- (uranium cannon shells, Krastorio2 prototypes/updates/base/ammo.lua:73) hit with a shooter or a projectile, and an
-- enemy vehicle hit by them keeps its damage.
--
-- Cost: the engine applies the two filters below, so the handler runs only for damage of the "kr-radioactive" type
-- done to a vehicle, once a second per irradiated driver at most. It touches no save data.
--
-- Remove this module when Krastorio 2 stops damaging the vehicle.

local vehicle_radiation = {}

local MOD_NAME = "Krastorio2"
local DAMAGE_TYPE = "kr-radioactive"

local logged = false

-- Whether the handler is needed: Krastorio 2 is loaded and its damage type exists.
---@return boolean
function vehicle_radiation.is_needed()
	return script.active_mods[MOD_NAME] ~= nil and prototypes ~= nil and prototypes.damage[DAMAGE_TYPE] ~= nil
end

-- Vehicles only, and only radiation: "mode" and joins the second filter to the first.
---@return table[]
function vehicle_radiation.filters()
	return {
		{filter = "vehicle"},
		{filter = "damage-type", type = DAMAGE_TYPE, mode = "and"}
	}
end

---@param event table on_entity_damaged
function vehicle_radiation.on_entity_damaged(event)
	if event.cause or event.source then
		return
	end
	local vehicle = event.entity
	if vehicle.valid and vehicle.health then
		-- Setting the health directly raises no damage event, so this cannot loop.
		vehicle.health = vehicle.health + event.final_damage_amount
		if not logged then
			logged = true
			log("razi-protocol: gave the radiation damage back to a vehicle with a driver (" .. vehicle.name .. ")")
		end
	end
end

return vehicle_radiation
