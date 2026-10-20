local enemy_autoplace = require("prototypes.compat.enemy_autoplace")

if not enemy_autoplace.enabled() or not mods["Cold_biters"] then
	return
end

local cold_enemy_control = "frost_enemy_base"

local cold_enemy_autoplace = {
	["cb-cold-spawner"] = {type = "unit-spawner", distance = 0, worm = false},
	["small-cold-worm-turret"] = {type = "turret", distance = 0, worm = true},
	["medium-cold-worm-turret"] = {type = "turret", distance = 2, worm = true},
	["big-cold-worm-turret"] = {type = "turret", distance = 5, worm = true},
	["behemoth-cold-worm-turret"] = {type = "turret", distance = 8, worm = true},
	["leviathan-cold-worm-turret"] = {type = "turret", distance = 10, worm = true},
	["mother-cold-worm-turret"] = {type = "turret", distance = 14, worm = true}
}

local cold_planets = {
	"aquilo",
	"paracelsin",
	"frozeta",
	"nexus",
	"shchierbin",
	"vesta"
}

local cold_source_planets = {
	"nauvis"
}

local function cold_autoplace_expression(distance, worm)
	local expression = "cb_enemy_autoplace_base(" .. distance .. ", " .. (42000 + distance) .. ")"
	if worm then
		return "(" .. expression .. ") * (1 - no_enemies_mode)"
	end

	return expression
end

local function restrict_entity_to_cold_tiles(entity_type, entity_name, distance, worm)
	local entity = data.raw[entity_type] and data.raw[entity_type][entity_name]
	if entity then
		entity.autoplace = entity.autoplace or {}
		-- The source mod's valid expression belongs to that mod. Only
		-- supply a fallback for forks whose autoplace is incomplete.
		if entity.autoplace.probability_expression == nil then
			entity.autoplace.control = cold_enemy_control
			entity.autoplace.order = worm and "b[enemy]-b[worm]" or "b[enemy]-a[spawner]"
			entity.autoplace.force = "enemy"
			entity.autoplace.probability_expression = cold_autoplace_expression(distance, worm)
			entity.autoplace.richness_expression = 1
		end
		-- Never union or overwrite source tile restrictions globally.
		-- Final ecology owns planet-specific cold nest variants.
	end
end

-- Existing cold nests keep their source placement; RP3 introduces
-- separate planet-local nests at data-final-fixes according to difficulty.
for name,spec in pairs(cold_enemy_autoplace) do
  restrict_entity_to_cold_tiles(spec.type,name,spec.distance,spec.worm)
end
