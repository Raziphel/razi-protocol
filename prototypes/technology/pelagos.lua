-- Pelagos can feed Aquilo/lithium in its own mod settings, so gating its
-- discovery behind nyxaris-discovery creates a technology cycle.
-- Prefer the Dea Dia branch when both optional integrations are installed.
-- Fall back through Panglia when Pelagos is installed on its own.
set_first_existing_prerequisite("planet-discovery-pelagos", {
	"system-discovery-dea-dia",
	"panglia_planet_discovery_panglia",
	"nyxaris-discovery"
})
set_technology_unit_ingredients_if_exists("planet-discovery-pelagos", build_integrated_science_ingredients({
	primary_science_packs = {
		"automation-science-pack",
		"logistic-science-pack",
		"military-science-pack",
		"space-science-pack",
		"agricultural-science-pack",
		"planetaris-pathological-science-pack"
	},
	extra_science_packs = {
		"insulation-science-pack",
		"thermodynamic-science-pack"
	}
}))
