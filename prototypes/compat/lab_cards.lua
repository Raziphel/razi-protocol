local lab_cards = {}
local Prototype = require("__razi_lib__/lib/prototype")
local Recipe = require("__razi_lib__/lib/recipe")
local Science = require("__razi_lib__/lib/science")
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
		craft_time = 10, regional_science_amount = 1,
		unlock_technology_candidates = {"space-science-pack", "planet-discovery-muluna"},
		ingredients = {
			"automation-science-pack", "logistic-science-pack",
			"military-science-pack", "chemical-science-pack",
			"production-science-pack", "utility-science-pack",
			"space-science-pack"
			-- The frontier systems now own metallurgy, biology and electronics.
			-- No later-planet science may be needed to construct this first card.
		},
		fallback_ingredients = {"automation-science-pack"}
	},
	{
		name = "solaris-tech-card",
		localised_name = {"item-name.solaris-tech-card"},
		icon = "__razi-protocol__/graphics/icons/tech-cards/solaris-tech-card.png",
		order = "s[system]-b[solaris]",
		craft_time = 12, regional_science_amount = 1,
		unlock_technology_candidates = {"planet-discovery-corrundum", "planet-discovery-castra"},
		ingredients = {
			"calidus-tech-card", "metallurgic-science-pack",
			"tungsten-science-pack", "battlefield-science-pack",
			"planetaris-compression-science-pack",
			"planetaris-polishing-science-pack",
			"planetaris-bioengineering-science-pack",
			"planetaris-pathological-science-pack",
			"planetaris-refraction-science-pack"
            -- Paracelsin electrochemistry is reached in the NEXT frontier.
            -- It must not block the Solaris card used to enter Vibrant.
		},
		fallback_ingredients = {"calidus-tech-card", "space-science-pack"}
	},
	{
		name = "nyxaris-tech-card",
		localised_name = {"item-name.nyxaris-tech-card"},
		icon = "__razi-protocol__/graphics/icons/tech-cards/nyxaris-tech-card.png",
		order = "s[system]-c[nyxaris]",
		craft_time = 12, regional_science_amount = 1,
		-- Never put optional Dea Dia / Pelagos science into a mandatory card.
		-- Panglia is the last core Nyxaris discovery.
		unlock_technology_candidates = {
			"panglia_planet_discovery_panglia",
			"planet-discovery-apia-carnova",
			"planet-discovery-moshine"
		},
		ingredients = {
			"calidus-tech-card", "agricultural-science-pack",
			"insulation-science-pack",
			"thermodynamic-science-pack", "apicultural-science-pack",
			"aerospace-science-pack"
		},
		fallback_ingredients = {"calidus-tech-card", "space-science-pack"}
	},
	{
		name = "vibrant-tech-card",
		localised_name = {"item-name.vibrant-tech-card"},
		icon = "__razi-protocol__/graphics/icons/tech-cards/vibrant-tech-card.png",
		order = "s[system]-d[vibrant]",
		craft_time = 16, regional_science_amount = 1,
		unlock_technology_candidates = {"planet-discovery-paracelsin", "planet-discovery-ribbonia"},
		ingredients = {
			"solaris-tech-card", "nyxaris-tech-card",
			"electromagnetic-science-pack", "ribbonia-alien-science-pack",
			"electrochemical-science-pack"
			-- Paracelsin chemistry now contributes to Vibrant completion.
			-- Optional side-world science is not a mandatory gate.
		},
		fallback_ingredients = {"solaris-tech-card", "nyxaris-tech-card"}
	},
	{
		name = "vespera-tech-card",
		localised_name = {"item-name.vespera-tech-card"},
		icon = "__razi-protocol__/graphics/icons/tech-cards/vespera-tech-card.png",
		order = "s[system]-e[vespera]",
		craft_time = 16, regional_science_amount = 1,
		unlock_technology_candidates = {"planet-discovery-maraxsis", "planet-discovery-rubia", "planet-discovery-muria"},
		ingredients = {
			"solaris-tech-card", "nyxaris-tech-card",
			"muriatic-science-pack", "cryogenic-science-pack",
			"biorecycling-science-pack", "rubia-biofusion-science-pack",
			"hydraulic-science-pack"
			-- Maraxsis industry completes Vespera, not its entry.
		},
		fallback_ingredients = {"solaris-tech-card", "nyxaris-tech-card"}
	},
	{
		name = "beetlejuice-tech-card",
		localised_name = {"item-name.beetlejuice-tech-card"},
		icon = "__razi-protocol__/graphics/icons/tech-cards/beetlejuice-tech-card.png",
		order = "s[system]-f[beetlejuice]",
		craft_time = 22, regional_science_amount = 2,
		unlock_technology_candidates = {"linox-technology_planet-discovery-linox", "planet-discovery-secretas", "planet-discovery-cubium"},
		ingredients = {
			"vibrant-tech-card", "vespera-tech-card",
			"golden-science-pack", "linox-item_linox-science-pack"
		},
		fallback_ingredients = {"vibrant-tech-card", "vespera-tech-card"}
	},
	{
		name = "umbra-tech-card",
		localised_name = {"item-name.umbra-tech-card"},
		icon = "__razi-protocol__/graphics/icons/tech-cards/umbra-tech-card.png",
		order = "s[system]-g[umbra]",
		craft_time = 22, regional_science_amount = 2,
		unlock_technology_candidates = {"planet-discovery-vesta", "planet-discovery-crucible", "planet-discovery-tenebris"},
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
		craft_time = 28, regional_science_amount = 2,
		unlock_technology_candidates = {"razi-singularity-theory", "promethium-882-research"},
		ingredients = {
			"beetlejuice-tech-card", "umbra-tech-card",
			"promethium-science-pack"
            -- Aegis/Bellicos logistics and pulsar science lie beyond the
            -- first Deep Space experiments. They remain optional freight.
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
	return Science.exists(name)
end

-- Mandatory cards now unlock at a chapter completion milestone,
-- rather than the first planet. Optional side-world sciences stay optional.
-- Native frontier sciences become more demanding at the outer edge;
-- predecessor SYSTEM cards always stay at one per recipe to avoid
-- multiplying the entire campaign's earlier factories recursively.
local function build_recipe_ingredients(science_packs, regional_amount)
	local ingredients = {}

	for _, science_pack in ipairs(science_packs or {}) do
		if science_pack_exists(science_pack) then
			local amount = science_pack:match("%-tech%-card$") and 1 or (regional_amount or 1)
			table.insert(ingredients, {type = "item", name = science_pack, amount = amount})
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
	return Technology.first_existing_name(candidates)
end

local function upsert_system_card(card)
	local ingredients = build_recipe_ingredients(card.ingredients, card.regional_science_amount)
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
		tool.icon = card.icon
		tool.icon_size = system_card_icon_size
		tool.icons = nil
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
				energy_required = card.craft_time or 10,
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
			:set_energy(card.craft_time or 10)
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
	Science.add_lab_input(lab, input_name)
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
	-- Science Tab is a recommended companion, not an essential mod.
	-- Vanilla Factorio has no guaranteed `science` item group.
	local group = data.raw["item-group"] and data.raw["item-group"]["science"]
		and "science" or "intermediate-products"
	ensure_item_subgroup(system_card_subgroup, group, "0[system-tech-card]")

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
