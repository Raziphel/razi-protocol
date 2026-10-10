local lab_cards = {}
local Collections = require("__razi_lib__/lib/collections")
local Prototype = require("__razi_lib__/lib/prototype")
local Recipe = require("__razi_lib__/lib/recipe")
local Technology = require("__razi_lib__/lib/technology")

local system_card_subgroup = "system-tech-card"
local vanilla_science_weight = 1000
local system_card_icon_size = 256

local system_card_definitions = {
	{
		name = "calidus-tech-card",
		localised_name = {"item-name.calidus-tech-card"},
		icon = "__razi-protocol__/graphics/icons/tech-cards/calidus-tech-card.png",
		order = "s[system]-a[calidus]",
		unlock_technology_candidates = {"planet-discovery-muluna", "space-science-pack"},
		ingredients = {
			"automation-science-pack", "logistic-science-pack",
			"military-science-pack", "chemical-science-pack",
			"production-science-pack", "utility-science-pack",
			"space-science-pack", "metallurgic-science-pack",
			"electromagnetic-science-pack", "agricultural-science-pack",
			"tungsten-science-pack", "lunar-science-pack",
			"interstellar-science-pack", "advanced-space-science-pack"
		},
		fallback_ingredients = {"automation-science-pack"}
	},
	{
		name = "solaris-tech-card",
		localised_name = {"item-name.solaris-tech-card"},
		icon = "__razi-protocol__/graphics/icons/tech-cards/solaris-tech-card.png",
		order = "s[system]-b[solaris]",
		unlock_technology_candidates = {"planet-discovery-castra"},
		ingredients = {
			"calidus-tech-card", "battlefield-science-pack",
			"planetaris-compression-science-pack",
			"planetaris-polishing-science-pack",
			"planetaris-bioengineering-science-pack",
			"planetaris-pathological-science-pack",
			"planetaris-refraction-science-pack", "electrochemical-science-pack"
		},
		fallback_ingredients = {"calidus-tech-card", "space-science-pack"}
	},
	{
		name = "nyxaris-tech-card",
		localised_name = {"item-name.nyxaris-tech-card"},
		icon = "__razi-protocol__/graphics/icons/tech-cards/nyxaris-tech-card.png",
		order = "s[system]-c[nyxaris]",
		-- Never put optional Dea Dia / Pelagos science into a mandatory card.
		unlock_technology_candidates = {
			"planet-discovery-moshine",
			"planet-discovery-apia-carnova",
			"panglia_planet_discovery_panglia"
		},
		ingredients = {
			"calidus-tech-card", "insulation-science-pack",
			"thermodynamic-science-pack", "apicultural-science-pack"
		},
		fallback_ingredients = {"calidus-tech-card", "space-science-pack"}
	},
	{
		name = "vibrant-tech-card",
		localised_name = {"item-name.vibrant-tech-card"},
		icon = "__razi-protocol__/graphics/icons/tech-cards/vibrant-tech-card.png",
		order = "s[system]-d[vibrant]",
		unlock_technology_candidates = {"planet-discovery-ribbonia"},
		ingredients = {
			"solaris-tech-card", "nyxaris-tech-card",
			"ribbonia-alien-science-pack",
			"galvanization-science-pack", "paracelsin-galvanization-science-pack",
			"vanadium-science-pack"
		},
		fallback_ingredients = {"solaris-tech-card", "nyxaris-tech-card"}
	},
	{
		name = "vespera-tech-card",
		localised_name = {"item-name.vespera-tech-card"},
		icon = "__razi-protocol__/graphics/icons/tech-cards/vibrant-tech-card.png",
		tint = {r = 0.45, g = 0.85, b = 1, a = 1},
		order = "s[system]-e[vespera]",
		unlock_technology_candidates = {"planet-discovery-muria"},
		ingredients = {
			"solaris-tech-card", "nyxaris-tech-card",
			"muriatic-science-pack", "cryogenic-science-pack",
			"biorecycling-science-pack", "rubia-biofusion-science-pack",
			"hydraulic-science-pack"
		},
		fallback_ingredients = {"solaris-tech-card", "nyxaris-tech-card"}
	},
	{
		name = "beetlejuice-tech-card",
		localised_name = {"item-name.beetlejuice-tech-card"},
		icon = "__razi-protocol__/graphics/icons/tech-cards/beetlejuice-tech-card.png",
		order = "s[system]-f[beetlejuice]",
		unlock_technology_candidates = {"planet-discovery-cubium"},
		ingredients = {
			"vibrant-tech-card", "vespera-tech-card",
			"golden-science-pack"
		},
		fallback_ingredients = {"vibrant-tech-card", "vespera-tech-card"}
	},
	{
		name = "umbra-tech-card",
		localised_name = {"item-name.umbra-tech-card"},
		icon = "__razi-protocol__/graphics/icons/tech-cards/deep-space-tech-card.png",
		tint = {r = 0.72, g = 0.52, b = 1, a = 1},
		order = "s[system]-g[umbra]",
		unlock_technology_candidates = {"planet-discovery-tenebris"},
		ingredients = {
			"vibrant-tech-card", "vespera-tech-card",
			"bioluminescent-science-pack", "gas-manipulation-science-pack",
			"planet-crucible-science-pack"
		},
		fallback_ingredients = {"vibrant-tech-card", "vespera-tech-card"}
	},
	{
		name = "deep-space-tech-card",
		localised_name = {"item-name.deep-space-tech-card"},
		icon = "__razi-protocol__/graphics/icons/tech-cards/deep-space-tech-card.png",
		order = "s[system]-h[deep-space]",
		unlock_technology_candidates = {"razi-singularity-theory", "promethium-882-research"},
		ingredients = {
			"beetlejuice-tech-card", "umbra-tech-card",
			"promethium-science-pack", "space-logistic-science-pack",
			"pulsar-science-pack"
		},
		fallback_ingredients = {"beetlejuice-tech-card", "umbra-tech-card"}
	}
}

local modded_science_ids = {
	"space-logistic-science-pack",
	"pulsar-science-pack",
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
	"muriatic-science-pack",
	"vanadium-science-pack",
	"calidus-tech-card",
	"solaris-tech-card",
	"nyxaris-tech-card",
	"vibrant-tech-card",
	"vespera-tech-card",
	"beetlejuice-tech-card",
	"umbra-tech-card",
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
	return Prototype.exists("tool", name) or Prototype.exists("item", name)
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
	local technology = Technology.optional(technology_name)
	if not technology then
		return
	end

	technology:unlock(recipe_name)
end

local function find_first_existing_technology(candidates)
	for _, technology_name in ipairs(candidates or {}) do
		if Prototype.exists("technology", technology_name) then
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

	local tool = Prototype.raw("tool", card.name)
	if not tool then
		data:extend({
			{
				type = "tool",
				name = card.name,
				localised_name = {"", card.localised_name},
				localised_description = {"item-description.science-pack"},
				icon = card.icon,
				icon_size = system_card_icon_size,
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
		tool = Prototype.raw("tool", card.name)
	end

	if tool then
		tool.localised_name = {"", card.localised_name}
		tool.localised_description = {"item-description.science-pack"}
		-- Tint existing icons for the new systems until dedicated artwork lands.
		tool.icon = card.tint and nil or card.icon
		tool.icon_size = system_card_icon_size
		tool.icons = card.tint and {{
			icon = card.icon,
			icon_size = system_card_icon_size,
			tint = card.tint
		}} or nil
		tool.subgroup = system_card_subgroup
		tool.order = card.order
		tool.stack_size = 200
		tool.weight = vanilla_science_weight
		tool.durability = 1
		tool.durability_description_key = "description.science-pack-remaining-amount-key"
		tool.factoriopedia_durability_description_key = "description.factoriopedia-science-pack-remaining-amount-key"
		tool.durability_description_value = "description.science-pack-remaining-amount-value"
	end

	local recipe = Recipe.optional(card.name)
	if not recipe then
		data:extend({
			{
				type = "recipe",
				name = card.name,
				localised_name = {"", card.localised_name},
				enabled = false,
				categories = {"crafting"},
				energy_required = 10,
				ingredients = ingredients,
				results = {
					{type = "item", name = card.name, amount = 1}
				},
				subgroup = system_card_subgroup,
				order = card.order
			}
		})
		recipe = Recipe.optional(card.name)
	end

	if recipe then
		recipe.localised_name = {"", card.localised_name}
		recipe
			:set_categories({"crafting"})
			:set_energy(10)
			:set_ingredients(ingredients)
			:set_results({
				{type = "item", name = card.name, amount = 1}
			})
			:set_subgroup(system_card_subgroup, card.order)
			:disable()
	end

	local unlock_technology = find_first_existing_technology(card.unlock_technology_candidates)
	if unlock_technology then
		add_recipe_unlock(unlock_technology, card.name)
	end
end

local function add_unique_input(lab, input_name)
	Collections.append_unique(lab.inputs, input_name)
end

local function set_science_weight(name, weight)
	local tool = Prototype.raw("tool", name)
	if tool then
		tool.weight = weight
	end

	local item = Prototype.raw("item", name)
	if item then
		item.weight = weight
	end
end

local regular_lab_names = {
	"lab",
	"kr-advanced-lab",
	"biolab",
	"kr-singularity-lab",
	"thermodynamics-lab",
	"pressure-lab",
	"omega-lab"
}

local function add_system_cards_to_regular_labs()
	for _, lab_name in ipairs(regular_lab_names) do
		local lab = data.raw.lab and data.raw.lab[lab_name]
		if lab and lab.inputs then
			for _, card in ipairs(system_card_definitions) do
				-- Deep Space remains an endgame-only input. Nexus adds it to the
				-- singularity lab and the omega lab through nexus_endgame.lua when that
				-- integration is installed.
				if card.name ~= "deep-space-tech-card" and science_pack_exists(card.name) then
					add_unique_input(lab, card.name)
				end
			end
		end
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

	add_system_cards_to_regular_labs()

	-- Do not add every modded science pack to every lab.
	-- Planet and mod-specific science packs must stay on the labs that own them.
	-- Only Razi Protocol's compressed system cards are shared by regular labs.
end

return lab_cards
