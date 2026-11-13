local lithium_battery = {}

-- Belts without a machine. Razi hides the assembling machine 4 of Lithium Battery (compat/redundant_progression.lua, setting
--    razi-hide-redundant-assembler-tiers), but the four promethium belt recipes of Lithium Battery (promethium-transport-belt,
--    -underground-belt, -splitter, -loader) are in the category hea-am4-only, which only that machine and its Tenebris and Rabbasca
--    copies have (prototypes/belt/recipe.lua, prototypes/hea-assembling-machine.lua). No machine the player has can make them.
--    The category goes to Krastorio 2's advanced assembling machine, the tier that takes the place of the hidden one, and to its copies.
-- Vesta items that are not there. With Vesta and its setting hea-endgame, Lithium Battery (7.6.4 data-final-fixes.lua:241-259)
--    rewrites the ingredients of ske_fusion_framework and ske_fusion_thruster with ske_empty_dt_canister and vesta-heater. Vesta
--    (2.1.30 data.lua:25-33) makes those two items only with its setting ske_vesta_legacy_recipes; without it the game stops with
--    "item with name 'ske_empty_dt_canister' does not exist". Ingredients whose item or fluid does not exist are taken out, and
--    the results of the same name from the recycling recipes, which are made from these lists before Razi loads.
-- Remove this module when Razi leaves the assembling machine 4 of Lithium Battery alone and when Lithium Battery checks
-- that the Vesta items exist.

local function sorted_keys(map)
	local keys = {}
	for key in pairs(map or {}) do
		keys[#keys + 1] = key
	end
	table.sort(keys)
	return keys
end

local BELT_CATEGORY = "hea-am4-only"
local SUBSTITUTE = "kr-advanced-assembling-machine"

local function keep_belts_craftable()
	local recipe = data.raw.recipe and data.raw.recipe["assembling-machine-4"]
	if not (type(recipe) == "table" and recipe.hidden) then
		return
	end
	if not (data.raw["recipe-category"] and data.raw["recipe-category"][BELT_CATEGORY]) then
		return
	end

	for _, name in ipairs(sorted_keys(data.raw["assembling-machine"])) do
		local machine = data.raw["assembling-machine"][name]
		local categories = type(machine) == "table" and machine.crafting_categories
		if type(categories) == "table" and not machine.hidden and name:sub(-#SUBSTITUTE) == SUBSTITUTE then
			local present = false
			for _, category in ipairs(categories) do
				present = present or category == BELT_CATEGORY
			end
			if not present then
				categories[#categories + 1] = BELT_CATEGORY
				log("razi-protocol: " .. name .. " makes the recipes of the " .. BELT_CATEGORY .. " category, "
					.. "as the assembling machine 4 of Lithium Battery is hidden")
			end
		end
	end
end

-- the Vesta recipes whose ingredients Lithium Battery rewrites
local VESTA_RECIPES = {"ske_fusion_framework", "ske_fusion_thruster"}

local function ingredient_exists(ingredient)
	if ingredient.type == "fluid" then
		return data.raw.fluid ~= nil and data.raw.fluid[ingredient.name] ~= nil
	end
	for item_type in pairs(defines.prototypes.item) do
		if data.raw[item_type] and data.raw[item_type][ingredient.name] then
			return true
		end
	end
	return false
end

local function remove_missing(name, field, verb)
	local recipe = data.raw.recipe and data.raw.recipe[name]
	local list = type(recipe) == "table" and recipe[field]
	if type(list) ~= "table" then
		return
	end
	for index = #list, 1, -1 do
		local entry = list[index]
		if type(entry) == "table" and type(entry.name) == "string" and not ingredient_exists(entry) then
			table.remove(list, index)
			log("razi-protocol: recipe " .. name .. " no longer " .. verb .. " " .. entry.name
				.. ", which Vesta makes only with its legacy recipes")
		end
	end
end

local function remove_missing_vesta_ingredients()
	if not mods["skewer_planet_vesta"] then
		return
	end
	for _, name in ipairs(VESTA_RECIPES) do
		remove_missing(name, "ingredients", "needs")
		-- the recycling recipe is made from the list of Lithium Battery before Razi loads
		remove_missing(name .. "-recycling", "results", "returns")
	end
end

function lithium_battery.data_final_fixes()
	if not (mods and mods["LithiumBattery"]) then
		return
	end

	keep_belts_craftable()
	remove_missing_vesta_ingredients()
end

return lithium_battery
