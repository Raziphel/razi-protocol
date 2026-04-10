set_prerequisites_if_exists("planet-discovery-vesta", {"planet-discovery-cubium"})
set_technology_unit_ingredients_if_exists("planet-discovery-vesta", build_integrated_science_ingredients({
	primary_science_packs = {
		"automation-science-pack",
		"logistic-science-pack",
		"chemical-science-pack",
		"utility-science-pack",
		"space-science-pack",
		"electromagnetic-science-pack",
		"thermodynamic-science-pack"
	},
	extra_science_packs = {
		"pelagos-science-pack",
		"planetaris-polishing-science-pack"
	}
}))
