-- Castra keeps no nests of the vanilla kind: its enemy bases are data collectors that Castra Prime's own script places
-- (castra-prime 0.9.4, control.lua:49 and base-generator.lua), and the map generation of the planet has no enemies.
-- But castra-enemy-tank, the unit of the data collector, is an ordinary unit, so the engine's enemy expansion takes it
-- into settler groups like any biter, and a group that arrives builds a vanilla base on Castra: a biter spawner and
-- worms, which then spawn biters. Castra Prime handles neither on_build_base_arrived nor on_biter_base_built
-- (pauldennis2/castra-prime#9). No prototype field keeps a unit out of expansion, so it is stopped at runtime:
-- * on_build_base_arrived on Castra: the group is broken up before it builds, and its units get the wander command
--   Castra Prime gives its tanks (control.lua:207), so its tank loop (control.lua:169) takes them over again;
-- * on_biter_base_built on Castra, in case a base gets built all the same: the entity is removed;
-- * once per save, the spawners, worms and units that earlier expansions left on Castra are removed.
local M = {}

local SURFACE = "castra"
-- Castra Prime's own spawner and units; anything else of these types on Castra came from expansion.
local CASTRA_SPAWNER = "data-collector"
local CASTRA_TANK = "castra-enemy-tank"
local COLLECTOR_UNIT_PREFIX = "data-collector-"

local function on_castra(object)
	return object ~= nil and object.valid and object.surface.name == SURFACE
end

local function wander(unit)
	local commandable = unit.valid and unit.commandable
	if commandable then
		commandable.set_command({
			type = defines.command.wander,
			distraction = defines.distraction.by_anything,
			ticks_to_wait = math.random(600, 5000)
		})
	end
end

-- Changing the commands of a group inside this event is safe since Factorio 2.1.12.
function M.on_build_base_arrived(event)
	local group = event.group
	if group and group.valid and group.is_unit_group then
		if not on_castra(group) then
			return
		end
		local members = group.members
		group.destroy()
		for _, unit in pairs(members) do
			wander(unit)
		end
	elseif on_castra(event.unit) then
		wander(event.unit)
	end
end

function M.on_biter_base_built(event)
	local entity = event.entity
	if on_castra(entity) and entity.name ~= CASTRA_SPAWNER then
		entity.destroy()
	end
end

local function built_by_expansion(entity)
	if entity.type == "unit-spawner" then
		return entity.name ~= CASTRA_SPAWNER
	elseif entity.type == "unit" then
		return entity.name ~= CASTRA_TANK and entity.name:sub(1, #COLLECTOR_UNIT_PREFIX) ~= COLLECTOR_UNIT_PREFIX
	end
	-- The turrets of Castra are ammo, electric, fluid and artillery turrets; the type "turret" is the worms.
	return entity.type == "turret"
end

-- Returns how many entities were removed.
function M.clear_built_nests()
	if storage.castra_expansion_nests_cleared then
		return 0
	end
	storage.castra_expansion_nests_cleared = true
	local surface = game.surfaces[SURFACE]
	if not surface then
		return 0
	end

	local removed = 0
	for _, entity in pairs(surface.find_entities_filtered({type = {"unit-spawner", "turret", "unit"}})) do
		if entity.valid and built_by_expansion(entity) then
			entity.destroy()
			removed = removed + 1
		end
	end
	if removed > 0 then
		log("razi-protocol: removed " .. removed .. " spawners, worms and units that enemy expansion built on Castra")
	end
	return removed
end

return M
