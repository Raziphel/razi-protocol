local armoured_biter_units = {
	["small-armoured-biter"] = true,
	["medium-armoured-biter"] = true,
	["big-armoured-biter"] = true,
	["behemoth-armoured-biter"] = true,
	["leviathan-armoured-biter"] = true
}

local armoured_biter_tiles = {
	"panglia-volcanic-soil-dark",
	"panglia-volcanic-soil-light",
	"panglia-volcanic-ash-soil",
	"panglia-volcanic-ash-flats",
	"panglia-volcanic-ash-light",
	"panglia-volcanic-ash-dark",
	"panglia-volcanic-cracks",
	"panglia-volcanic-cracks-warm",
	"panglia-volcanic-folds",
	"panglia-volcanic-folds-flat",
	"panglia-volcanic-folds-warm",
	"panglia-volcanic-pumice-stones",
	"panglia-volcanic-cracks-hot",
	"panglia-volcanic-jagged-ground",
	"panglia-volcanic-smooth-stone",
	"panglia-volcanic-smooth-stone-warm",
	"panglia-volcanic-ash-cracks",
	"panglia-midland-turquoise-bark",
	"panglia-midland-turquoise-bark-2",
	"panglia-wetland-light-dead-skin",
	"panglia-wetland-dead-skin",
	"panglia-midland-cracked-lichen-dark",
	"hyarion-jagged-ground",
	"hyarion-cracks-hot",
	"hyarion-cracks-warm",
	"hyarion-cracks",
	"hyarion-folds-flat",
	"hyarion-crystal-light",
	"hyarion-crystal-dark",
	"hyarion-crystal-flats",
	"hyarion-pumice-stones",
	"hyarion-smooth-stone",
	"hyarion-smooth-stone-warm",
	"hyarion-crystal-cracks",
	"hyarion-folds",
	"hyarion-folds-warm",
	"hyarion-soil-dark",
	"hyarion-soil-light",
	"hyarion-crystal-soil",
	"volcanic-soil-dark",
	"volcanic-soil-light",
	"volcanic-ash-soil",
	"volcanic-ash-flats",
	"volcanic-ash-light",
	"volcanic-ash-dark",
	"volcanic-cracks",
	"volcanic-cracks-warm",
	"volcanic-folds",
	"volcanic-folds-flat",
	"volcanic-folds-warm",
	"volcanic-pumice-stones",
	"volcanic-cracks-hot",
	"volcanic-jagged-ground",
	"volcanic-smooth-stone",
	"volcanic-smooth-stone-warm",
	"volcanic-ash-cracks"
}

local function remove_armoured_units_from_spawner(spawner)
	if not spawner or not spawner.result_units then
		return
	end

	local result_units = {}
	for _, result_unit in pairs(spawner.result_units) do
		if not armoured_biter_units[result_unit[1]] then
			table.insert(result_units, result_unit)
		end
	end

	spawner.result_units = result_units
end

local function add_spawner_to_planet(planet_name, spawner_name)
	local planet = data.raw.planet[planet_name]
	if not planet or not planet.map_gen_settings then
		return
	end

	local map_gen_settings = planet.map_gen_settings
	map_gen_settings.autoplace_controls = map_gen_settings.autoplace_controls or {}
	map_gen_settings.autoplace_controls["enemy-base"] = {
		frequency = 1,
		size = 1,
		richness = 1
	}

	map_gen_settings.autoplace_settings = map_gen_settings.autoplace_settings or {}
	map_gen_settings.autoplace_settings.entity = map_gen_settings.autoplace_settings.entity or {}
	map_gen_settings.autoplace_settings.entity.settings = map_gen_settings.autoplace_settings.entity.settings or {}
	map_gen_settings.autoplace_settings.entity.settings[spawner_name] = {}
end

local armoured_spawner = data.raw["unit-spawner"]["armoured-biter-spawner"]

remove_armoured_units_from_spawner(data.raw["unit-spawner"]["biter-spawner"])

if armoured_spawner then
	armoured_spawner.autoplace = armoured_spawner.autoplace or {}
	armoured_spawner.autoplace.tile_restriction = armoured_biter_tiles

	add_spawner_to_planet("panglia", "armoured-biter-spawner")
	add_spawner_to_planet("hyarion", "armoured-biter-spawner")
	add_spawner_to_planet("nexus", "armoured-biter-spawner")
end
