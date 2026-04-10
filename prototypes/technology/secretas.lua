if technology_exists("planet-discovery-frozeta") then
	set_prerequisites_if_exists("planet-discovery-frozeta", {"vibrant-discovery"})
	set_technology_unit_ingredients_if_exists("planet-discovery-frozeta", build_integrated_science_ingredients({
		primary_science_packs = {
			"automation-science-pack",
			"logistic-science-pack",
			"utility-science-pack",
			"space-science-pack",
			"cryogenic-science-pack",
			"electromagnetic-science-pack",
			"thermodynamic-science-pack"
		}
	}))

	set_prerequisites_if_exists("planet-discovery-secretas", {"planet-discovery-frozeta"})
else
	set_prerequisites_if_exists("planet-discovery-secretas", {"vibrant-discovery"})
end

set_technology_unit_ingredients_if_exists("planet-discovery-secretas", build_integrated_science_ingredients({
	primary_science_packs = {
		"automation-science-pack",
		"logistic-science-pack",
		"production-science-pack",
		"utility-science-pack",
		"space-science-pack",
		"electromagnetic-science-pack",
		"cryogenic-science-pack",
		"aerospace-science-pack"
	},
	extra_science_packs = {
		"pelagos-science-pack"
	}
}))
