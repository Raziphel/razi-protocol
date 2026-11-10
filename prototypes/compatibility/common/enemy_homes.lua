local enemy_autoplace = require("prototypes.compatibility.common.enemy_autoplace")
local difficulty = require("lib.difficulty.presets")

-- Where each themed enemy family lives. One list for the six enemy modules, so that a planet is added to a family (or
-- taken from it) in one place. The list is the authors' design (each mod was made for one or two places) plus the
-- planets whose theme fits the family. Nauvis keeps the vanilla enemies; planets with enemies of their own (Gleba,
-- Tellus, Lemures with Dea Dia, ...) are not touched.
--
-- The homes grow with the `razi-enemy-habitats` setting. Each home has the first step it belongs to, and the steps
-- add up:
--   none    no home (Easy): the enemy mods' own placement on Fulgora and Aquilo is switched off too
--   normal  Hyarion (Armoured), Arig (Arachnids), Moshine (Explosive), Cubium (Toxic), Frozeta (Cold),
--           Fulgora (Electric, without Fulgora Replicators) and Ribbonia (Electric)
--   wide    + Panglia (Armoured), Athos (Arachnids), Cubium (Explosive), Paracelsin (Cold),
--           Corrundum (Electric, with Fulgora Replicators)
--   widest  + Crucible (Armoured and Arachnids)
-- `auto` (the default) follows the difficulty level; the level sets the step itself, so `auto` is only seen on Normal
-- and Custom and means `normal`.
--
-- A home with `without_mod` is a home only while that mod is not installed, one with `with_mod` only while it is
-- (Electric flying enemies leave Fulgora for Corrundum when Fulgora Replicators holds Fulgora's storage islands).
--
-- `native` homes are placed by the enemy mod itself, so Razi Protocol only counts them as homes; when a native home is
-- not a home (the step is none, or its `without_mod` mod is installed) the mod's nests there are switched off.
-- `native_planets` are planets where the mod places itself although they are not a home; they are only switched off
-- without homes.
-- `control` is the autoplace control the family's nests use; Armoured, Toxic and Arachnids share the vanilla
-- "enemy-base" one, so every planet with that control (Nauvis, Terrapalus and each home of another family) is a place
-- where their nests could turn up; `exclude_from_other_planets` switches them off there.
local steps = {none = 0, normal = 1, wide = 2, widest = 3}

-- The tiles a nest of the family may stand on are the land tiles of its homes. A planet that shares its tiles with
-- Nauvis (Athos) cannot be told apart by tiles, which is what `exclude_from_other_planets` is for. The lists are kept
-- by hand, as names that are skipped when the tile does not exist: a planet mod may fill its tile settings in a later
-- stage than the enemy modules run in, and the lists of the homes of the first step must stay as they were.
local planet_tiles = {
	hyarion = {
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
		"hyarion-crystal-soil"
	},
	arig = {
		"arig-sand",
		"arig-deep-sand",
		"arig-stable-sand",
		"planetaris-sandstone-1",
		"planetaris-sandstone-2",
		"planetaris-sandstone-3"
	},
	moshine = {
		"moshine-rock",
		"moshine-hot-swamp",
		"moshine-lava",
		"moshine-dust",
		"moshine-sand",
		"moshine-dunes"
	},
	cubium = {
		"cubium-volcanic-cracks-hot",
		"cubium-volcanic-jagged-ground",
		"cubium-lava",
		"cubium-lava-hot",
		"cubium-volcanic-cracks-warm",
		"cubium-volcanic-cracks",
		"cubium-volcanic-folds-flat",
		"cubium-volcanic-ash-light",
		"cubium-volcanic-ash-dark",
		"cubium-volcanic-ash-flats",
		"cubium-volcanic-pumice-stones",
		"cubium-volcanic-smooth-stone",
		"cubium-smooth-stone-warm",
		"cubium-ash-cracks",
		"cubium-folds",
		"cubium-folds-warm",
		"cubium-soil-dark",
		"cubium-soil-light",
		"cubium-ash-soil"
	},
	-- Frozeta's tiles are the vanilla snow and ice ones, as Aquilo's and Lemures' (Dea Dia's cold nests stand there).
	frozeta = {
		"snow-flat",
		"snow-crests",
		"snow-lumpy",
		"snow-patchy",
		"ice-rough",
		"ice-smooth",
		"ammoniacal-ocean",
		"ammoniacal-ocean-2",
		"brash-ice"
	},
	-- The land tiles of the planets that join on the wider steps (the liquid ones cannot hold a nest).
	panglia = {
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
		"panglia-midland-cracked-lichen-dark"
	},
	paracelsin = {
		"volcanic-soil-dark",
		"volcanic-soil-light",
		"volcanic-ash-soil",
		"volcanic-ash-light",
		"volcanic-ash-dark",
		"volcanic-cracks",
		"volcanic-folds",
		"volcanic-folds-flat"
	},
	athos = {
		"dry-dirt",
		"dirt-1",
		"dirt-2",
		"dirt-3",
		"dirt-4",
		"dirt-5",
		"dirt-6",
		"dirt-7",
		"sand-1",
		"sand-2",
		"sand-3"
	},
	-- Corrundum's land: the volcanic soil. Its petroleum tile is oil and holds no nest.
	corrundum = {
		"volcanic-ash-soil",
		"volcanic-soil-dark",
		"volcanic-soil-light"
	},
	crucible = {
		"planet-crucible-dirt-1",
		"planet-crucible-dirt-2",
		"planet-crucible-dirt-3",
		"planet-crucible-dirt-4",
		"planet-crucible-rock-1",
		"planet-crucible-rock-2",
		"planet-crucible-rock-3",
		"planet-crucible-rock-4",
		"planet-crucible-sand-1"
	}
}

local families = {
	armoured = {
		control = "enemy-base",
		homes = {{planet = "hyarion", step = steps.normal}, {planet = "panglia", step = steps.wide}, {planet = "crucible", step = steps.widest}}
	},
	arachnids = {
		control = "enemy-base",
		homes = {{planet = "arig", step = steps.normal}, {planet = "athos", step = steps.wide}, {planet = "crucible", step = steps.widest}}
	},
	toxic = {
		control = "enemy-base",
		-- Vesta is not a home: about 2% of it is land (Toxic nests found 1 to 3 places there).
		homes = {{planet = "cubium", step = steps.normal}}
	},
	explosive = {
		control = "hot_enemy_base",
		homes = {{planet = "moshine", step = steps.normal}, {planet = "cubium", step = steps.wide}}
	},
	cold = {
		control = "frost_enemy_base",
		-- Aquilo is not a home: about 97% of it is ocean, so cold nests found no land there.
		native_planets = {"aquilo"},
		-- Vesta (about 2% land) and Obsidiax (0.9% land) are not homes: Cold nests found 0 to 31 places there.
		homes = {{planet = "frozeta", step = steps.normal}, {planet = "paracelsin", step = steps.wide}}
	},
	electric = {
		control = "electric_enemies",
		-- Fulgora Replicators holds Fulgora's storage islands, so the Electric nests move from Fulgora to Corrundum.
		homes = {
			{planet = "fulgora", step = steps.normal, native = true, without_mod = "Fulgora_Replicators"},
			{planet = "ribbonia", step = steps.normal},
			{planet = "corrundum", step = steps.wide, with_mod = "Fulgora_Replicators"}
		}
	}
}

local enemy_homes = {}

-- Entity names of each family, announced by the enemy modules when they are installed and have a placeable nest.
local claimed = {}

-- The setting of the step, or `auto`, which is the step of the Normal level.
function enemy_homes.habitat()
	local value = difficulty.effective("razi-enemy-habitats", "auto")
	if steps[value] == nil then
		return "normal"
	end

	return value
end

local function current_step()
	return steps[enemy_homes.habitat()]
end

-- The homes of the family at a step, in the order of the list. A home bound to a mod is counted only as the mod says.
local function homes_at(family, step)
	local result = {}
	for _, home in ipairs(family and family.homes or {}) do
		local allowed = (home.without_mod == nil or not mods[home.without_mod])
			and (home.with_mod == nil or mods[home.with_mod])
		if allowed and home.step <= step then
			result[#result + 1] = home
		end
	end

	return result
end

function enemy_homes.is_home(family_name, planet_name)
	for _, home in ipairs(homes_at(families[family_name], current_step())) do
		if home.planet == planet_name then
			return true
		end
	end

	return false
end

-- The homes Razi Protocol has to set up itself (not the ones the enemy mod places on its own).
function enemy_homes.planets(family_name)
	local result = {}
	for _, home in ipairs(homes_at(families[family_name], current_step())) do
		if not home.native then
			result[#result + 1] = home.planet
		end
	end

	return result
end

-- Tile names of the family's homes, in the order of the homes. Without homes (Easy) the homes of the Normal step
-- stay in the restriction: the nests are placed nowhere then, but the same prototypes stand on planets of other mods
-- (Dea Dia's cold nests on Lemures) and need their tiles.
function enemy_homes.tiles(family_name)
	local homes = homes_at(families[family_name], current_step())
	if #homes == 0 then
		homes = homes_at(families[family_name], steps.normal)
	end

	local result = {}
	local seen = {}
	for _, home in ipairs(homes) do
		for _, tile_name in ipairs(enemy_autoplace.existing_tiles(planet_tiles[home.planet])) do
			if not seen[tile_name] then
				seen[tile_name] = true
				result[#result + 1] = tile_name
			end
		end
	end

	return result
end

-- The enemy mods that place themselves on a planet are switched off there when the planet is not a home: a native
-- home that is none at this step or that Fulgora Replicators took (Electric on Fulgora), and, only without homes, the
-- planets the mod uses although they are no home (Cold on Aquilo). A native planet that is a home is left to the mod.
function enemy_homes.switch_off_native(family_name, entity_names)
	local family = families[family_name]
	if not family then
		return
	end

	local planets = {}
	local homes = {}
	for _, home in ipairs(homes_at(family, current_step())) do
		homes[home.planet] = true
	end
	for _, home in ipairs(family.homes) do
		if home.native and not homes[home.planet] then
			planets[#planets + 1] = home.planet
		end
	end
	if current_step() == steps.none then
		for _, planet_name in ipairs(family.native_planets or {}) do
			planets[#planets + 1] = planet_name
		end
	end

	for _, planet_name in ipairs(planets) do
		enemy_autoplace.zero_entities_on_planet(planet_name, entity_names)
	end
end

function enemy_homes.claim(family_name, entity_names)
	claimed[family_name] = entity_names
end

local function control_is_active(planet, control_name)
	local map_gen_settings = planet.map_gen_settings
	local control = map_gen_settings
		and map_gen_settings.autoplace_controls
		and map_gen_settings.autoplace_controls[control_name]
	if type(control) ~= "table" then
		return false
	end

	return control.frequency ~= 0 and control.size ~= 0
end

-- Armoured Biters, Toxic Biters and Arachnids use the control every planet with vanilla biters has, and a tile
-- restriction alone does not stop them where a planet shares tiles with Nauvis (Athos, Prosephina, Terrapalus, Castra,
-- Ribbonia, Tenebris). Switch their nests off by name on every planet that has the control and is not their home, on
-- every step.
function enemy_homes.exclude_from_other_planets()
	if not enemy_autoplace.enabled() then
		return
	end

	local excluded = {}
	for family_name, entity_names in pairs(claimed) do
		local family = families[family_name]
		for planet_name, planet in pairs(data.raw.planet or {}) do
			if family
				and family.control == "enemy-base"
				and not enemy_homes.is_home(family_name, planet_name)
				and control_is_active(planet, family.control)
			then
				enemy_autoplace.zero_entities_on_planet(planet_name, entity_names)
				excluded[#excluded + 1] = family_name .. "@" .. planet_name
			end
		end
	end

	table.sort(excluded)
	for _, entry in ipairs(excluded) do
		log("razi-protocol: enemy homes: " .. entry .. " switched off")
	end
end

function enemy_homes.data_final_fixes()
	enemy_homes.exclude_from_other_planets()
end

return enemy_homes
