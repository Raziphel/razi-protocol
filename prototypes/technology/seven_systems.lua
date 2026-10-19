-- New system gates. Existing discoveries keep their prototype IDs for saves.
local TechnologyGraph = require("__razi_lib__/lib/technology_graph")

local seven_systems = {}

local star_icons = {
	vespera = "__razi-protocol__/graphics/icons/VesperaStar.png",
	umbra = "__razi-protocol__/graphics/icons/UmbraStar.png"
}

local function new_discovery(name, star, order, count, prerequisites, packs)
	return {
		type = "technology",
		name = name,
		localised_name = {"technology-name." .. name},
		icon = star_icons[star],
		icon_size = 1024,
		essential = true,
		order = order,
		prerequisites = prerequisites,
		effects = {{
			type = "unlock-space-location",
			space_location = "sye-" .. star,
			use_icon_overlay_constant = true
		}},
		unit = {count = count, time = 60, ingredients = packs}
	}
end

data:extend({
	new_discovery(
		"vespera-discovery", "vespera", "ec[vespera]", 1300,
		{"solaris-discovery", "nyxaris-discovery"},
		{{"solaris-tech-card", 1}, {"nyxaris-tech-card", 1}}
	),
	new_discovery(
		"umbra-discovery", "umbra", "ef[umbra]", 1700,
		{"vibrant-discovery", "vespera-discovery"},
		{{"vibrant-tech-card", 1}, {"vespera-tech-card", 1}}
	),
	{
		type = "technology",
		name = "razi-outer-frontier-mastery",
		localised_name = {"technology-name.razi-outer-frontier-mastery"},
		icon = "__razi-protocol__/graphics/icons/BeetleJuiceStar.png",
		icon_size = 1024,
		essential = true,
		order = "eg[outer-frontier]",
		prerequisites = {"beetlejuice-discovery", "umbra-discovery"},
		effects = {},
		unit = {
			count = 2200,
			time = 60,
			ingredients = {{"beetlejuice-tech-card", 1}, {"umbra-tech-card", 1}}
		}
	}
})

-- Technologies whose price is made of system cards (see compat/lab_cards.lua).
local priced_in_cards = {
	"vespera-discovery",
	"umbra-discovery",
	"razi-outer-frontier-mastery",
	"razi-singularity-theory",
	"razi-singularity-test-fire",
	"razi-stable-intergalactic-singularity"
}

-- The Deep Space card is unlocked by the transceiver chain itself, so it is not listed.
local system_cards = {
	["calidus-tech-card"] = true,
	["solaris-tech-card"] = true,
	["nyxaris-tech-card"] = true,
	["vibrant-tech-card"] = true,
	["vespera-tech-card"] = true,
	["beetlejuice-tech-card"] = true,
	["umbra-tech-card"] = true
}

-- A card in the price is useless until its recipe is unlocked. Make the technology that
-- unlocks the recipe a prerequisite whenever it is not an ancestor yet. Runs after the
-- cards and their unlocks exist (compat/lab_cards.lua).
function seven_systems.data_final_fixes()
	local technologies = data.raw.technology
	if not technologies then
		return
	end

	for _, name in ipairs(priced_in_cards) do
		local technology = technologies[name]
		local ingredients = technology and technology.unit and technology.unit.ingredients or {}
		for _, ingredient in ipairs(ingredients) do
			local card = ingredient[1] or ingredient.name
			if system_cards[card] then
				-- Card recipes are named after the cards.
				local parent = TechnologyGraph.first_unlock(technologies, card, true)
				if parent and TechnologyGraph.add_prerequisite(technologies, name, parent) then
					log("[Razi Protocol/seven-systems] " .. name .. " now requires " .. parent .. ": it unlocks " .. card)
				end
			end
		end
	end
end

return seven_systems
