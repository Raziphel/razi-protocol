local transceiver_endgame = {}

local icon = "__Krastorio2Assets__/technologies/intergalactic-transceiver.png"

local function add_science_pack(ingredients, name, amount)
	if data.raw.tool and data.raw.tool[name] then
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

local function make_transceiver_technology(name, prerequisites, count, multiplier, effects)
	return {
		type = "technology",
		name = name,
		localised_name = {"technology-name." .. name},
		icon = icon,
		icon_size = 256,
		essential = true,
		prerequisites = prerequisites,
		effects = effects or {},
		unit = {
			count = count,
			time = 60,
			ingredients = build_transceiver_science(multiplier)
		}
	}
end

-- Our version of Extended Endgame: the transceiver tech gives you the theory,
-- but these staged tests prove the singularity is stable before the recipe opens.
data:extend({
	make_transceiver_technology(
		"razi-singularity-theory",
		{"kr-intergalactic-transceiver"},
		5000,
		1
	),
	make_transceiver_technology(
		"razi-singularity-test-fire",
		{"razi-singularity-theory"},
		7500,
		2
	),
	make_transceiver_technology(
		"razi-stable-intergalactic-singularity",
		{"razi-singularity-test-fire"},
		10000,
		3,
		{
			{type = "unlock-recipe", recipe = "kr-intergalactic-transceiver"}
		}
	)
})

return transceiver_endgame
