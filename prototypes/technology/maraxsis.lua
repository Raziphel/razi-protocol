set_prerequisites_if_exists("planet-discovery-maraxsis", {"vibrant-discovery"})
set_technology_unit_ingredients_if_exists("planet-discovery-maraxsis", build_integrated_science_ingredients({
	primary_science_packs = {
		"automation-science-pack",
		"logistic-science-pack",
		"chemical-science-pack",
		"production-science-pack",
		"utility-science-pack",
		"space-science-pack",
		"agricultural-science-pack",
		"electromagnetic-science-pack"
	},
	extra_science_packs = {
		"pelagos-science-pack",
		"planetaris-bioengineering-science-pack",
		"cryogenic-science-pack"
	}
}))
