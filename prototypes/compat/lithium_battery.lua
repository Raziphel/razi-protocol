local lithium_battery = {}

-- Aquilo Overhaul: Lithium Battery 7.5.0 with Krastorio 2 Spaced Out, Planet Crucible and Maraxsis stops the game while it loads
-- at two places. Both come from the K2SO branch of Lithium Battery, which copies a science pack recipe, hands the copy's
-- ingredients to the Krastorio research data recipe and deletes the copy again.
--
-- 1. Dead productivity effects. The copies are cryogenic-science-pack-clone and promethium-science-pack-clone
--    (prototypes/recipes-updates.lua:29-31, :132-134), deleted at the end of data-final-fixes.lua (:361-369). Planet Crucible makes one
--    productivity technology per science pack from every recipe that produces the pack, copies included, in data-updates.lua (:610-690),
--    so those technologies keep a change-recipe-productivity effect of a recipe that no longer exists:
--    "recipe with name 'cryogenic-science-pack-clone' does not exist ... planet-crucible-cryogenic-science-pack-productivity".
--    The effects of recipes that do not exist are taken out; the effect of the real recipe stays.
-- 2. Doubled biter eggs. Lithium Battery writes the three ingredients of its promethium copy, biter-egg among them, into
--    kr-promethium-research-data (data-final-fixes.lua:365-368). Maraxsis (compat/krastorio-2-final-fixes.lua:5-12) then moves the
--    biter eggs of promethium-science-pack, which it doubles, into the same recipe by appending them, and the game stops with
--    "Duplicate item ingredients are not allowed (biter-egg exists 2 or more times)". Equal ingredients of the research data
--    recipes are added up into one.
-- 3. Belts without a machine. Razi hides the assembling machine 4 of Lithium Battery (compat/redundant_progression.lua, setting
--    razi-hide-redundant-assembler-tiers), but the four promethium belt recipes of Lithium Battery (promethium-transport-belt,
--    -underground-belt, -splitter, -loader) are in the category hea-am4-only, which only that machine and its Tenebris and Rabbasca
--    copies have (prototypes/belt/recipe.lua, prototypes/hea-assembling-machine.lua). No machine the player has can make them.
--    The category goes to Krastorio 2's advanced assembling machine, the tier that takes the place of the hidden one, and to its copies.
-- Remove this module when Lithium Battery stops deleting recipes that other mods have listed, when it or Maraxsis does not
-- add the biter egg a second time, and when Razi leaves the assembling machine 4 of Lithium Battery alone.

local RESEARCH_DATA = {"kr-cryogenic-research-data", "kr-promethium-research-data"}

local function sorted_keys(map)
	local keys = {}
	for key in pairs(map or {}) do
		keys[#keys + 1] = key
	end
	table.sort(keys)
	return keys
end

local function remove_dead_productivity_effects()
	local recipes = data.raw.recipe or {}
	for _, name in ipairs(sorted_keys(data.raw.technology)) do
		local technology = data.raw.technology[name]
		local effects = type(technology) == "table" and technology.effects
		if type(effects) == "table" then
			for index = #effects, 1, -1 do
				local effect = effects[index]
				if type(effect) == "table" and effect.type == "change-recipe-productivity" and recipes[effect.recipe] == nil then
					table.remove(effects, index)
					log("razi-protocol: technology " .. name .. " no longer raises the productivity of " .. tostring(effect.recipe)
						.. ", which Lithium Battery removed")
				end
			end
		end
	end
end

local function merge_equal_ingredients(name)
	local recipe = data.raw.recipe and data.raw.recipe[name]
	local ingredients = type(recipe) == "table" and recipe.ingredients
	if type(ingredients) ~= "table" then
		return
	end

	local first_of = {}
	local merged = {}
	local changed = false
	for _, ingredient in ipairs(ingredients) do
		local key = type(ingredient) == "table" and type(ingredient.name) == "string" and type(ingredient.amount) == "number"
			and (ingredient.type or "item") .. "/" .. ingredient.name
		local first = key and first_of[key]
		if first then
			first.amount = first.amount + ingredient.amount
			changed = true
			log("razi-protocol: recipe " .. name .. " lists " .. ingredient.name .. " twice, the amounts are added up to " .. first.amount)
		else
			merged[#merged + 1] = ingredient
			if key then
				first_of[key] = ingredient
			end
		end
	end
	if changed then
		recipe.ingredients = merged
	end
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

function lithium_battery.data_final_fixes()
	if not (mods and mods["LithiumBattery"]) then
		return
	end

	remove_dead_productivity_effects()
	for _, name in ipairs(RESEARCH_DATA) do
		merge_equal_ingredients(name)
	end
	keep_belts_craftable()
end

return lithium_battery
