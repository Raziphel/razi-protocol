set_prerequisites_if_exists("planet-discovery-cubium", {"beetlejuice-discovery"})
set_technology_unit_ingredients_if_exists("planet-discovery-cubium", build_integrated_science_ingredients({
	primary_science_packs = {
		"automation-science-pack",
		"logistic-science-pack",
		"chemical-science-pack",
		"production-science-pack",
		"utility-science-pack",
		"space-science-pack",
		"metallurgic-science-pack"
	},
	extra_science_packs = {
		"planetaris-compression-science-pack",
		"cryogenic-science-pack",
		"pelagos-science-pack"
	}
}))
