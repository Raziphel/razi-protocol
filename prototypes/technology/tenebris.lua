set_prerequisites_if_exists("planet-discovery-tenebris", {"vibrant-discovery"})
set_technology_unit_ingredients_if_exists("planet-discovery-tenebris", build_integrated_science_ingredients({
	primary_science_packs = {
		"automation-science-pack",
		"logistic-science-pack",
		"production-science-pack",
		"utility-science-pack",
		"space-science-pack",
		"agricultural-science-pack",
		"cryogenic-science-pack",
		"planetaris-pathological-science-pack",
		"thermodynamic-science-pack"
	},
	extra_science_packs = {
		"pelagos-science-pack"
	}
}))
