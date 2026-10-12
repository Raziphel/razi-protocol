set_prerequisites_if_exists("panglia_planet_discovery_panglia", {"nyxaris-discovery"})
set_technology_unit_ingredients_if_exists("panglia_planet_discovery_panglia", build_integrated_science_ingredients({
	primary_science_packs = {
		"automation-science-pack",
		"logistic-science-pack",
		"utility-science-pack",
		"space-science-pack",
		"agricultural-science-pack",
		"electromagnetic-science-pack",
		"planetaris-bioengineering-science-pack",
		"planetaris-pathological-science-pack",
		"thermodynamic-science-pack"
	},
	extra_science_packs = {
		"aerospace-science-pack"
	}
}))
