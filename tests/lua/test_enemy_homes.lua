-- Where the themed enemy families live (compat/enemy_homes.lua and the six enemy modules) on a mocked data.raw, on each
-- step of the razi-enemy-habitats setting and at each difficulty level.
-- Run from the mod root:
--   lua5.2 tests/lua/test_enemy_homes.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

-- Factorio's table.deepcopy
if not table.deepcopy then
	local function deepcopy(value)
		if type(value) ~= "table" then
			return value
		end
		local copy = {}
		for key, entry in pairs(value) do
			copy[key] = deepcopy(entry)
		end
		return copy
	end
	table.deepcopy = deepcopy -- luacheck: ignore 122
end

local logged = {}
rawset(_G, "log", function(message) logged[#logged + 1] = message end)

local module_names = {
	"enemy_autoplace", "enemy_homes", "enemy_planet_pollution", "armoured_biters", "arachnids_enemy",
	"explosive_biters", "toxic_biters", "cold_biters", "electric_flying_enemies"
}

local all_mods = {
	["ArmouredBiters-2_1-update"] = "2.0.4", Arachnids_enemy = "1.2.1", Explosive_biters = "2.4.0",
	Toxic_biters = "2.1.0", Cold_biters = "2.3.0", Electric_flying_enemies = "0.2.1"
}

local vanilla = {"biter-spawner", "spitter-spawner", "small-worm-turret", "medium-worm-turret", "big-worm-turret", "behemoth-worm-turret"}
local toxic_worm = "small-toxic-worm-turret"
local nest = {
	armoured = "armoured-biter-spawner", arachnids = "arachnid-spawner-unitspawner", explosive = "explosive-biter-spawner",
	toxic = "toxic-biter-spawner", cold = "cb-cold-spawner", electric = "flying-electric-unit-spawner"
}
local cold_worm = "small-cold-worm-turret"
local walker = "walker-electric-unit-spawner"

local function spawner(name, control)
	return {type = "unit-spawner", name = name, autoplace = {control = control, probability_expression = "x"}}
end

local function planet(controls, tile_names)
	local map_gen_settings = {autoplace_controls = controls or {}}
	if tile_names then
		local tile_settings = {}
		for _, name in ipairs(tile_names) do
			tile_settings[name] = {}
		end
		map_gen_settings.autoplace_settings = {tile = {settings = tile_settings}}
	end

	return {type = "planet", map_gen_settings = map_gen_settings}
end

-- `startup` holds the saved values of the settings; the difficulty is resolved by the real scripts.razi_difficulty_presets.
local function setup(active_mods, startup)
	for _, name in ipairs(module_names) do
		package.loaded["prototypes.compat." .. name] = nil
	end
	package.loaded["scripts.razi_difficulty_presets"] = nil
	rawset(_G, "mods", active_mods)
	rawset(_G, "settings", {startup = startup or {}})

	local spawners = {}
	for _, name in ipairs(vanilla) do
		spawners[name] = spawner(name, "enemy-base")
	end
	spawners[nest.armoured] = spawner(nest.armoured, "enemy-base")
	spawners[nest.arachnids] = spawner(nest.arachnids, "enemy-base")
	spawners[nest.toxic] = spawner(nest.toxic, "enemy-base")
	spawners[nest.explosive] = spawner(nest.explosive, "hot_enemy_base")
	spawners[nest.cold] = spawner(nest.cold, "frost_enemy_base")
	spawners[nest.electric] = spawner(nest.electric, "electric_enemies")
	spawners[walker] = spawner(walker, "electric_enemies")
	local turrets = {
		[toxic_worm] = {type = "turret", name = toxic_worm, autoplace = {control = "enemy-base", probability_expression = "x"}},
		[cold_worm] = {type = "turret", name = cold_worm, autoplace = {control = "frost_enemy_base", probability_expression = "x"}}
	}

	local tiles = {}
	for _, name in ipairs({"hyarion-soil-dark", "arig-sand", "moshine-rock", "cubium-folds", "snow-flat", "ice-rough", "fulgoran-dust",
		"dirt-1", "sand-1", "panglia-volcanic-soil-dark", "panglia-midland-turquoise-bark", "planet-crucible-dirt-1", "dust-flat-vesta",
		"ice-rough-vesta", "volcanic-soil-dark", "obsidiax-tile", "panglia-volcanic-cracks", "volcanic-cracks"}) do
		tiles[name] = {type = "tile", name = name}
	end
	tiles["volcanic-soil-dark"].absorptions_per_second = {pollution = 0.00003}

	rawset(_G, "data", {raw = {
		["unit-spawner"] = spawners,
		turret = turrets,
		tile = tiles,
		planet = {
			nauvis = planet({["enemy-base"] = {}, ["frost_enemy_base"] = {}}),
			terrapalus = planet({["enemy-base"] = {}}),
			-- tiles shared with Nauvis and a control of its own: the case a tile restriction does not cover
			athos = planet({["enemy-base"] = {}}),
			hyarion = planet(), arig = planet(), moshine = planet(), cubium = planet(), aquilo = planet(), frozeta = planet(),
			fulgora = planet({electric_enemies = {}}),
			ribbonia = planet(),
			lemures = planet({frost_enemy_base = {}}),
			-- homes of the wider steps
			panglia = planet({}, {"panglia-volcanic-soil-dark", "panglia-midland-turquoise-bark"}), crucible = planet(), vesta = planet(),
			paracelsin = planet(), obsidiax = planet({}, {"obsidiax-tile"}),
			-- planets that are no home on any step: back to the planets' own state
			corrundum = planet(), nexus = planet(),
			-- a planet that turns the control off
			quiet = planet({["enemy-base"] = {frequency = 0, size = 0, richness = 0}}),
		},
	}})
end

local function run_all()
	for _, name in ipairs({"arachnids_enemy", "armoured_biters", "cold_biters", "electric_flying_enemies", "explosive_biters", "toxic_biters"}) do
		require("prototypes.compat." .. name)
	end
	require("prototypes.compat.enemy_homes").data_final_fixes()
end

local function map_gen(planet_name)
	return data.raw.planet[planet_name].map_gen_settings --[[@as table]]
end

local function entity_setting(planet_name, entity_name)
	local settings = map_gen(planet_name)
	settings = settings.autoplace_settings and settings.autoplace_settings.entity and settings.autoplace_settings.entity.settings
	return settings and settings[entity_name]
end

local function placed(planet_name, entity_name)
	local setting = entity_setting(planet_name, entity_name)
	return setting ~= nil and setting.frequency ~= 0
end

-- A planet with tile settings of its own has autoplace_settings; the entity part is what the enemy modules write.
local function untouched(planet_name)
	local settings = map_gen(planet_name).autoplace_settings --[[@as table?]]
	return settings == nil or settings.entity == nil
end

local function zeroed(planet_name, entity_name)
	local setting = entity_setting(planet_name, entity_name)
	return setting ~= nil and setting.frequency == 0 and setting.size == 0 and setting.richness == 0
end

local function restricted_to(entity)
	local restriction = {}
	for _, tile_name in ipairs(entity.autoplace.tile_restriction) do
		restriction[tile_name] = true
	end
	return restriction
end

local function nest_tiles(family)
	return restricted_to(data.raw["unit-spawner"][nest[family]])
end

-- The homes of every step, as they add up.
local steps = {
	none = {},
	normal = {
		armoured = {"hyarion"}, arachnids = {"arig"}, explosive = {"moshine"}, toxic = {"cubium"},
		cold = {"frozeta"}, electric = {"ribbonia"}
	},
	wide = {
		armoured = {"hyarion", "panglia"}, arachnids = {"arig", "athos"}, explosive = {"moshine", "cubium"},
		toxic = {"cubium"}, cold = {"frozeta", "paracelsin"}, electric = {"ribbonia"}
	},
	widest = {
		armoured = {"hyarion", "panglia", "crucible"}, arachnids = {"arig", "athos", "crucible"},
		explosive = {"moshine", "cubium"}, toxic = {"cubium"},
		cold = {"frozeta", "paracelsin"}, electric = {"ribbonia"}
	}
}
local family_names = {"armoured", "arachnids", "explosive", "toxic", "cold", "electric"}
local shared = {"armoured", "arachnids", "toxic"}

-- Everything the step has to give, checked on a fresh fixture. `label` names the case in the messages.
local function check_step(label, startup, step_name)
	setup(all_mods, startup)
	run_all()
	local homes = steps[step_name]
	local is_home = {}
	for _, family in ipairs(family_names) do
		is_home[family] = {}
		for _, planet_name in ipairs(homes[family] or {}) do
			is_home[family][planet_name] = true
		end
	end

	-- Which planets get which family.
	for _, family in ipairs(family_names) do
		for planet_name in pairs(data.raw.planet) do
			check(placed(planet_name, nest[family]) == (is_home[family][planet_name] == true),
				label .. ": " .. family .. " nests on " .. planet_name .. ": expected " .. tostring(is_home[family][planet_name] == true))
		end
	end

	-- A planet that is no home of any family is back to its own state: no control, no entry, no pollution.
	local any_home = {}
	for _, family in ipairs(family_names) do
		for planet_name in pairs(is_home[family]) do
			any_home[planet_name] = true
		end
	end
	for _, planet_name in ipairs({"panglia", "crucible", "vesta", "paracelsin", "obsidiax", "corrundum", "nexus"}) do
		if not any_home[planet_name] then
			check(next(map_gen(planet_name).autoplace_controls) == nil, label .. ": " .. planet_name .. " has no enemy control")
			check(untouched(planet_name), label .. ": " .. planet_name .. " has no entity entries")
		end
	end

	-- Pollution only where there is a home of this step; Fulgora's is the enemy mod's own, Lemures belongs to Dea Dia.
	for planet_name in pairs(data.raw.planet) do
		local expected = any_home[planet_name] and "pollution" or nil
		check(data.raw.planet[planet_name].pollutant_type == expected,
			label .. ": pollution of " .. planet_name .. " is " .. tostring(data.raw.planet[planet_name].pollutant_type))
	end

	-- The vanilla enemies are off on the homes; a planet that switched the control off is left alone.
	for planet_name in pairs(any_home) do
		check(zeroed(planet_name, "biter-spawner"), label .. ": vanilla biters are off on " .. planet_name)
	end
	check(untouched("quiet"), label .. ": a planet with the control off gets no entries")

	-- Nauvis keeps its vanilla enemies; no specialist nests on Nauvis, Terrapalus or any other planet with the shared
	-- control that is no home of the family, whatever tiles it has (Athos has Nauvis' tiles).
	for _, planet_name in ipairs({"nauvis", "terrapalus", "athos"}) do
		for _, family in ipairs(shared) do
			if not is_home[family][planet_name] then
				check(zeroed(planet_name, nest[family]), label .. ": " .. family .. " is switched off on " .. planet_name)
			end
		end
	end
	for _, planet_name in ipairs({"nauvis", "terrapalus"}) do
		check(zeroed(planet_name, toxic_worm), label .. ": toxic worms are switched off on " .. planet_name)
		for _, name in ipairs(vanilla) do
			check(entity_setting(planet_name, name) == nil, label .. ": " .. planet_name .. " keeps the vanilla " .. name)
		end
	end
	if homes.toxic then
		check(placed("cubium", toxic_worm), label .. ": Cubium has the toxic worms")
		check(placed("ribbonia", walker) and placed("ribbonia", nest.electric), label .. ": Ribbonia has both electric nests")
	end
	-- A home of one shared-control family is not a home of the others.
	for _, family in ipairs(shared) do
		for planet_name in pairs(is_home[family]) do
			for _, other in ipairs(shared) do
				if other ~= family and not is_home[other][planet_name] then
					check(zeroed(planet_name, nest[other]), label .. ": " .. planet_name .. " has no " .. other)
				end
			end
		end
	end

	-- Dea Dia's cold nests on Lemures keep their tiles, and the planet is not touched.
	check(untouched("lemures"), label .. ": Lemures gets no entity entries")
	check(data.raw.planet.lemures.pollutant_type == nil, label .. ": Lemures keeps its pollution state")
	check(nest_tiles("cold")["snow-flat"] and nest_tiles("cold")["ice-rough"], label .. ": Cold nests keep the snow and ice tiles")

	-- The native homes: left to the mods with a step, switched off without one.
	if step_name == "none" then
		check(zeroed("fulgora", nest.electric) and zeroed("fulgora", walker), label .. ": Fulgora's electric nests are switched off")
		check(zeroed("aquilo", nest.cold) and zeroed("aquilo", cold_worm), label .. ": Aquilo's cold nests are switched off")
		check(map_gen("fulgora").autoplace_controls.electric_enemies ~= nil, label .. ": Fulgora keeps its control")
	else
		check(entity_setting("fulgora", nest.electric) == nil and map_gen("fulgora").autoplace_settings == nil,
			label .. ": Fulgora's electric nests stay the enemy mod's")
		check(map_gen("aquilo").autoplace_settings == nil, label .. ": Aquilo is left alone")
	end
	return homes
end

local function tile_set(step_name, family)
	setup(all_mods, {["razi-enemy-habitats"] = {value = step_name}})
	run_all()
	return nest_tiles(family)
end

-- The four steps by the setting (Custom level), and the setting at its default.
for _, step_name in ipairs({"none", "normal", "wide", "widest"}) do
	check_step("custom " .. step_name, {["razi-difficulty-preset"] = {value = "custom"}, ["razi-enemy-habitats"] = {value = step_name}}, step_name)
end
check_step("no settings", {}, "normal")
check_step("auto", {["razi-enemy-habitats"] = {value = "auto"}}, "normal")
check_step("unknown value", {["razi-enemy-habitats"] = {value = "everywhere"}}, "normal")

-- The levels set the step with `auto` saved; a step chosen by hand stays.
check_step("easy", {["razi-difficulty-preset"] = {value = "easy"}, ["razi-enemy-habitats"] = {value = "auto"}}, "none")
check_step("normal", {["razi-difficulty-preset"] = {value = "normal"}, ["razi-enemy-habitats"] = {value = "auto"}}, "normal")
check_step("hard", {["razi-difficulty-preset"] = {value = "hard"}, ["razi-enemy-habitats"] = {value = "auto"}}, "wide")
check_step("nightmare", {["razi-difficulty-preset"] = {value = "nightmare"}, ["razi-enemy-habitats"] = {value = "auto"}}, "widest")
check_step("hard, normal homes", {["razi-difficulty-preset"] = {value = "hard"}, ["razi-enemy-habitats"] = {value = "normal"}}, "normal")
check_step("easy, wide homes", {["razi-difficulty-preset"] = {value = "easy"}, ["razi-enemy-habitats"] = {value = "wide"}}, "wide")
check_step("normal, no homes", {["razi-difficulty-preset"] = {value = "normal"}, ["razi-enemy-habitats"] = {value = "none"}}, "none")

-- Tile restrictions keep to the tiles of the homes of the step.
local armoured_normal = tile_set("normal", "armoured")
check(armoured_normal["hyarion-soil-dark"] and not armoured_normal["panglia-volcanic-soil-dark"] and not armoured_normal["panglia-volcanic-cracks"]
	and not armoured_normal["volcanic-cracks"] and not armoured_normal["planet-crucible-dirt-1"], "Armoured nests only on Hyarion's tiles")
local armoured_wide = tile_set("wide", "armoured")
check(armoured_wide["hyarion-soil-dark"] and armoured_wide["panglia-volcanic-soil-dark"] and armoured_wide["panglia-midland-turquoise-bark"]
	and not armoured_wide["planet-crucible-dirt-1"], "Armoured nests on the tiles of Hyarion and Panglia")
local armoured_widest = tile_set("widest", "armoured")
check(armoured_widest["planet-crucible-dirt-1"] and armoured_widest["panglia-volcanic-soil-dark"], "Armoured nests also on Crucible's tiles")
local arachnid_normal = tile_set("normal", "arachnids")
check(arachnid_normal["arig-sand"] and not arachnid_normal["dirt-1"], "Arachnid nests only on Arig's tiles")
local arachnid_wide = tile_set("wide", "arachnids")
check(arachnid_wide["arig-sand"] and arachnid_wide["dirt-1"] and arachnid_wide["sand-1"], "Arachnid nests on Athos' tiles too")
local toxic_normal = tile_set("normal", "toxic")
check(toxic_normal["cubium-folds"] and not toxic_normal["dust-flat-vesta"] and not toxic_normal["planet-crucible-dirt-1"],
	"Toxic nests only on Cubium's tiles")
-- Vesta and Obsidiax are no home on any step: they are nearly all ocean and lava.
check(not tile_set("widest", "toxic")["dust-flat-vesta"], "Toxic nests not on Vesta's tiles")
check(tile_set("normal", "explosive")["moshine-rock"] and not tile_set("normal", "explosive")["cubium-folds"], "Explosive nests only on Moshine's tiles")
check(tile_set("wide", "explosive")["cubium-folds"], "Explosive nests on Cubium's tiles")
local cold_normal = tile_set("normal", "cold")
check(cold_normal["snow-flat"] and not cold_normal["volcanic-soil-dark"] and not cold_normal["obsidiax-tile"], "Cold nests on snow and ice")
local cold_wide = tile_set("wide", "cold")
check(cold_wide["snow-flat"] and cold_wide["volcanic-soil-dark"], "Cold nests also on Paracelsin's tiles")
local cold_widest = tile_set("widest", "cold")
check(not cold_widest["obsidiax-tile"] and not cold_widest["ice-rough-vesta"], "Cold nests not on Vesta's and Obsidiax' tiles")
-- Without homes the restriction is the one of the first step: Dea Dia's cold nests stand on Lemures.
local cold_none = tile_set("none", "cold")
for tile_name in pairs(cold_normal) do
	check(cold_none[tile_name], "no homes, Cold keeps " .. tile_name)
end
local none_count, normal_count = 0, 0
for _ in pairs(cold_none) do none_count = none_count + 1 end
for _ in pairs(cold_normal) do normal_count = normal_count + 1 end
check(none_count == normal_count, "no homes, the Cold restriction is the one of the first step")
check(tile_set("none", "armoured")["hyarion-soil-dark"], "no homes, Armoured keeps the first step's tiles")

check(#logged > 0, "the nests that were switched off are logged")

-- Pollution absorption of the tiles of the homes: Panglia's plant tiles have none of their own.
local function absorbs(tile_name)
	local absorptions = data.raw.tile[tile_name].absorptions_per_second
	return absorptions and absorptions.pollution
end
setup(all_mods, {["razi-enemy-habitats"] = {value = "widest"}})
run_all()
require("prototypes.compat.enemy_planet_pollution").data_final_fixes()
check(absorbs("panglia-midland-turquoise-bark") == 0.00003, "the tiles of Panglia absorb pollution when it is a home")
check(absorbs("obsidiax-tile") == nil, "Obsidiax is no home, its tile stays")
setup(all_mods)
run_all()
require("prototypes.compat.enemy_planet_pollution").data_final_fixes()
check(absorbs("panglia-midland-turquoise-bark") == nil, "no home, no change to the tiles")

-- Without the enemy mods nothing is placed or switched off.
setup({})
run_all()
for planet_name in pairs(data.raw.planet) do
	check(untouched(planet_name), "no enemy mods, " .. planet_name .. " untouched")
end

-- Only the installed families are switched off: with Toxic alone the Armoured nest is not named.
setup({Toxic_biters = "2.1.0"})
run_all()
check(zeroed("nauvis", nest.toxic) and entity_setting("nauvis", nest.armoured) == nil, "only the installed family is switched off")

-- Enemy routing off: nothing is touched.
setup(all_mods)
settings.startup["razi-enable-enemy-routing"] = {value = false} -- luacheck: ignore 122
run_all()
for planet_name in pairs(data.raw.planet) do
	check(untouched(planet_name), "routing off, " .. planet_name .. " untouched")
end

-- A family without a placeable nest (a mod with its nest setting off) is not claimed, so nothing is switched off.
setup(all_mods)
data.raw["unit-spawner"][nest.armoured] = nil
run_all()
check(entity_setting("nauvis", nest.armoured) == nil, "no Armoured nest, nothing to switch off")

rawset(_G, "mods", nil)
rawset(_G, "log", nil)
rawset(_G, "settings", nil)
rawset(_G, "data", nil)
print("enemy_homes: ok")
