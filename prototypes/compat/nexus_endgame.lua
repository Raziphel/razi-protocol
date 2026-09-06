local nexus_endgame = {}

local deep_space_card = "deep-space-tech-card"

local omega_science_packs = {
	"omega-automation-science-pack",
	"omega-logistic-science-pack",
	"omega-military-science-pack",
	"omega-chemical-science-pack",
	"omega-production-science-pack",
	"omega-utility-science-pack",
	"omega-space-science-pack",
	"omega-metallurgic-science-pack",
	"omega-electromagnetic-science-pack",
	"omega-agricultural-science-pack",
	"omega-cryogenic-science-pack"
}

local omega_science_pack_lookup = {}
for _, science_pack in ipairs(omega_science_packs) do
	omega_science_pack_lookup[science_pack] = true
end

local function ingredient_name(ingredient)
	return ingredient and (ingredient.name or ingredient[1])
end

local function ingredient_amount(ingredient)
	return ingredient and (ingredient.amount or ingredient[2] or 1) or 1
end

local function add_unique_science_pack(ingredients, science_pack, amount)
	if not (data.raw.tool and data.raw.tool[science_pack]) then
		return
	end

	for _, ingredient in ipairs(ingredients) do
		if ingredient_name(ingredient) == science_pack then
			if ingredient[2] then
				ingredient[2] = math.max(ingredient[2], amount)
			else
				ingredient.amount = math.max(ingredient.amount or 1, amount)
			end
			return
		end
	end

	table.insert(ingredients, {science_pack, amount})
end

local function replace_omega_science(technology)
	local ingredients = technology.unit and technology.unit.ingredients
	if not ingredients then
		return
	end

	local highest_omega_amount = 0
	local new_ingredients = {}

	for _, ingredient in ipairs(ingredients) do
		local name = ingredient_name(ingredient)
		if omega_science_pack_lookup[name] then
			highest_omega_amount = math.max(highest_omega_amount, ingredient_amount(ingredient))
		else
			table.insert(new_ingredients, ingredient)
		end
	end

	if highest_omega_amount > 0 then
		-- Nexus made one Omega pack per science color. We already have a system
		-- card ladder, so fold that fan-out into one black card and keep the cost.
		add_unique_science_pack(new_ingredients, deep_space_card, highest_omega_amount)
		technology.unit.ingredients = new_ingredients
	end
end

local function recipe_name_from_effect(effect)
	if effect and effect.type == "unlock-recipe" then
		return effect.recipe
	end
end

local function prune_omega_recipe_unlocks(technology)
	if not technology or not technology.effects then
		return
	end

	for index = #technology.effects, 1, -1 do
		local recipe_name = recipe_name_from_effect(technology.effects[index])
		if omega_science_pack_lookup[recipe_name] then
			table.remove(technology.effects, index)
		end
	end

	local unlock_exists = false
	for _, effect in ipairs(technology.effects) do
		if recipe_name_from_effect(effect) == deep_space_card then
			unlock_exists = true
			break
		end
	end

	if not unlock_exists and data.raw.recipe and data.raw.recipe[deep_space_card] then
		table.insert(technology.effects, {
			type = "unlock-recipe",
			recipe = deep_space_card
		})
	end
end

local function tuck_away_omega_recipe(recipe_name)
	local recipe = data.raw.recipe and data.raw.recipe[recipe_name]
	if recipe then
		recipe.enabled = false
		recipe.hidden = true
		recipe.hide_from_player_crafting = true
		recipe.hidden_in_factoriopedia = true
	end
end

local function tuck_away_omega_tool(tool_name)
	local tool = data.raw.tool and data.raw.tool[tool_name]
	if tool then
		tool.hidden = true
		tool.hidden_in_factoriopedia = true
	end
end

local function science_pack_exists(science_pack)
	return
		(data.raw.tool and data.raw.tool[science_pack]) or
		(data.raw.item and data.raw.item[science_pack])
end

local function add_input_to_lab(lab, science_pack)
	if not (lab and lab.inputs and science_pack_exists(science_pack)) then
		return
	end

	for _, input in ipairs(lab.inputs) do
		if input == science_pack then
			return
		end
	end

	table.insert(lab.inputs, science_pack)
end

local function add_endgame_science_to_singularity_lab()
	local singularity_lab = data.raw.lab and data.raw.lab["kr-singularity-lab"]
	if not (singularity_lab and singularity_lab.inputs) then
		return
	end

	for _, science_pack in ipairs({
		"promethium-882-science-pack",
		"antimatter-science-pack",
		deep_space_card
	}) do
		add_input_to_lab(singularity_lab, science_pack)
	end
end

function nexus_endgame.data_final_fixes()
	if not mods["Nexus"] then
		return
	end

	for _, technology in pairs(data.raw.technology or {}) do
		replace_omega_science(technology)
	end

	for _, recipe_name in ipairs(omega_science_packs) do
		tuck_away_omega_recipe(recipe_name)
		tuck_away_omega_tool(recipe_name)
	end

	prune_omega_recipe_unlocks(data.raw.technology and data.raw.technology["promethium-882-research"])
	add_endgame_science_to_singularity_lab()
end

return nexus_endgame
