data:extend({
	{
		type = "bool-setting",
		name = "razi-route-distance-repair",
		setting_type = "startup",
		default_value = true,
		order = "ba[integration]-z[distance-repair]"
	},
	{
		type = "string-setting",
		name = "razi-planetary-interdependence",
		setting_type = "startup",
		default_value = "balanced",
		allowed_values = {"off", "balanced", "deep"},
		order = "ba[integration]-0[interdependence]"
	},
	{
		type = "bool-setting",
		name = "razi-distributed-technology",
		setting_type = "startup",
		default_value = false,
		order = "ba[integration]-c[planetary-tech-distribution]"
	},
	{
		type = "bool-setting",
		name = "razi-auto-tech-cards",
		setting_type = "startup",
		default_value = false,
		order = "ba[integration]-d[auto-tech-cards]"
	},
	{
		type = "bool-setting",
		name = "razi-infinite-research-cards",
		setting_type = "startup",
		default_value = true,
		order = "ba[integration]-d2[infinite-research-cards]"
	},
	{
		type = "bool-setting",
		name = "razi-stage-aquilo-breakthroughs",
		setting_type = "startup",
		default_value = true,
		order = "ba[integration]-c2[aquilo-breakthroughs]"
	},
	{
		type = "bool-setting",
		name = "razi-orbital-catapult-local-links",
		setting_type = "startup",
		default_value = true,
		order = "ba[integration]-e[catapult-links]"
	},
	{
		type = "bool-setting",
		name = "razi-orbital-catapult-regional-links",
		setting_type = "startup",
		default_value = true,
		order = "ba[integration]-e2[regional-catapult-links]"
	}
})
