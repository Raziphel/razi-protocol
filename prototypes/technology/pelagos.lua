-- Pelagos can feed Aquilo/lithium in its own mod settings, so gating its
-- discovery behind nyxaris-discovery creates a technology cycle.
-- Keep Pelagos physically in Nyxaris via routes/orbit, but start its tech from
-- the Dea Dia branch so the integrated tree stays acyclic.
set_prerequisites_if_exists("planet-discovery-pelagos", {"system-discovery-dea-dia"})
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
