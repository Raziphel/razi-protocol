local function build_solaris_science_ingredients()
	return build_integrated_science_ingredients({
		primary_science_packs = {
			"planetaris-compression-science-pack",
			"planetaris-polishing-science-pack",
			"planetaris-bioengineering-science-pack",
			"planetaris-pathological-science-pack"
		},
		first_available_science_packs = {
			"lithium-science-pack",
			"tungsten-science-pack"
		},
		fallback_science_packs = {
			"space-science-pack",
			"metallurgic-science-pack",
			"electromagnetic-science-pack",
			"agricultural-science-pack"
		}
	})
end

local function build_nyxaris_science_ingredients()
	return build_integrated_science_ingredients({
		primary_science_packs = {
			"planetaris-compression-science-pack",
			"planetaris-polishing-science-pack",
			"planetaris-bioengineering-science-pack",
			"planetaris-pathological-science-pack"
		},
		first_available_science_packs = {
			"lithium-science-pack",
			"tungsten-science-pack"
		},
		extra_science_packs = {
			"insulation-science-pack",
			"thermodynamic-science-pack",
			"aerospace-science-pack"
		},
		fallback_science_packs = {
			"space-science-pack",
			"metallurgic-science-pack",
			"electromagnetic-science-pack",
			"agricultural-science-pack"
		}
	})
end

local function build_vibrant_science_ingredients()
	return build_integrated_science_ingredients({
		primary_science_packs = {
			"automation-science-pack",
			"logistic-science-pack",
			"utility-science-pack",
			"space-science-pack",
			"electromagnetic-science-pack",
			"cryogenic-science-pack"
		},
		extra_science_packs = {
			"apicultural-science-pack",
			"pelagos-science-pack"
		},
		fallback_science_packs = {
			"automation-science-pack",
			"logistic-science-pack",
			"utility-science-pack",
			"space-science-pack",
			"electromagnetic-science-pack",
			"cryogenic-science-pack"
		}
	})
end

local function build_beetlejuice_science_ingredients()
	return build_integrated_science_ingredients({
		primary_science_packs = {
			"automation-science-pack",
			"logistic-science-pack",
			"utility-science-pack",
			"space-science-pack",
			"electromagnetic-science-pack",
			"cryogenic-science-pack"
		},
		extra_science_packs = {
			"pelagos-science-pack",
			"planetaris-bioengineering-science-pack",
			"thermodynamic-science-pack"
		},
		fallback_science_packs = {
			"automation-science-pack",
			"logistic-science-pack",
			"utility-science-pack",
			"space-science-pack",
			"electromagnetic-science-pack",
			"cryogenic-science-pack"
		}
	})
end

local solaris_science_ingredients = build_solaris_science_ingredients()
local nyxaris_science_ingredients = build_nyxaris_science_ingredients()
local vibrant_science_ingredients = build_vibrant_science_ingredients()
local beetlejuice_science_ingredients = build_beetlejuice_science_ingredients()
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

local vibrant_prerequisite_technologies = {
	"apicultural-science-pack",
	"pelagos-science-pack"
}

local beetlejuice_prerequisite_technologies = {
	"cryogenic-science-pack",
	"pelagos-science-pack",
	"planetaris-bioengineering-science-pack",
	"thermodynamic-science-pack"
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
			},
			{
				type = "unlock-space-location",
				space_location = "sye-solaris",
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
	},
	{
		type = "technology",
		name = "vibrant-discovery",
		localised_name = "Vibrant Discovery",
		icon = "__razi-protocol__/graphics/icons/VibrantStar.png",
		icon_size = 1024,
		essential = true,
		effects = {
			{
				type = "unlock-space-location",
				space_location = "sye-vibrant",
				use_icon_overlay_constant = true
			}
		},
		prerequisites = {
			"nyxaris-discovery"
		},
		unit = {
			count = 1200,
			time = 60,
			ingredients = vibrant_science_ingredients
		},
		order = "ec[vibrant]"
	},
	{
		type = "technology",
		name = "beetlejuice-discovery",
		localised_name = "Beetlejuice Discovery",
		icon = "__razi-protocol__/graphics/icons/BeetleJuiceStar.png",
		icon_size = 1024,
		essential = true,
		effects = {
			{
				type = "unlock-space-location",
				space_location = "sye-beetlejuice",
				use_icon_overlay_constant = true
			}
		},
		prerequisites = {
			"vibrant-discovery"
		},
		unit = {
			count = 1500,
			time = 60,
			ingredients = beetlejuice_science_ingredients
		},
		order = "ed[beetlejuice]"
	}
})

add_existing_prerequisites("solaris-discovery", solaris_prerequisite_technologies)
add_existing_prerequisites("nyxaris-discovery", nyxaris_prerequisite_technologies)
add_existing_prerequisites("vibrant-discovery", vibrant_prerequisite_technologies)
add_existing_prerequisites("beetlejuice-discovery", beetlejuice_prerequisite_technologies)
