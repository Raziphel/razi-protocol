local orphan_unlocks = {}

-- Recipes that are created disabled and that no technology unlocks, because the mod that made them meant to add the
-- unlock and did not. They are unreachable in a game: not by hand, not by a machine, not by a recipe productivity
-- technology that already lists them. A repair names the technology that fits the recipe; the technology and the
-- machine that runs the recipe must be reachable by the time it is researched.
local function unlocks_recipe(technology, recipe_name)
	for _, effect in ipairs(technology.effects or {}) do
		if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
			return true
		end
	end

	return false
end

local function is_unlocked(recipe_name)
	for _, technology in pairs(data.raw.technology or {}) do
		if unlocks_recipe(technology, recipe_name) then
			return true
		end
	end

	return false
end

-- The hidden copies rigor-module made of the recipe, one per step of rigor. rigor-module unlocks each copy together
-- with its recipe, in its own data-final-fixes, which runs before this one, so a recipe unlocked here has to bring its
-- copies along, or a machine with a rigor module would have no recipe to run.
local function rigor_copies(recipe_name)
	local table_data = data.raw["mod-data"] and data.raw["mod-data"].rigor_module_mod_recipe_table
	local copies = table_data and table_data.data and table_data.data[recipe_name]
	local names = {}

	if type(copies) == "table" then
		for _, copy_name in pairs(copies) do
			if copy_name ~= recipe_name and data.raw.recipe[copy_name] then
				names[#names + 1] = copy_name
			end
		end
	end

	table.sort(names)
	return names
end

function orphan_unlocks.unlock(recipe_name, technology_name)
	if data.raw.recipe and data.raw.recipe[recipe_name] and not is_unlocked(recipe_name) then
		local technology = data.raw.technology and data.raw.technology[technology_name]

		if technology then
			technology.effects = technology.effects or {}
			table.insert(technology.effects, {type = "unlock-recipe", recipe = recipe_name})

			local copies = rigor_copies(recipe_name)
			for _, copy_name in ipairs(copies) do
				if not is_unlocked(copy_name) then
					table.insert(technology.effects, {type = "unlock-recipe", recipe = copy_name, hidden = true})
				end
			end

			log("razi-protocol: " .. recipe_name .. " is unlocked by " .. technology_name
				.. (#copies > 0 and (" (+" .. #copies .. " rigor copies)") or ""))
		else
			log("razi-protocol: " .. recipe_name .. " has no unlock, and technology " .. technology_name
				.. " does not exist to give it one")
		end
	end
end

return orphan_unlocks
