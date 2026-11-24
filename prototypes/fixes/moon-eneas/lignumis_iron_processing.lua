-- moon-eneas 1.0.10 with its startup setting integrate-lignumis replaces the whole effects list of iron-processing with four
-- recipes (prototypes/patches/lignumis-recipe.lua:3-12, loaded from data-final-fixes.lua:11) instead of adding to it. On a
-- Lignumis start the recipes other mods put there are lost: the iron stick, the wind turbine, the iron beam and the inserter
-- parts that Lignumis moves into iron-processing for K2SO (prototypes/compatibility/k2so.lua:22-27), and Lignumis' own iron
-- steam inserters, steam assembling machine, desiccation furnace and copper gun turret, which nothing else unlocks. The effects
-- are noted in data-updates, after Lignumis' data-updates and before Eneas' data-final-fixes, and the lost unlocks are added back.
local lignumis_iron_processing = {}

local TECHNOLOGY = "iron-processing"

local before_eneas = nil

local function integrated()
	local setting = settings and settings.startup and settings.startup["integrate-lignumis"]
	return mods and mods["moon-eneas"] and mods["lignumis"] and setting and setting.value == true
end

local function unlocked_recipes(technology)
	local recipes = {}
	for _, effect in ipairs(technology.effects or {}) do
		if effect.type == "unlock-recipe" and effect.recipe then
			recipes[#recipes + 1] = effect.recipe
		end
	end
	return recipes
end

function lignumis_iron_processing.data_updates()
	local technology = data.raw.technology and data.raw.technology[TECHNOLOGY]
	if not integrated() or not technology then
		return
	end
	before_eneas = unlocked_recipes(technology)
end

function lignumis_iron_processing.data_final_fixes()
	local technology = data.raw.technology and data.raw.technology[TECHNOLOGY]
	if not integrated() or not technology or not before_eneas then
		return
	end

	local unlocked = {}
	for _, recipe in ipairs(unlocked_recipes(technology)) do
		unlocked[recipe] = true
	end
	technology.effects = technology.effects or {}
	for _, recipe in ipairs(before_eneas) do
		if not unlocked[recipe] and data.raw.recipe and data.raw.recipe[recipe] then
			technology.effects[#technology.effects + 1] = {type = "unlock-recipe", recipe = recipe}
			unlocked[recipe] = true
			log("razi-protocol: " .. TECHNOLOGY .. " unlocks " .. recipe
				.. " again, which Eneas drops from it with integrate-lignumis")
		end
	end
end

return lignumis_iron_processing
