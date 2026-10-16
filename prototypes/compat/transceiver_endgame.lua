local transceiver_endgame = {}

local transceiver_recipe = "kr-intergalactic-transceiver"
local original_transceiver_tech = "kr-intergalactic-transceiver"
local final_transceiver_tech = "razi-stable-intergalactic-singularity"

local function remove_recipe_unlock(technology_name, recipe_name)
	local technology = data.raw.technology and data.raw.technology[technology_name]
	if not technology or not technology.effects then
		return
	end

	for index = #technology.effects, 1, -1 do
		local effect = technology.effects[index]
		if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
			table.remove(technology.effects, index)
		end
	end
end

local function add_recipe_unlock(technology_name, recipe_name)
	local technology = data.raw.technology and data.raw.technology[technology_name]
	if not technology then
		return
	end

	technology.effects = technology.effects or {}
	for _, effect in ipairs(technology.effects) do
		if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
			return
		end
	end

	table.insert(technology.effects, {
		type = "unlock-recipe",
		recipe = recipe_name
	})
end

-- Science pack multiplier of each stage of the singularity chain
-- (prototypes/technology/transceiver_endgame.lua).
local singularity_stages = {
	{name = "razi-singularity-theory", multiplier = 1},
	{name = "razi-singularity-test-fire", multiplier = 2},
	{name = final_transceiver_tech, multiplier = 3}
}

-- Factorio 2.1 science packs can be plain items (the K2 tech cards and the
-- promethium pack are), so look for both types.
local function science_pack_exists(name)
	return (data.raw.tool and data.raw.tool[name]) or (data.raw.item and data.raw.item[name])
end

local function add_science_pack(ingredients, name, amount)
	if science_pack_exists(name) then
		table.insert(ingredients, {name, amount or 1})
	end
end

local function build_transceiver_science(multiplier)
	local ingredients = {}

	add_science_pack(ingredients, "calidus-tech-card", 1)
	add_science_pack(ingredients, "solaris-tech-card", 1)
	add_science_pack(ingredients, "nyxaris-tech-card", 1)
	add_science_pack(ingredients, "vibrant-tech-card", 1)
	add_science_pack(ingredients, "beetlejuice-tech-card", multiplier)
	add_science_pack(ingredients, "kr-matter-tech-card", 1)
	add_science_pack(ingredients, "kr-advanced-tech-card", 1)
	add_science_pack(ingredients, "kr-singularity-tech-card", multiplier)
	add_science_pack(ingredients, "promethium-science-pack", multiplier)

	return ingredients
end

-- The singularity techs are made in the data stage, before the system tech
-- cards exist (prototypes/compat/lab_cards.lua adds them in data-final-fixes),
-- so they used to end up with no ingredients and cost nothing.
local function fill_singularity_science()
	for _, stage in ipairs(singularity_stages) do
		local technology = data.raw.technology and data.raw.technology[stage.name]
		if technology and technology.unit and #(technology.unit.ingredients or {}) == 0 then
			technology.unit.ingredients = build_transceiver_science(stage.multiplier)
			log("[Razi Protocol/transceiver] " .. stage.name .. ": " .. #technology.unit.ingredients .. " science packs")
		end
	end
end

function transceiver_endgame.data_final_fixes()
	fill_singularity_science()
	-- K2SO should still own the final charge/activation. We just move the recipe
	-- unlock behind our own test-fire research chain.
	remove_recipe_unlock(original_transceiver_tech, transceiver_recipe)
	add_recipe_unlock(final_transceiver_tech, transceiver_recipe)
end

return transceiver_endgame
