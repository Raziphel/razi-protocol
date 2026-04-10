local function science_pack_exists(name)
	return data.raw.tool and data.raw.tool[name] ~= nil
end

local function add_science_pack_if_exists(ingredients, science_pack)
	if science_pack_exists(science_pack) then
		table.insert(ingredients, {science_pack, 1})
		return true
	end

	return false
end

local function add_unique_science_pack_if_exists(ingredients, science_pack)
	if not science_pack_exists(science_pack) then
		return false
	end

	for _, ingredient in ipairs(ingredients) do
		if ingredient[1] == science_pack then
			return false
		end
	end

	table.insert(ingredients, {science_pack, 1})
	return true
end

local function build_solaris_science_ingredients()
	local ingredients = {}

	local planetaris_pack_candidates = {
		"planetaris-compression-science-pack",
		"planetaris-polishing-science-pack",
		"planetaris-bioengineering-science-pack",
		"planetaris-pathological-science-pack"
	}

	for _, science_pack in ipairs(planetaris_pack_candidates) do
		if science_pack_exists(science_pack) then
			table.insert(ingredients, {science_pack, 1})
		end
	end

	local corrundum_pack_candidates = {
		"lithium-science-pack",
		"tungsten-science-pack",
		"chemical-science-pack"
	}

	for _, science_pack in ipairs(corrundum_pack_candidates) do
		if add_science_pack_if_exists(ingredients, science_pack) then
			break
		end
	end

	if #ingredients == 0 then
		ingredients = {
			{"space-science-pack", 1},
			{"metallurgic-science-pack", 1},
			{"electromagnetic-science-pack", 1},
			{"agricultural-science-pack", 1}
		}
	end

	return ingredients
end

local function build_nyxaris_science_ingredients()
	local ingredients = build_solaris_science_ingredients()

	local dea_dia_pack_candidates = {
		"insulation-science-pack",
		"thermodynamic-science-pack",
		"aerospace-science-pack"
	}

	for _, science_pack in ipairs(dea_dia_pack_candidates) do
		add_unique_science_pack_if_exists(ingredients, science_pack)
	end

	return ingredients
end

local solaris_science_ingredients = build_solaris_science_ingredients()
local nyxaris_science_ingredients = build_nyxaris_science_ingredients()
local solaris_prerequisite_technologies = {
	"lithium-processing",
	"tungsten-carbide"
}

local nyxaris_prerequisite_technologies = {
	"planetaris-compression-science-pack",
	"planetaris-polishing-science-pack",
	"planetaris-bioengineering-science-pack",
	"planetaris-pathological-science-pack",
	"lithium-processing",
	"tungsten-carbide"
}

data:extend({
	{
		type = "technology",
		name = "solaris-discovery",
		localised_name = "Solaris Discovery",
		icon = "__razi-protocol__/graphics/icons/SolarisStar.png",
		icon_size = 1024,
		essential = true,
		effects = {
			{
				type = "unlock-space-location",
				space_location = "sye-calidus",
				use_icon_overlay_constant = true
			}
		},
		prerequisites = {
			"planet-discovery-vulcanus",
			"planet-discovery-fulgora",
			"planet-discovery-gleba"
		},
		unit = {
			count = 1000,
			time = 60,
			ingredients = solaris_science_ingredients
		},
		order = "ea[solaris]"
	},
	{
		type = "technology",
		name = "nyxaris-discovery",
		localised_name = "Nyxaris Discovery",
		icon = "__razi-protocol__/graphics/icons/NyxarisStar.png",
		icon_size = 1024,
		essential = true,
		effects = {
			{
				type = "unlock-space-location",
				space_location = "sye-nyxaris",
				use_icon_overlay_constant = true
			}
		},
		prerequisites = {
			"system-discovery-dea-dia"
		},
		unit = {
			count = 1000,
			time = 60,
			ingredients = nyxaris_science_ingredients
		},
		order = "eb[nyxaris]"
	}
})

add_existing_prerequisites("solaris-discovery", solaris_prerequisite_technologies)
add_existing_prerequisites("nyxaris-discovery", nyxaris_prerequisite_technologies)
