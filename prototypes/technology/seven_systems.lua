-- New system gates. Existing discoveries keep their prototype IDs for saves.
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
