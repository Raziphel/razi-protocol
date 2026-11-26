local M = {}

-- bzcarbon's diamond-processing unlocks synthetic-diamond, but Nexus replaces that technology
-- with its own space progression in DFF. Keep Nexus's name and give the BZ recipe a separate
-- technology (bzcarbon/carbon-recipe.lua:249-277; bzcarbon/carbon-recipe-updates.lua:6-8;
-- Nexus/compatibility/Krastorio2-spaced-out/technology_fix.lua:252).
local function unlocks_recipe(technologies, recipe_name)
	for _, technology in pairs(technologies) do
		for _, effect in pairs(technology.effects or {}) do
			if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
				return true
			end
		end
	end

	return false
end

local function note(message)
	if log then
		log("razi-protocol: bz: " .. message)
	end
end

function M.data_final_fixes()
	if not (mods and mods["bzcarbon"]) then
		return
	end

	local raw = data and data.raw or {}
	local recipes = raw.recipe or {}
	local technologies = raw.technology or {}
	if not recipes["synthetic-diamond"] or not technologies["advanced-material-processing-2"] then
		return
	end
	if technologies["razi-bz-diamond-processing"] or unlocks_recipe(technologies, "synthetic-diamond") then
		return
	end

	data:extend({
		{
			type = "technology",
			name = "razi-bz-diamond-processing",
			icon = "__bzcarbon__/graphics/icons/diamond.png",
			icon_size = 128,
			effects = {
				{ type = "unlock-recipe", recipe = "synthetic-diamond" },
			},
			prerequisites = { "advanced-material-processing-2" },
			unit = {
				count = 100,
				ingredients = {
					{ "automation-science-pack", 1 },
					{ "logistic-science-pack", 1 },
					{ "chemical-science-pack", 1 },
				},
				time = 15,
			},
		},
	})
	note("added razi-bz-diamond-processing to unlock synthetic-diamond")

	for _, technology_name in ipairs({ "low-density-structure", "laser" }) do
		local technology = technologies[technology_name]
		if technology and technology.prerequisites then
			local prerequisites = technology.prerequisites
			for index, prerequisite in ipairs(prerequisites) do
				if prerequisite == "diamond-processing" then
					prerequisites[index] = "razi-bz-diamond-processing"
					note(technology_name .. " requires razi-bz-diamond-processing instead of diamond-processing")
				end
			end
		end
	end
end

return M
