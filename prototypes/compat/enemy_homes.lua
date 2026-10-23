local enemy_autoplace = require("prototypes.compat.enemy_autoplace")

-- Where each themed enemy family lives. One list for the six enemy modules, so that a planet is added to a family (or
-- taken from it) in one place. The list is the authors' design (each mod was made for one or two places) plus the
-- planets whose theme fits the family: Armoured Biters on Hyarion, Arachnids on Arig, Explosive Biters on Moshine, Toxic
-- Biters on Cubium, Cold Biters on Aquilo and Frozeta, Electric Flying Enemies on Fulgora and Ribbonia. Nauvis keeps the
-- vanilla enemies; planets with enemies of their own authors (Gleba, Tellus, Lemures with Dea Dia, ...) are not touched.
--
-- `native` planets are placed by the enemy mod itself, so Razi Protocol only counts them as homes.
-- `control` is the autoplace control the family's nests use; Armoured, Toxic and Arachnids share the vanilla
-- "enemy-base" one, so every planet with that control (Nauvis, Terrapalus and each home of another family) is a place
-- where their nests could turn up; `exclude_from_other_planets` switches them off there.
local families = {
	armoured = {planets = {"hyarion"}, control = "enemy-base"},
	arachnids = {planets = {"arig"}, control = "enemy-base"},
	toxic = {planets = {"cubium"}, control = "enemy-base"},
	explosive = {planets = {"moshine"}, control = "hot_enemy_base"},
	cold = {planets = {"aquilo", "frozeta"}, control = "frost_enemy_base"},
	electric = {planets = {"fulgora", "ribbonia"}, native = {fulgora = true}, control = "electric_enemies"}
}

local enemy_homes = {}

-- Entity names of each family, announced by the enemy modules when they are installed and have a placeable nest.
local claimed = {}

function enemy_homes.is_home(family_name, planet_name)
	local family = families[family_name]
	if not family then
		return false
	end

	for _, home in ipairs(family.planets) do
		if home == planet_name then
			return true
		end
	end

	return false
end

-- The homes Razi Protocol has to set up itself (not the ones the enemy mod places on its own).
function enemy_homes.planets(family_name)
	local family = families[family_name]
	local result = {}
	for _, planet_name in ipairs(family and family.planets or {}) do
		if not (family.native and family.native[planet_name]) then
			result[#result + 1] = planet_name
		end
	end

	return result
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
-- Ribbonia, Tenebris). Switch their nests off by name on every planet that has the control and is not their home.
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
