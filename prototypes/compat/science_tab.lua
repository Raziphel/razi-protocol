local science_tab = {}

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

local function set_subgroup(prototype_type, name, subgroup)
	local prototype = data.raw[prototype_type] and data.raw[prototype_type][name]
	if prototype then
		prototype.subgroup = subgroup
	end
end

local function move_science_pack(name, subgroup)
	set_subgroup("tool", name, subgroup)
	set_subgroup("item", name, subgroup)
	set_subgroup("recipe", name, subgroup)
end

function science_tab.data_updates()
	if not mods["science-tab"] then
		return
	end

	-- Science Tab directly indexes these subgroups for supported mods. In this
	-- pack, some of those mods can rename or remove them before final fixes.
	ensure_item_subgroup("maraxsis-deepsea-research", "intermediate-products", "z[maraxsis-deepsea-research]")
	ensure_item_subgroup("maraxsis-fill-research-vessel", "intermediate-products", "z[maraxsis-fill-research-vessel]")
	ensure_item_subgroup("maraxsis-empty-research-vessel", "intermediate-products", "z[maraxsis-empty-research-vessel]")
	ensure_item_subgroup("kr-tech-cards-cooling", "intermediate-products", "z[kr-tech-cards-cooling]")
end

function science_tab.data_final_fixes()
	if not mods["science-tab"] or not (data.raw["item-group"] and data.raw["item-group"].science) then
		return
	end

	local science_group = data.raw["item-group"].science
	science_group.order = "fz[science]"

	ensure_item_subgroup("system-tech-card", "science", "0[system-tech-card]")
	ensure_item_subgroup("planet-science-pack", "science", "9[planet-science]")
	ensure_item_subgroup("research-data", "science", "1[research-data]")

	local system_tech_cards = {
		"calidus-tech-card",
		"solaris-tech-card",
		"nyxaris-tech-card",
		"vibrant-tech-card",
		"beetlejuice-tech-card",
		"deep-space-tech-card"
	}

	local planet_science_packs = {
		"ambition-science-pack",
		"bioluminescent-science-pack",
		"hydraulic-science-pack",
		"biorecycling-science-pack",
		"muriatic-science-pack",
		"rubia-biofusion-science-pack",
		"vanadium-science-pack",
		"planet-crucible-science-pack",
		"battlefield-science-pack",
		"cryogenic-science-pack",
		"electrochemical-science-pack",
		"golden-science-pack",
		"metallurgic-science-pack",
		"agricultural-science-pack",
		"electromagnetic-science-pack",
		"promethium-science-pack"
	}

	for _, pack in ipairs(system_tech_cards) do
		move_science_pack(pack, "system-tech-card")
	end

	for _, pack in ipairs(planet_science_packs) do
		move_science_pack(pack, "planet-science-pack")
	end

	for _, name in pairs({
		"castra-data",
		"kr-biter-research-data",
		"kr-matter-research-data",
		"kr-metallurgic-research-data",
		"kr-agricultural-research-data",
		"kr-cryogenic-research-data",
		"kr-electromagnetic-research-data",
		"kr-promethium-research-data",
		"hydraulic-research-data",
		"datacell-empty",
		"datacell-raw-data",
		"datacell-ai-model-data",
		"datacell-equation",
		"datacell-solved-equation",
		"datacell-dna-raw",
		"datacell-dna-sequenced",
		"linox-item_lava-data-card",
		"linox-item_rare-earth-data-card",
		"linox-item_samarium-data-card",
		"linox-item_dysprosium-data-card",
		"linox-item_neodymium-data-card",
		"linox-item_erbium-data-card"
	}) do
		set_subgroup("tool", name, "research-data")
		set_subgroup("item", name, "research-data")
		set_subgroup("recipe", name, "research-data")
	end

	-- Do not add system tech cards to lab.inputs here.
	-- This was a duplicate of progression.lua, and this duplicate must not exist.
	-- Science Tab compatibility should only move science items between subgroups.
	-- Deep space lab inputs are handled by omega-lab in nexus_endgame.lua.
end

return science_tab
