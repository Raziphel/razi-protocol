set_prerequisites_if_exists("planet-discovery-paracelsin", {"vibrant-discovery"})
set_technology_unit_ingredients_if_exists("planet-discovery-paracelsin", build_integrated_science_ingredients({
	primary_science_packs = {
		"automation-science-pack",
		"logistic-science-pack",
		"utility-science-pack",
		"space-science-pack",
		"electromagnetic-science-pack",
		"cryogenic-science-pack",
	},
	extra_science_packs = {
		"apicultural-science-pack",
		"pelagos-science-pack"
	}
}))
