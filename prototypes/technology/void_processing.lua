set_first_existing_prerequisite("black-hole-discovery", {
	"planet-discovery-nexus",
	"planet-nexus-scanning",
	"planet-nexus-scanning-Krastorio2-space-out"
})
add_existing_prerequisites("black-hole-discovery", {
	"promethium-science-pack"
})
set_technology_unit_ingredients_if_exists("black-hole-discovery", build_integrated_science_ingredients({
	primary_science_packs = {
		"automation-science-pack",
		"logistic-science-pack",
		"military-science-pack",
		"chemical-science-pack",
		"production-science-pack",
		"utility-science-pack",
		"space-science-pack",
		"promethium-science-pack"
	},
	extra_science_packs = {
		"planetaris-compression-science-pack",
		"cryogenic-science-pack",
		"pelagos-science-pack",
		"thermodynamic-science-pack"
	}
}))
