set_prerequisites_if_exists("planet-discovery-moshine", {"nyxaris-discovery"})
set_technology_unit_ingredients_if_exists("planet-discovery-moshine", build_integrated_science_ingredients({
	primary_science_packs = {
		"automation-science-pack",
		"logistic-science-pack",
		"utility-science-pack",
		"space-science-pack",
		"electromagnetic-science-pack",
		"planetaris-polishing-science-pack",
		"aerospace-science-pack"
	},
}))
