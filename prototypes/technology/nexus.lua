local nexus_discovery_technologies = {
	"planet-discovery-nexus",
	"planet-nexus-scanning",
	"planet-nexus-scanning-Krastorio2-space-out"
}

local nexus_science_ingredients = build_integrated_science_ingredients({
	primary_science_packs = {
		"automation-science-pack",
		"logistic-science-pack",
		"military-science-pack",
		"chemical-science-pack",
		"production-science-pack",
		"utility-science-pack",
		"space-science-pack",
		"metallurgic-science-pack",
		"electromagnetic-science-pack",
		"agricultural-science-pack",
		"cryogenic-science-pack"
	},
	extra_science_packs = {
		"pelagos-science-pack",
		"planetaris-polishing-science-pack"
	}
})

for _, technology_name in ipairs(nexus_discovery_technologies) do
	set_prerequisites_if_exists(technology_name, {"beetlejuice-discovery"})
	set_technology_unit_ingredients_if_exists(technology_name, nexus_science_ingredients)
end
