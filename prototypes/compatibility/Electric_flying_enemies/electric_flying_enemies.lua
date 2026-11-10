local enemy_autoplace = require("prototypes.compatibility.common.enemy_autoplace")
local enemy_homes = require("prototypes.compatibility.common.enemy_homes")

if not enemy_autoplace.enabled() or not mods["Electric_flying_enemies"] then
	return
end

local electric_enemy_tiles = {
	"fulgoran-dust",
	"fulgoran-rock",
	"fulgoran-conduit",
	"fulgoran-machinery",
	"oil-ocean-shallow",
	"oil-ocean-deep",
	"fulgoran-space-platform",
	"ribbonia-gap",
	"ribbonia-water",
	"ribbonia-void",
	"dirt-1",
	"dirt-2",
	"dirt-3",
	"dirt-4",
	"dirt-5",
	"dirt-6",
	"dirt-7",
	"grass-1",
	"grass-2",
	"grass-3",
	"grass-4",
	"red-desert-0",
	"red-desert-1",
	"red-desert-2",
	"red-desert-3",
	"dry-dirt",
	"sand-1",
	"sand-2",
	"sand-3"
}

-- Only the spawners of Electric flying enemies themselves, by name: spawners of other mods are not ours to move
-- (Fulgora Replicators' crawler and carrier have an autoplace on Fulgora tied to that mod's own script).
local electric_spawner_names = {
	"flying-electric-unit-spawner",
	"walker-electric-unit-spawner"
}

local function entity_exists(entity_name)
	return data.raw["unit-spawner"] and data.raw["unit-spawner"][entity_name]
end

local function add_unique(values, value)
	for _, existing in pairs(values) do
		if existing == value then
			return
		end
	end

	table.insert(values, value)
end

local function extend_tile_restriction(spawner)
	spawner.autoplace.tile_restriction = spawner.autoplace.tile_restriction or {}

	for _, tile_name in pairs(enemy_autoplace.existing_tiles(electric_enemy_tiles)) do
		add_unique(spawner.autoplace.tile_restriction, tile_name)
	end

	-- The land of the homes that are not the mod's own (Corrundum with Fulgora Replicators).
	for _, tile_name in ipairs(enemy_homes.tiles("electric")) do
		add_unique(spawner.autoplace.tile_restriction, tile_name)
	end
end

local function collect_electric_spawners()
	local spawners = {}

	for _, entity_name in ipairs(electric_spawner_names) do
		local spawner = entity_exists(entity_name)
		if enemy_autoplace.has_valid_autoplace(spawner) then
			spawners[entity_name] = spawner
		end
	end

	return spawners
end

local function add_electric_enemies_to_planet(planet_name, spawners)
	if not next(spawners) then
		return
	end

	for entity_name, spawner in pairs(spawners) do
		local control = spawner.autoplace and spawner.autoplace.control or "enemy-base"
		local entity_settings = enemy_autoplace.prepare_custom_enemy_planet(planet_name, control)
		if entity_settings then
			entity_settings[entity_name] = {}
		end
	end
end

local electric_spawners = collect_electric_spawners()

for _, spawner in pairs(electric_spawners) do
	extend_tile_restriction(spawner)
end

for _, planet_name in pairs(enemy_homes.planets("electric")) do
	add_electric_enemies_to_planet(planet_name, electric_spawners)
end

-- The Electric mod's own nests on Fulgora are switched off when Fulgora is no home: without homes (Easy), and with
-- Fulgora Replicators on every step.
local placed_names = {}
for entity_name in pairs(electric_spawners) do
	placed_names[#placed_names + 1] = entity_name
end
table.sort(placed_names)
enemy_homes.switch_off_native("electric", placed_names)
