local enemy_autoplace = {}

local vanilla_enemy_entities = {
	"biter-spawner",
	"spitter-spawner",
	"small-worm-turret",
	"medium-worm-turret",
	"big-worm-turret",
	"behemoth-worm-turret"
}

local function planet_entity_settings(planet_name)
	local planet = data.raw.planet and data.raw.planet[planet_name]
	local map_gen_settings = planet and planet.map_gen_settings
	if not map_gen_settings then
		return nil
	end

	map_gen_settings.autoplace_settings = map_gen_settings.autoplace_settings or {}
	map_gen_settings.autoplace_settings.entity = map_gen_settings.autoplace_settings.entity or {}
	map_gen_settings.autoplace_settings.entity.settings = map_gen_settings.autoplace_settings.entity.settings or {}

	return map_gen_settings.autoplace_settings.entity.settings
end

function enemy_autoplace.disable_vanilla_enemies_on_planet(planet_name)
	local entity_settings = planet_entity_settings(planet_name)
	if not entity_settings then
		return
	end

	for _, entity_name in pairs(vanilla_enemy_entities) do
		if
			(data.raw["unit-spawner"] and data.raw["unit-spawner"][entity_name]) or
			(data.raw.turret and data.raw.turret[entity_name])
		then
			entity_settings[entity_name] = {
				frequency = 0,
				size = 0,
				richness = 0
			}
		end
	end
end

return enemy_autoplace
