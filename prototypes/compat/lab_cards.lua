local lab_cards = {}

local system_card_subgroup = "system-tech-card"
local vanilla_science_weight = 1000

local system_card_definitions = {
	{
		name = "calidus-tech-card",
		localised_name = "Calidus Tech Card",
		tint = {r = 1.0, g = 0.86, b = 0.08},
		order = "s[system]-a[calidus]",
		unlock_technology_candidates = {
			"moon-discovery-cerys"
		},
		ingredients = {
			"automation-science-pack",
			"logistic-science-pack",
			"military-science-pack",
			"chemical-science-pack",
			"production-science-pack",
			"utility-science-pack",
			"space-science-pack",
			"metallurgic-science-pack",
			"electromagnetic-science-pack",
			"agricultural-science-pack",
			"lithium-science-pack",
			"tungsten-science-pack",
			"lunar-science-pack",
			"interstellar-science-pack",
			"advanced-space-science-pack",
			"cerysian-science-pack"
		},
		fallback_ingredients = {
			"automation-science-pack"
		}
	},
	{
		name = "solaris-tech-card",
		localised_name = "Solaris Tech Card",
		tint = {r = 1.0, g = 0.52, b = 0.18},
		order = "s[system]-b[solaris]",
		unlock_technology_candidates = {
			"planet-discovery-castra"
		},
		ingredients = {
			"battlefield-science-pack",
			"planetaris-compression-science-pack",
			"planetaris-polishing-science-pack",
			"planetaris-bioengineering-science-pack",
			"planetaris-pathological-science-pack",
			"planetaris-refraction-science-pack",
			"electrochemical-science-pack"
		},
		fallback_ingredients = {
			"calidus-tech-card",
			"space-science-pack"
		}
	},
	{
		name = "nyxaris-tech-card",
		localised_name = "Nyxaris Tech Card",
		tint = {r = 0.36, g = 0.62, b = 1.0},
		order = "s[system]-c[nyxaris]",
		unlock_technology_candidates = {
			"system-discovery-dea-dia",
			"planet-discovery-dea-dia",
			"planet-discovery-apia-carnova",
			"planet-discovery-moshine",
			"planet-discovery-pelagos"
		},
		ingredients = {
			"aerospace-science-pack",
			"insulation-science-pack",
			"thermodynamic-science-pack",
			"apicultural-science-pack",
			"pelagos-science-pack"
		},
		fallback_ingredients = {
			"solaris-tech-card",
			"space-science-pack"
		}
	},
	{
		name = "vibrant-tech-card",
		localised_name = "Vibrant Tech Card",
		tint = {r = 0.82, g = 0.28, b = 1.0},
		order = "s[system]-d[vibrant]",
		unlock_technology_candidates = {
			"planet-discovery-ribbonia",
			"planet-discovery-aquilo",
			"planet-discovery-maraxsis"
		},
		ingredients = {
			"ribbonia-alien-science-pack",
			"biorecycling-science-pack",
			"rubia-biofusion-science-pack",
			"galvanization-science-pack",
			"paracelsin-galvanization-science-pack",
			"hydraulic-science-pack"
		},
		fallback_ingredients = {
			"nyxaris-tech-card",
			"space-science-pack"
		}
	},
	{
		name = "beetlejuice-tech-card",
		localised_name = "Beetlejuice Tech Card",
		tint = {r = 0.22, g = 1.0, b = 0.42},
		order = "s[system]-e[beetlejuice]",
		unlock_technology_candidates = {
			"planet-discovery-cubium",
			"planet-discovery-tenebris"
		},
		ingredients = {
			"bioluminescent-science-pack",
			"cryogenic-science-pack",
			"gas-manipulation-science-pack",
			"planet-crucible-science-pack",
			"golden-science-pack"
		},
		fallback_ingredients = {
			"vibrant-tech-card",
			"space-science-pack"
		}
	},
	{
		name = "deep-space-tech-card",
		localised_name = "Deep Space Tech Card",
		tint = {r = 0.18, g = 0.18, b = 0.22},
		order = "s[system]-f[deep-space]",
		unlock_technology_candidates = {
			"promethium-882-research"
		},
		ingredients = {
			"beetlejuice-tech-card",
			"promethium-science-pack",
			"promethium-882-science-pack"
		},
		fallback_ingredients = {
			"beetlejuice-tech-card",
			"promethium-science-pack"
		}
	}
}

local modded_science_ids = {
	"lunar-science-pack",
	"interstellar-science-pack",
	"advanced-space-science-pack",
	"cerysian-science-pack",
	"battlefield-science-pack",
	"planetaris-compression-science-pack",
	"planetaris-polishing-science-pack",
	"planetaris-bioengineering-science-pack",
	"planetaris-pathological-science-pack",
	"planetaris-refraction-science-pack",
	"electrochemical-science-pack",
	"aerospace-science-pack",
	"insulation-science-pack",
	"thermodynamic-science-pack",
	"apicultural-science-pack",
	"pelagos-science-pack",
	"ribbonia-alien-science-pack",
	"biorecycling-science-pack",
	"rubia-biofusion-science-pack",
	"galvanization-science-pack",
	"paracelsin-galvanization-science-pack",
	"hydraulic-science-pack",
	"bioluminescent-science-pack",
	"gas-manipulation-science-pack",
	"planet-crucible-science-pack",
	"golden-science-pack",
	"promethium-science-pack",
	"promethium-882-science-pack",
	"antimatter-science-pack",
	"void-science-pack",
	"voidp-void-science-pack",
	"kr-advanced-tech-card",
	"kr-matter-tech-card",
	"kr-singularity-tech-card",
	"calidus-tech-card",
	"solaris-tech-card",
	"nyxaris-tech-card",
	"vibrant-tech-card",
	"beetlejuice-tech-card",
	"deep-space-tech-card"
}

local function ensure_item_subgroup(name, group, order)
	local subgroup = data.raw["item-subgroup"] and data.raw["item-subgroup"][name]
	if subgroup then
		subgroup.group = group or subgroup.group
		subgroup.order = order or subgroup.order
		return
	end

	data:extend({
		{
			type = "item-subgroup",
			name = name,
			group = group,
			order = order
		}
	})
end

local function science_pack_exists(name)
	return
		(data.raw.tool and data.raw.tool[name]) or
		(data.raw.item and data.raw.item[name])
end

local function build_recipe_ingredients(science_packs)
	local ingredients = {}

	for _, science_pack in ipairs(science_packs or {}) do
		if science_pack_exists(science_pack) then
			table.insert(ingredients, {type = "item", name = science_pack, amount = 1})
		end
	end

	return ingredients
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

local function find_first_existing_technology(candidates)
	for _, technology_name in ipairs(candidates or {}) do
		if data.raw.technology and data.raw.technology[technology_name] then
			return technology_name
		end
	end

	return nil
end

local function upsert_system_card(card)
	local ingredients = build_recipe_ingredients(card.ingredients)
	if #ingredients == 0 then
		ingredients = build_recipe_ingredients(card.fallback_ingredients)
	end

	if #ingredients == 0 then
		return
	end

	local tool = data.raw.tool and data.raw.tool[card.name]
	if not tool then
		data:extend({
			{
				type = "tool",
				name = card.name,
				localised_name = {"", card.localised_name},
				localised_description = {"item-description.science-pack"},
				icons = {
					{
						icon = "__base__/graphics/icons/space-science-pack.png",
						icon_size = 64,
						tint = card.tint
					}
				},
				subgroup = system_card_subgroup,
				order = card.order,
				stack_size = 200,
				weight = vanilla_science_weight,
				durability = 1,
				durability_description_key = "description.science-pack-remaining-amount-key",
				factoriopedia_durability_description_key = "description.factoriopedia-science-pack-remaining-amount-key",
				durability_description_value = "description.science-pack-remaining-amount-value"
			}
		})
		tool = data.raw.tool and data.raw.tool[card.name]
	end

	if tool then
		tool.localised_name = {"", card.localised_name}
		tool.localised_description = {"item-description.science-pack"}
		tool.icons = {
			{
				icon = "__base__/graphics/icons/space-science-pack.png",
				icon_size = 64,
				tint = card.tint
			}
		}
		tool.subgroup = system_card_subgroup
		tool.order = card.order
		tool.stack_size = 200
		tool.weight = vanilla_science_weight
		tool.durability = 1
		tool.durability_description_key = "description.science-pack-remaining-amount-key"
		tool.factoriopedia_durability_description_key = "description.factoriopedia-science-pack-remaining-amount-key"
		tool.durability_description_value = "description.science-pack-remaining-amount-value"
	end

	local recipe = data.raw.recipe and data.raw.recipe[card.name]
	if not recipe then
		data:extend({
			{
				type = "recipe",
				name = card.name,
				localised_name = {"", card.localised_name},
				enabled = false,
				category = "crafting",
				energy_required = 10,
				ingredients = ingredients,
				results = {
					{type = "item", name = card.name, amount = 1}
				},
				subgroup = system_card_subgroup,
				order = card.order
			}
		})
		recipe = data.raw.recipe and data.raw.recipe[card.name]
	end

	if recipe then
		recipe.localised_name = {"", card.localised_name}
		recipe.enabled = false
		recipe.category = "crafting"
		recipe.energy_required = 10
		recipe.ingredients = ingredients
		recipe.results = {
			{type = "item", name = card.name, amount = 1}
		}
		recipe.subgroup = system_card_subgroup
		recipe.order = card.order
	end

	local unlock_technology = find_first_existing_technology(card.unlock_technology_candidates)
	if unlock_technology then
		add_recipe_unlock(unlock_technology, card.name)
	end
end

local function add_unique_input(lab, input_name)
	for _, existing in ipairs(lab.inputs or {}) do
		if existing == input_name then
			return
		end
	end

	table.insert(lab.inputs, input_name)
end

local function set_science_weight(name, weight)
	local tool = data.raw.tool and data.raw.tool[name]
	if tool then
		tool.weight = weight
	end

	local item = data.raw.item and data.raw.item[name]
	if item then
		item.weight = weight
	end
end

function lab_cards.data_final_fixes()
	ensure_item_subgroup(system_card_subgroup, "science", "0[system-tech-card]")

	for _, card in ipairs(system_card_definitions) do
		upsert_system_card(card)
	end

	for _, science_name in ipairs(modded_science_ids) do
		set_science_weight(science_name, vanilla_science_weight)
	end

	-- Do not add every modded science pack to every lab.
	-- Planet and mod-specific science packs must stay on the labs that own them.
	-- System tech cards are handled by progression.lua.
end

return lab_cards
