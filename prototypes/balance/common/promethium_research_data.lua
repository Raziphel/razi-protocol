-- Hyarion, Foliax and omni recipe amounts are a balance decision: each recipe keeps its source ingredients but produces
-- research data, so every promethium card takes a blank tech card like the Krastorio 2 chain.
local RECIPES = {
	-- Planetaris Hyarion (planetaris-hyarion/prototypes/recipe.lua:1231): 20 chunks, 1 quantum processor, 10 biter eggs.
	{recipe = "planetaris-promethium-science-pack", cards = 15, data = 8},
	-- Foliax (foliax/prototypes/recipe.lua:3178): 25 chunks, 25 processing units, 25 raw fish.
	{recipe = "foliax-promethium-science-pack", cards = 10, data = 10},
	-- omni (omni/prototypes/recipe.lua:377-393): 10 biter eggs, 1 quantum processor, 250 beninium.
	{recipe = "advanced-promethium-science", cards = 5, data = 5, mod = "omni"},
}

local DATA_NAME = "kr-promethium-research-data"

local function deep_copy(value)
	if type(value) ~= "table" then
		return value
	end

	local copy = {}
	for key, item in pairs(value) do
		copy[deep_copy(key)] = deep_copy(item)
	end

	return copy
end

local function single_result(results)
	if type(results) ~= "table" then
		return nil
	end

	local count = 0
	local result
	for key, value in pairs(results) do
		if key ~= 1 then
			return nil
		end
		count = count + 1
		result = value
	end

	if count == 1 and type(result) == "table" then
		return result
	end

	return nil
end

local promethium_research_data = {}

function promethium_research_data.data_final_fixes()
	local raw = data and data.raw
	if type(raw) ~= "table" or type(raw.item) ~= "table" or type(raw.recipe) ~= "table" then
		return
	end

	local research_data = raw.item[DATA_NAME]
	if type(research_data) ~= "table" then
		return
	end

	local changed_copies = {}
	for _, entry in ipairs(RECIPES) do
		local recipe = raw.recipe[entry.recipe]
		if type(recipe) == "table" then
			local result = single_result(recipe.results)
			if result and result.type == "item" and result.name == "promethium-science-pack"
				and result.amount == entry.cards then
				result.name = DATA_NAME
				result.amount = entry.data

				if recipe.main_product == "promethium-science-pack" then
					recipe.main_product = DATA_NAME
				end

				if type(recipe.localised_name) == "table"
					and recipe.localised_name[1] == "item-name.promethium-science-pack" then
					recipe.localised_name = {"item-name." .. DATA_NAME}
				end

				if type(recipe.localised_description) == "table"
					and recipe.localised_description[1] == "item-description.promethium-science-pack" then
					recipe.localised_description = nil
				end

				if recipe.icon ~= nil or recipe.icons ~= nil then
					if type(research_data.icons) == "table" then
						recipe.icons = deep_copy(research_data.icons)
						recipe.icon = nil
						recipe.icon_size = nil
					elseif research_data.icon ~= nil then
						recipe.icon = research_data.icon
						recipe.icon_size = research_data.icon_size
						recipe.icons = nil
					end
				end

				local log_prefix = entry.mod and ("razi-protocol: " .. entry.mod .. ": ") or "razi-protocol: "
				log(log_prefix .. entry.recipe .. " makes " .. entry.data .. " " .. DATA_NAME
					.. " instead of " .. entry.cards .. " promethium-science-pack")
				changed_copies[#changed_copies + 1] = "igrys-" .. entry.recipe .. "-enhanced"
			end
		end
	end

	if #changed_copies > 0 then
		require("prototypes.balance.common.hide_recipes").hide(changed_copies)
	end
end

return promethium_research_data
