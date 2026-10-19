data:extend({
	{
		type = "bool-setting",
		name = "razi-enable-enemy-routing",
		setting_type = "startup",
		default_value = true,
		order = "a[compat]-a[enemy-routing]"
	},
	{
		type = "bool-setting",
		name = "razi-hide-redundant-assembler-tiers",
		setting_type = "startup",
		default_value = true,
		order = "a[compat]-b[redundant-assemblers]"
	},
	{
		type = "bool-setting",
		name = "razi-curated-space-routes",
		setting_type = "startup",
		default_value = true,
		order = "ca[quality-of-life]-c3[curated-route-authority]"
	},
	{
		type = "bool-setting",
		name = "razi-route-distance-repair",
		setting_type = "startup",
		default_value = true,
		order = "ba[integration]-z[distance-repair]"
	},
	{
		type = "string-setting",
		name = "razi-asteroid-population",
		setting_type = "startup",
		default_value = "standard",
		allowed_values = {"sparse", "standard", "dense", "swarm"},
		order = "aa[worlds]-d[asteroid-population]"
	},
	{
		type = "string-setting",
		name = "razi-starmap-orbit-density",
		setting_type = "startup",
		default_value = "full",
		allowed_values = {"full", "balanced", "clean", "off"},
		order = "cb[starmap]-a2[orbit-density]"
	},
	{
		type = "bool-setting",
		name = "razi-stage-aquilo-breakthroughs",
		setting_type = "startup",
		default_value = true,
		order = "ba[integration]-c2[aquilo-breakthroughs]"
	}
})
